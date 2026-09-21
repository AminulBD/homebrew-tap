#!/usr/bin/env python3
"""Sync tap formulae and casks to the latest upstream GitHub release.

Everything is driven by the package file itself: the upstream repo, the current
version and the per-platform asset names all come from the `url` stanzas, so
adding a platform -- or a whole formula or cask -- needs no change here.

Formulae pin one `url` per platform, each followed by its `sha256`, with the
version embedded in the asset name. Casks carry a single `version` stanza, a
`url` template interpolating `#{version}` and optionally `#{arch}`, and a
`sha256` stanza with one hash per architecture.

Hashes are read from the release's SHA256SUMS when it publishes one, so a bump
costs two requests and no archive downloads; otherwise each asset is downloaded
and hashed locally.

Run with --dry-run to see what would change without writing.
"""

import argparse
import hashlib
import json
import os
import re
import sys
import urllib.error
import urllib.request
from pathlib import Path

PACKAGES = ["Formula/ds.rb", "Casks/avro.rb"]

ROOT = Path(__file__).resolve().parent.parent

# Formula: a pinned `url` and the `sha256` directly beneath it, capturing the
# owner/repo, the version and the asset filename.
PINNED = re.compile(
    r'(url\s+")https://github\.com/([^/"]+/[^/"]+)/releases/download/v([^/"]+)/([^"]+)'
    r'("\s*\n\s*sha256\s+")[0-9a-f]{64}(")'
)

# Cask: the `version`, `arch` and `sha256` stanzas, and a `url` template that
# interpolates them.
CASK_VERSION = re.compile(r'^(\s*version\s+")([^"]+)(")', re.M)
CASK_URL = re.compile(
    r'^\s*url\s+"https://github\.com/([^/"]+/[^/"]+)/releases/download/v#\{version\}/([^"]+)"', re.M
)
CASK_ARCH = re.compile(r'^\s*arch\s+arm:\s*"([^"]+)",\s*intel:\s*"([^"]+)"', re.M)
CASK_SHA = re.compile(r'(\b(arm|intel):\s*"|^\s*sha256\s+")([0-9a-f]{64})(")', re.M)


def get(url, token=None):
    req = urllib.request.Request(url, headers={"User-Agent": "aminulbd-homebrew-tap"})
    # Only the API gets the token: GitHub redirects asset downloads to a
    # different host, which rejects a forwarded Authorization header.
    if token and url.startswith("https://api.github.com/"):
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=300) as resp:
        return resp.read()


def version_key(v):
    return tuple(int(n) for n in re.findall(r"\d+", v))


def latest_release(repo, token):
    # /releases/latest already excludes drafts and prereleases.
    data = json.loads(get(f"https://api.github.com/repos/{repo}/releases/latest", token))
    return data["tag_name"].lstrip("v"), {a["name"] for a in data["assets"]}


def sha256sums(repo, tag, token):
    try:
        body = get(f"https://github.com/{repo}/releases/download/{tag}/SHA256SUMS", token)
    except urllib.error.HTTPError as e:
        if e.code == 404:
            return None
        raise
    sums = {}
    for line in body.decode().splitlines():
        parts = line.split()
        if len(parts) == 2 and re.fullmatch(r"[0-9a-f]{64}", parts[0]):
            sums[parts[1].lstrip("*")] = parts[0]
    if not sums:
        raise SystemExit(f"{repo} {tag}: SHA256SUMS held no usable hashes")
    return sums


def hashes(repo, tag, assets, token):
    """Return {asset: sha256} for the named assets, or None if any is unavailable."""
    sums = sha256sums(repo, tag, token)
    if sums is None:
        # No checksum file on the release: hash the assets ourselves.
        sums = {}
        for asset in assets:
            print(f"  downloading {asset}")
            body = get(f"https://github.com/{repo}/releases/download/{tag}/{asset}", token)
            sums[asset] = hashlib.sha256(body).hexdigest()
    if missing := sorted(set(assets) - set(sums)):
        print(f"  skipping: SHA256SUMS for {tag} is missing {missing}")
        return None
    for asset in assets:
        print(f"  {asset}: {sums[asset]}")
    return sums


def check_upstream(path, repo, current, wanted, token):
    """Return the latest version and the assets it must carry, or None to skip."""
    latest, published = latest_release(repo, token)
    print(f"{path.name}: {repo} pinned {current}, upstream latest {latest}")

    if latest == current:
        return None
    if version_key(latest) < version_key(current):
        print(f"  skipping: {latest} is older than the pinned {current}")
        return None

    # Assets can lag the release by seconds; the next run picks it up.
    assets = wanted(latest)
    if missing := sorted(set(assets) - published):
        print(f"  skipping: release v{latest} is missing {missing}")
        return None
    return latest, assets


