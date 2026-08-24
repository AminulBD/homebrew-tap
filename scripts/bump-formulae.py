#!/usr/bin/env python3
"""Sync tap formulae to the latest upstream GitHub release.

Everything is driven by the formula itself: each `url` pinned to a GitHub
release, together with the `sha256` beneath it, is discovered by reading the
file. The upstream repo, the current version and the per-platform asset names
all come from those URLs, so adding a platform -- or a whole formula -- needs no
change here.

Hashes are read from the release's SHA256SUMS rather than computed locally, so a
bump costs two requests and no archive downloads.

Run with --dry-run to see what would change without writing.
"""

import argparse
import json
import os
import re
import sys
import urllib.request
from pathlib import Path

FORMULAE = ["Formula/ds.rb"]

ROOT = Path(__file__).resolve().parent.parent

# A pinned `url` and the `sha256` directly beneath it, capturing the owner/repo,
# the version and the asset filename.
PINNED = re.compile(
    r'(url\s+")https://github\.com/([^/"]+/[^/"]+)/releases/download/v([^/"]+)/([^"]+)'
    r'("\s*\n\s*sha256\s+")[0-9a-f]{64}(")'
)


def get(url, token=None):
    req = urllib.request.Request(url, headers={"User-Agent": "aminulbd-homebrew-tap"})
    # Only the API gets the token: GitHub redirects asset downloads to a
    # different host, which rejects a forwarded Authorization header.
    if token and url.startswith("https://api.github.com/"):
        req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req, timeout=60) as resp:
        return resp.read()


def version_key(v):
    return tuple(int(n) for n in re.findall(r"\d+", v))


def latest_release(repo, token):
    # /releases/latest already excludes drafts and prereleases.
    data = json.loads(get(f"https://api.github.com/repos/{repo}/releases/latest", token))
    return data["tag_name"].lstrip("v"), {a["name"] for a in data["assets"]}


def sha256sums(repo, tag, token):
    body = get(f"https://github.com/{repo}/releases/download/{tag}/SHA256SUMS", token)
    sums = {}
    for line in body.decode().splitlines():
        parts = line.split()
        if len(parts) == 2 and re.fullmatch(r"[0-9a-f]{64}", parts[0]):
            sums[parts[1].lstrip("*")] = parts[0]
    if not sums:
        raise SystemExit(f"{repo} {tag}: SHA256SUMS held no usable hashes")
    return sums


def bump(path, token, dry_run):
    path = ROOT / path
    text = path.read_text()

    pins = PINNED.findall(text)
    if not pins:
        raise SystemExit(f"{path}: no pinned GitHub release URLs found")

    repos = {p[1] for p in pins}
    current = {p[2] for p in pins}
    if len(repos) != 1 or len(current) != 1:
        raise SystemExit(f"{path}: inconsistent pins, repos={repos} versions={current}")
    repo, current = repos.pop(), current.pop()

    latest, published = latest_release(repo, token)
    print(f"{path.name}: {repo} pinned {current}, upstream latest {latest}")

    if latest == current:
        return None
    if version_key(latest) < version_key(current):
        print(f"  skipping: {latest} is older than the pinned {current}")
        return None

    # Asset names carry the version, so derive the new ones from the old.
    assets = {}
    for _, _, _, asset, _, _ in pins:
        if current not in asset:
            raise SystemExit(f"{path}: cannot place version in asset name {asset}")
        assets[asset] = asset.replace(current, latest)

    # Assets can lag the release by seconds; the next run picks it up.
    if missing := sorted(set(assets.values()) - published):
        print(f"  skipping: release v{latest} is missing {missing}")
        return None

    tag = f"v{latest}"
    sums = sha256sums(repo, tag, token)
    if missing := sorted(set(assets.values()) - set(sums)):
        print(f"  skipping: SHA256SUMS for v{latest} is missing {missing}")
        return None

    for asset in assets.values():
        print(f"  {asset}: {sums[asset]}")

    def rewrite(m):
        head, _, _, asset, mid, tail = m.groups()
        url = f"https://github.com/{repo}/releases/download/{tag}/{assets[asset]}"
        return f"{head}{url}{mid}{sums[assets[asset]]}{tail}"

    text, n = PINNED.subn(rewrite, text)
    if n != len(pins):
        raise SystemExit(f"{path}: rewrote {n} pins, expected {len(pins)}")
    if f"v{current}" in text:
        raise SystemExit(f"{path}: still references {current} after rewriting")

    if dry_run:
        print(f"  dry run: would write {path.name}")
    else:
        path.write_text(text)

    return {"formula": path.stem, "old": current, "new": latest}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--formula", help="only bump this formula (by name, e.g. ds)")
    args = ap.parse_args()

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")
    paths = FORMULAE
    if args.formula:
        paths = [p for p in paths if Path(p).stem == args.formula]
        if not paths:
            raise SystemExit(f"no formula named {args.formula}")

    changed = [c for c in (bump(p, token, args.dry_run) for p in paths) if c]

    summary = ", ".join(f"{c['formula']} {c['old']} -> {c['new']}" for c in changed)
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
