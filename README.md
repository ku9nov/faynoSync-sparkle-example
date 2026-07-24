# faynosync-sparkle-example

Example macOS app wired to Sparkle for auto-updates, intended to be published through faynoSync.

## Initial setup

### Prerequisites

- Xcode command line tools
- [xcodegen](https://github.com/yonsweng/xcodegen) (`brew install xcodegen`)
- Sparkle CLI tools in `./tools` (see below) — not vendored in the repo

### Install Sparkle CLI tools

The Makefile targets call Sparkle's binaries from `$SPARKLE_BIN` (default `./tools`).
They are not committed (`tools/` is gitignored), so fetch them once from a Sparkle release:

```bash
mkdir -p tools
VER=2.6.4
curl -fL -o /tmp/sparkle.tar.xz \
  https://github.com/sparkle-project/Sparkle/releases/download/${VER}/Sparkle-${VER}.tar.xz
tar -xf /tmp/sparkle.tar.xz -C /tmp bin
cp /tmp/bin/generate_keys /tmp/bin/generate_appcast /tmp/bin/sign_update tools/
```

`generate_keys` is used by `make keys`, `generate_appcast` by `make appcast`, and
`sign_update` produces the `edSignature` for the faynoSync upload `signature` field.

### Config

Copy `.env.example` to `.env` and set `DEVELOPER_ID`, `DEVELOPMENT_TEAM`, and `DOWNLOAD_URL_PREFIX`.
When `DEVELOPER_ID` is set the build uses manual signing, so `DEVELOPMENT_TEAM` must match that identity's team ID.
App-level config (`SUFeedURL`, `SUPublicEDKey`, `FaynoSync*`) lives in `Resources/Info.plist`.

## Usage

```
make keys      # generate Ed25519 keys; paste SUPublicEDKey into Resources/Info.plist
make generate  # run xcodegen to (re)create the Xcode project
make build     # build + sign + zip the .app into build/dist
make appcast   # sign archives and (re)generate appcast.xml in build/dist
make run       # build and launch the app
make clean
```

The private signing key is stored in the macOS login Keychain and never leaves the machine.
