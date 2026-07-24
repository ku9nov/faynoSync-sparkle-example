#!/usr/bin/env bash
set -euo pipefail
[[ -f .env ]] && source .env
: "${SPARKLE_BIN:=./tools}"
: "${DIST_DIR:=build/dist}"
: "${DOWNLOAD_URL_PREFIX:=}"

# Reads the Ed25519 private key from the Keychain, signs every archive in DIST_DIR and
# writes one appcast.{channel}.xml per {platform}/{arch} branch. Upload the whole DIST_DIR
# to S3/CDN. Optional knobs below enrich the generated feed (set via env/.env); empty =>
# the flag is omitted and Sparkle uses its own default.
: "${SPARKLE_ACCOUNT:=}"                        # --account (keychain key name)
: "${ED_KEY_FILE:=}"                            # --ed-key-file (CI: private key file, or '-' for stdin)
: "${SPARKLE_CHANNEL:=}"                        # --channel (adds sparkle:channel; clients must opt in to see it)
: "${LINK:=}"                                   # --link (product website; required by informational updates)
: "${RELEASE_NOTES_URL_PREFIX:=}"               # --release-notes-url-prefix
: "${FULL_RELEASE_NOTES_URL:=}"                 # --full-release-notes-url
: "${CRITICAL_UPDATE_VERSION:=}"                # --critical-update-version (empty string "" => critical from any version)
: "${PHASED_ROLLOUT_INTERVAL:=}"                # --phased-rollout-interval (seconds)
: "${INFORMATIONAL_UPDATE_VERSIONS:=}"          # --informational-update-versions (needs LINK)
: "${MAJOR_VERSION:=}"                          # --major-version
: "${IGNORE_SKIPPED_UPGRADES_BELOW_VERSION:=}"  # --ignore-skipped-upgrades-below-version
: "${MAXIMUM_VERSIONS:=}"                        # --maximum-versions
: "${MAXIMUM_DELTAS:=}"                          # --maximum-deltas
: "${DELTA_COMPRESSION:=}"                       # --delta-compression (lzma|lzfse|lz4|default)
: "${VERSIONS:=}"                               # --versions (comma list of CFBundleVersion)
: "${EMBED_RELEASE_NOTES:=}"                     # --embed-release-notes (non-empty => on)

# Elements generate_appcast cannot produce — injected verbatim into every <item> after
# generation, for exercising an API's parser against the full appcast schema.
: "${MAXIMUM_SYSTEM_VERSION:=}"                  # <sparkle:maximumSystemVersion>
: "${MINIMUM_UPDATE_VERSION:=}"                  # <sparkle:minimumUpdateVersion>
: "${EXTRA_ITEM_XML:=}"                          # raw XML block (e.g. sparkle:hardwareRequirements, sparkle:tags)

if [[ -n "$INFORMATIONAL_UPDATE_VERSIONS" && -z "$LINK" ]]; then
	echo "INFORMATIONAL_UPDATE_VERSIONS requires LINK (--link)" >&2
	exit 1
fi

