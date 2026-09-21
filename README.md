# homebrew-tap

Homebrew tap for [Aminul](https://github.com/aminulbd)'s tools.

## Formulae

| Formula | What it is | Upstream | Ships |
| --- | --- | --- | --- |
| `ds` | Check domain availability over RDAP with a WHOIS fallback | [aminulbd/ds](https://github.com/aminulbd/ds) | prebuilt binary |

## Casks

| Cask | What it is | Upstream | Ships |
| --- | --- | --- | --- |
| `avro` | Bangla phonetic input method for macOS | [AminulBD/iAvro](https://github.com/AminulBD/iAvro) | signed, notarized app |

## Install

```sh
brew install aminulbd/tap/<formula>            # e.g. brew install aminulbd/tap/ds
brew install --cask aminulbd/tap/avro
```

`avro` installs into `~/Library/Input Methods`; log out and back in,
then add it under `System Settings > Keyboard > Input Sources > Edit… > + >
Bangla > Avro Keyboard`.

Naming the tap in full is enough on its own — Homebrew treats it as consent to
load the formula or cask. Upgrading later is the usual:

```sh
brew update && brew upgrade <formula>
```

### Installing by bare name

Homebrew 6 refuses to load a formula or cask from a third-party tap you have not
trusted, so shortening this to `brew install <formula>` takes one extra command,
once for the whole tap:

```sh
brew trust aminulbd/tap
brew tap aminulbd/tap
brew install ds
brew install --cask avro
```

Without the `brew trust`, the install stops with `Refusing to load formula
aminulbd/tap/ds from untrusted tap aminulbd/tap`. The same one-off applies to
`brew bundle`, after which a `Brewfile` works normally:

```ruby
tap "aminulbd/tap"
brew "ds"
cask "avro"
```

Usage is in `man ds` and the
[project README](https://github.com/aminulbd/ds#readme).

## License

Each formula packages separately licensed software; see the upstream project for
its terms. `ds` is MIT; `avro` packages
[iAvro](https://github.com/AminulBD/iAvro), see that repository for its terms.
