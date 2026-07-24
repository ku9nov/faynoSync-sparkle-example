SHELL := /bin/bash

.PHONY: help keys generate build appcast run clean

help:
	@echo "faynosync-sparkle-example"
	@echo "  make keys      - generate Ed25519 keys; paste SUPublicEDKey into Resources/Info.plist"
	@echo "  make generate  - run xcodegen to (re)create the Xcode project"
	@echo "  make build [CHANNEL=nightly|stable] [ARCH=arm64|amd64] - build + sign + zip into build/dist/{platform}/{arch}/{channel}"
	@echo "  make appcast   - sign archives and (re)generate appcast.{channel}.xml per arch in build/dist"
	@echo "  make run       - build and launch the app"
	@echo ""
	@echo "Prereqs: xcodegen, Xcode command line tools, Sparkle bin/ tools (SPARKLE_BIN, default ./tools)"

keys:
	@scripts/generate-keys.sh

generate:
	@xcodegen generate

build:
	@CHANNEL="$(CHANNEL)" ARCH="$(ARCH)" scripts/build.sh

appcast:
	@scripts/release.sh

run: build
	@open build/dd/Build/Products/Release/faynosyncSparkleExample.app

clean:
	@rm -rf build faynosyncSparkleExample.xcodeproj