common=()
[[ -n "$SPARKLE_ACCOUNT" ]] && common+=(--account "$SPARKLE_ACCOUNT")
[[ -n "$ED_KEY_FILE" ]] && common+=(--ed-key-file "$ED_KEY_FILE")
[[ -n "$LINK" ]] && common+=(--link "$LINK")
[[ -n "$RELEASE_NOTES_URL_PREFIX" ]] && common+=(--release-notes-url-prefix "$RELEASE_NOTES_URL_PREFIX")
[[ -n "$FULL_RELEASE_NOTES_URL" ]] && common+=(--full-release-notes-url "$FULL_RELEASE_NOTES_URL")
[[ -n "$CRITICAL_UPDATE_VERSION" ]] && common+=(--critical-update-version "$CRITICAL_UPDATE_VERSION")
[[ -n "$PHASED_ROLLOUT_INTERVAL" ]] && common+=(--phased-rollout-interval "$PHASED_ROLLOUT_INTERVAL")
[[ -n "$INFORMATIONAL_UPDATE_VERSIONS" ]] && common+=(--informational-update-versions "$INFORMATIONAL_UPDATE_VERSIONS")
[[ -n "$MAJOR_VERSION" ]] && common+=(--major-version "$MAJOR_VERSION")
[[ -n "$IGNORE_SKIPPED_UPGRADES_BELOW_VERSION" ]] && common+=(--ignore-skipped-upgrades-below-version "$IGNORE_SKIPPED_UPGRADES_BELOW_VERSION")
[[ -n "$MAXIMUM_VERSIONS" ]] && common+=(--maximum-versions "$MAXIMUM_VERSIONS")
[[ -n "$MAXIMUM_DELTAS" ]] && common+=(--maximum-deltas "$MAXIMUM_DELTAS")
[[ -n "$DELTA_COMPRESSION" ]] && common+=(--delta-compression "$DELTA_COMPRESSION")
[[ -n "$VERSIONS" ]] && common+=(--versions "$VERSIONS")
[[ -n "$EMBED_RELEASE_NOTES" ]] && common+=(--embed-release-notes)

inject=""
if [[ -n "$MAXIMUM_SYSTEM_VERSION" || -n "$MINIMUM_UPDATE_VERSION" || -n "$EXTRA_ITEM_XML" ]]; then
	inject="            <!-- faynosync-injected:start -->"$'\n'
	[[ -n "$MAXIMUM_SYSTEM_VERSION" ]] && inject+="            <sparkle:maximumSystemVersion>$MAXIMUM_SYSTEM_VERSION</sparkle:maximumSystemVersion>"$'\n'
	[[ -n "$MINIMUM_UPDATE_VERSION" ]] && inject+="            <sparkle:minimumUpdateVersion>$MINIMUM_UPDATE_VERSION</sparkle:minimumUpdateVersion>"$'\n'
	[[ -n "$EXTRA_ITEM_XML" ]] && inject+="$EXTRA_ITEM_XML"$'\n'
	inject+="            <!-- faynosync-injected:end -->"$'\n'
fi

shopt -s nullglob
for dir in "$DIST_DIR"/*/*/*/; do
	channel=$(basename "$dir")
	rel=${dir#"$DIST_DIR"/}
	archdir=$(dirname "${dir%/}")
	appcast="$archdir/appcast.$channel.xml"

	[[ -f "$appcast" ]] && sed -i '' '/<!-- faynosync-injected:start -->/,/<!-- faynosync-injected:end -->/d' "$appcast"


	for zip in "$dir"*.zip; do
		printf '<h2>%s</h2>\n<p>Released %s</p>\n' \
			"$(basename "${zip%.zip}")" "$(date '+%Y-%m-%d %H:%M:%S %z')" > "${zip%.zip}.html"
	done

	args=(-o "$appcast")
	[[ -n "$DOWNLOAD_URL_PREFIX" ]] && args+=(--download-url-prefix "${DOWNLOAD_URL_PREFIX%/}/$rel")
	[[ -n "$SPARKLE_CHANNEL" ]] && args+=(--channel "$SPARKLE_CHANNEL")
	[[ ${#common[@]} -gt 0 ]] && args+=("${common[@]}")
	args+=("$dir")
	"$SPARKLE_BIN/generate_appcast" "${args[@]}"

	if [[ -n "$inject" ]]; then
		INJECT_BLOCK="$inject" awk '
			BEGIN { block = ENVIRON["INJECT_BLOCK"] }
			/^[[:space:]]*<\/item>[[:space:]]*$/ { printf "%s", block }
			{ print }
		' "$appcast" > "$appcast.tmp" && mv "$appcast.tmp" "$appcast"
	fi

	echo "appcast.$channel.xml written to $archdir/"
done