def bump_formula(path, text, token):
    pins = PINNED.findall(text)
    if not pins:
        raise SystemExit(f"{path}: no pinned GitHub release URLs found")

    repos = {p[1] for p in pins}
    current = {p[2] for p in pins}
    if len(repos) != 1 or len(current) != 1:
        raise SystemExit(f"{path}: inconsistent pins, repos={repos} versions={current}")
    repo, current = repos.pop(), current.pop()

    # Asset names carry the version, so derive the new ones from the old.
    for _, _, _, asset, _, _ in pins:
        if current not in asset:
            raise SystemExit(f"{path}: cannot place version in asset name {asset}")

    def wanted(latest):
        return [asset.replace(current, latest) for _, _, _, asset, _, _ in pins]

    if not (found := check_upstream(path, repo, current, wanted, token)):
        return None
    latest, assets = found
    tag = f"v{latest}"
    if not (sums := hashes(repo, tag, assets, token)):
        return None

    def rewrite(m):
        head, _, _, asset, mid, tail = m.groups()
        asset = asset.replace(current, latest)
        url = f"https://github.com/{repo}/releases/download/{tag}/{asset}"
        return f"{head}{url}{mid}{sums[asset]}{tail}"

    text, n = PINNED.subn(rewrite, text)
    if n != len(pins):
        raise SystemExit(f"{path}: rewrote {n} pins, expected {len(pins)}")
    if f"v{current}" in text:
        raise SystemExit(f"{path}: still references {current} after rewriting")
    return text, current, latest


def bump_cask(path, text, token):
    version = CASK_VERSION.search(text)
    url = CASK_URL.search(text)
    if not version or not url:
        raise SystemExit(f"{path}: no version stanza or GitHub release url template found")
    current = version.group(2)
    repo, template = url.groups()

    # One asset per architecture when the template uses `#{arch}`, else one.
    arch = CASK_ARCH.search(text)
    if "#{arch}" in template:
        if not arch:
            raise SystemExit(f"{path}: url uses #{{arch}} but there is no arch stanza")
        arches = {"arm": arch.group(1), "intel": arch.group(2)}
    else:
        arches = {None: ""}

    def asset(latest, arch_name):
        return template.replace("#{version}", latest).replace("#{arch}", arch_name)

    def wanted(latest):
        return [asset(latest, a) for a in arches.values()]

    if not (found := check_upstream(path, repo, current, wanted, token)):
        return None
    latest, _ = found
    if not (sums := hashes(repo, f"v{latest}", wanted(latest), token)):
        return None

    # Each sha256 belongs to the arch it is keyed by; a bare sha256 to the one asset.
    def rewrite(m):
        head, key, _, tail = m.groups()
        if key not in arches:
            raise SystemExit(f"{path}: sha256 for unknown arch {key}")
        return f"{head}{sums[asset(latest, arches[key])]}{tail}"

    text, n = CASK_SHA.subn(rewrite, text)
    if n != len(arches):
        raise SystemExit(f"{path}: rewrote {n} hashes, expected {len(arches)}")
    text, n = CASK_VERSION.subn(rf"\g<1>{latest}\g<3>", text, count=1)
    if n != 1:
        raise SystemExit(f"{path}: could not rewrite the version stanza")
    return text, current, latest


def bump(path, token, dry_run):
    path = ROOT / path
    text = path.read_text()

    is_cask = path.parent.name == "Casks"
    result = (bump_cask if is_cask else bump_formula)(path, text, token)
    if not result:
        return None
    text, current, latest = result

    if dry_run:
        print(f"  dry run: would write {path.name}")
    else:
        path.write_text(text)

    return {"package": path.stem, "old": current, "new": latest}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--formula", help="only bump this formula or cask (by name, e.g. ds)")
    args = ap.parse_args()

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    paths = PACKAGES
    if args.formula:
        paths = [p for p in paths if Path(p).stem == args.formula]
        if not paths:
            raise SystemExit(f"no formula or cask named {args.formula}")

    changed = [c for c in (bump(p, token, args.dry_run) for p in paths) if c]

    summary = ", ".join(f"{c['package']} {c['old']} -> {c['new']}" for c in changed)
    print(summary or "everything is up to date")

    if out := os.environ.get("GITHUB_OUTPUT"):
        with open(out, "a") as fh:
            fh.write(f"changed={'true' if changed else 'false'}\n")
            fh.write(f"summary={summary}\n")
    if changed and (step := os.environ.get("GITHUB_STEP_SUMMARY")):
        with open(step, "a") as fh:
            fh.write(f"Bumped {summary}\n")


if __name__ == "__main__":
    sys.exit(main())
