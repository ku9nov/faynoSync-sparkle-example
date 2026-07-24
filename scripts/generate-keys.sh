#!/usr/bin/env bash
set -euo pipefail
[[ -f .env ]] && source .env
: "${SPARKLE_BIN:=./tools}"

# Stores the Ed25519 private key in the login Keychain and prints SUPublicEDKey.
# Paste the printed key into Resources/Info.plist (SUPublicEDKey). The private key
# never leaves this machine and is never uploaded to faynoSync.
"$SPARKLE_BIN/generate_keys"
