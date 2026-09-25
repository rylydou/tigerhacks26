# Detect the host OS / architecture (used for CPU count and the Butler download)
UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)

# Run in parallel using all available CPU cores
#ifeq ($(UNAME_S),Darwin)
#NPROCS := $(shell sysctl -n hw.ncpu)
#else
#NPROCS := $(shell nproc)
#endif
#MAKEFLAGS += -j$(NPROCS)

# The names of the export presets defined in export_presets.cfg to build and publish
platforms := html linux windows macos

# The project path on itch.io, in the format "username/projectname"
ITCH_PATH := ciber-turtle/nanobots

# The title of the executable to be generated (without extension)
# Note: Used inside double quotes in recipes, so spaces are fine but avoid quotes.
EXE_TITLE := Nanobots

BUTLER := .godot/bin/butler/butler

# Path to the Godot executable (the binary inside the .app bundle, not the bundle itself).
# Override from the command line or environment, e.g. `make build-all GODOT=/path/to/godot`.
GODOT ?= /Users/ryly/Library/Application Support/Godot/app_userdata/Godots/versions/Godot_v4_7_2-stable_macos_universal/Godot.app/Contents/MacOS/Godot

# Command to build the project with Godot, shared across all platforms
GODOT_BUILD := "$(GODOT)" --headless --quiet --no-header --lsp-port 0 --path . --export-release

# ----- macOS signing / notarization -----
# By default the app is ad-hoc signed ("-"). That is enough for it to launch on other Macs,
# but Gatekeeper will still ask the user to approve it (System Settings > Privacy & Security >
# Open Anyway) because it isn't notarized.
# For a build that opens with no warnings, set these (requires a paid Apple Developer account):
#   MACOS_SIGN_IDENTITY  "Developer ID Application: Your Name (TEAMID)"
#   NOTARY_PROFILE       keychain profile created with `xcrun notarytool store-credentials`
MACOS_SIGN_IDENTITY ?= -
NOTARY_PROFILE ?=

MACOS_STAGE := .godot/build/macos
MACOS_APP := $(MACOS_STAGE)/dmg/$(EXE_TITLE).app
MACOS_DMG := bin/macos/$(EXE_TITLE).dmg
MACOS_ZIP := bin/$(EXE_TITLE)-macos.zip

ifeq ($(MACOS_SIGN_IDENTITY),-)
CODESIGN_FLAGS := --force --deep --sign -
else
CODESIGN_FLAGS := --force --deep --options runtime --timestamp --sign "$(MACOS_SIGN_IDENTITY)"
endif

.PHONY: build-html build-windows build-linux build-macos build-all publish-all clean \
	download-butler upgrade-butler setup-butler

# Keep Godot from importing exported builds back into the project
bin/.gdignore:
	@mkdir -p bin
	@touch $@


# ===== Build targets for each platform =====

build-html: bin/.gdignore
	@echo "🛠️ Building HTML5"
	@mkdir -p bin/html
	@$(GODOT_BUILD) html bin/html/index.html


build-windows: bin/.gdignore
	@echo "🛠️ Building Windows"
	@mkdir -p bin/windows
	@$(GODOT_BUILD) windows "bin/windows/$(EXE_TITLE).exe"


build-linux: bin/.gdignore
	@echo "🛠️ Building Linux"
	@mkdir -p bin/linux
	@$(GODOT_BUILD) linux "bin/linux/$(EXE_TITLE).x86_64"


# Exports a .app, signs it, wraps it in a .dmg (with an Applications shortcut), optionally
# notarizes + staples it, then zips the .dmg with ditto so nothing gets stripped in transit.
build-macos: bin/.gdignore
ifneq ($(UNAME_S),Darwin)
	$(error build-macos requires a macOS host (codesign / hdiutil))
endif
	@echo "🛠️ Building MacOS"
	@rm -rf "$(MACOS_STAGE)" bin/macos "$(MACOS_ZIP)"
	@mkdir -p "$(MACOS_STAGE)/dmg" bin/macos
	@$(GODOT_BUILD) macos "$(MACOS_APP)"
	@test -d "$(MACOS_APP)" || { echo "❌ Godot did not produce $(MACOS_APP)"; exit 1; }
	@echo "🔏 Signing app ($(MACOS_SIGN_IDENTITY))"
	@xattr -cr "$(MACOS_APP)"
	@codesign $(CODESIGN_FLAGS) "$(MACOS_APP)"
	@codesign --verify --deep --strict "$(MACOS_APP)"
	@ln -s /Applications "$(MACOS_STAGE)/dmg/Applications"
	@echo "💿 Creating DMG"
	@hdiutil create -quiet -volname "$(EXE_TITLE)" -srcfolder "$(MACOS_STAGE)/dmg" \
		-fs HFS+ -format UDZO -ov "$(MACOS_DMG)"
ifneq ($(MACOS_SIGN_IDENTITY),-)
	@codesign --force --timestamp --sign "$(MACOS_SIGN_IDENTITY)" "$(MACOS_DMG)"
endif
ifneq ($(NOTARY_PROFILE),)
	@echo "📨 Notarizing DMG (this can take a few minutes)"
	@xcrun notarytool submit "$(MACOS_DMG)" --keychain-profile "$(NOTARY_PROFILE)" --wait
	@xcrun stapler staple "$(MACOS_DMG)"
endif
	@echo "🗜️ Zipping DMG"
	@ditto -c -k --sequesterRsrc "$(MACOS_DMG)" "$(MACOS_ZIP)"
	@echo "✅ $(MACOS_DMG) and $(MACOS_ZIP)"


# ===== General Utilities =====

# Publish a specific platform to Itch.io
publish-%: build-% $(BUTLER)
	@echo "☁️ Publishing $*"
	@$(BUTLER) push --if-changed --fix-permissions --auto-wrap --dereference bin/$* $(ITCH_PATH):$*


# Publish all platforms
publish-all: $(addprefix publish-,$(platforms))
	@echo "✅ Published all platforms"


build-all: $(addprefix build-,$(platforms))
	@echo "✅ Built all platforms"

# Delete all build artifacts
clean:
	@echo "🧹 Cleaning build artifacts..."
	@rm -rf bin/* .godot/build


# ===== Butler Management =====

ifeq ($(UNAME_S),Darwin)
ifeq ($(UNAME_M),arm64)
BUTLER_CHANNEL := darwin-arm64
else
BUTLER_CHANNEL := darwin-amd64
endif
else
BUTLER_CHANNEL := linux-amd64
endif

$(BUTLER):
	@mkdir -p $(dir $@)
	@echo " Downloading Butler ($(BUTLER_CHANNEL))..."
	@curl -#L https://broth.itch.zone/butler/$(BUTLER_CHANNEL)/LATEST/archive/default -o .godot/bin/butler.zip
	@echo "Extracting Butler..."
	@unzip -o .godot/bin/butler.zip -d .godot/bin/butler
	@rm .godot/bin/butler.zip
	@chmod +x $@


download-butler: $(BUTLER)
	@echo "✅ Butler is ready to use!"


upgrade-butler: $(BUTLER)
	@$(BUTLER) upgrade


setup-butler: $(BUTLER)
	@$(BUTLER) login
