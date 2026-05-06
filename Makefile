# PortPeek - macOS Makefile
# Usage: make help

# Configuration
APP_NAME       := PortPeek
BUNDLE_ID      := com.jabar.portpeek
VERSION        := 1.0.0
BUILD_NUMBER   := 1
CODESIGN_IDENTITY ?= -

# Paths
BUILD_DIR      := build
APP_BUNDLE     := $(BUILD_DIR)/$(APP_NAME).app
DMG_NAME       := $(BUILD_DIR)/PortPeek-$(VERSION).dmg
RELEASE_BIN    := PortPeek/.build/release/PortPeek
DEBUG_BIN      := PortPeek/.build/debug/PortPeek

# Tools
SWIFT_FORMAT   := swift-format
DEVELOPER_DIR  := /Applications/Xcode.app/Contents/Developer

.PHONY: all build build-release bundle codesign dmg install uninstall \
        run snapshot test test-verbose resolve format lint xcode clean help

# Default: full distribution build
all: build-release bundle codesign

# --- Build ---

build:
	swift build --package-path PortPeek
	swift build --package-path PortPeekCapture

build-release:
	swift build --package-path PortPeek -c release

# --- App Bundle ---

bundle: build-release
	@echo "Creating app bundle..."
	@rm -rf "$(APP_BUNDLE)"
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"
	@cp $(RELEASE_BIN) "$(APP_BUNDLE)/Contents/MacOS/PortPeek"
	@sed -e 's/BUNDLE_ID_PLACEHOLDER/$(BUNDLE_ID)/' \
	     -e 's/VERSION_PLACEHOLDER/$(VERSION)/' \
	     -e 's/BUILD_NUMBER_PLACEHOLDER/$(BUILD_NUMBER)/' \
	     PortPeek/Info.plist > "$(APP_BUNDLE)/Contents/Info.plist"
	@echo "APPL????" > "$(APP_BUNDLE)/Contents/PkgInfo"
	@echo "Built $(APP_BUNDLE)"

# --- Code Signing ---

codesign: bundle
	@echo "Signing with identity: $(CODESIGN_IDENTITY)"
	codesign --force --options runtime \
		--entitlements PortPeek/PortPeek.entitlements \
		--sign "$(CODESIGN_IDENTITY)" \
		"$(APP_BUNDLE)"
	@echo "Verifying signature..."
	codesign --verify --verbose "$(APP_BUNDLE)"

# --- DMG Packaging ---

dmg: codesign
	@echo "Creating DMG..."
	@rm -f "$(DMG_NAME)"
	@mkdir -p "$(BUILD_DIR)/dmg-staging"
	@cp -R "$(APP_BUNDLE)" "$(BUILD_DIR)/dmg-staging/"
	@ln -sf /Applications "$(BUILD_DIR)/dmg-staging/Applications"
	hdiutil create -volname "$(APP_NAME)" \
		-srcfolder "$(BUILD_DIR)/dmg-staging" \
		-ov -format UDZO \
		"$(DMG_NAME)"
	@rm -rf "$(BUILD_DIR)/dmg-staging"
	@echo "Created $(DMG_NAME)"

# --- Install ---

install: codesign
	@echo "Installing to /Applications..."
	@rm -rf "/Applications/$(APP_NAME).app"
	cp -R "$(APP_BUNDLE)" "/Applications/$(APP_NAME).app"
	@echo "Installed."

uninstall:
	@echo "Removing from /Applications..."
	rm -rf "/Applications/$(APP_NAME).app"
	@echo "Uninstalled."

# --- Run & Test ---

run:
	swift run --package-path PortPeek PortPeek

snapshot:
	swift run --package-path PortPeekCapture PortPeekCapture port-peek-screenshot.png

test:
	DEVELOPER_DIR=$(DEVELOPER_DIR) swift test --package-path PortPeek

test-verbose:
	DEVELOPER_DIR=$(DEVELOPER_DIR) swift test --package-path PortPeek --verbose

# --- Dependencies ---

resolve:
	swift package --package-path PortPeek resolve
	swift package --package-path PortPeekCapture resolve

# --- Code Quality ---

format:
	@if command -v $(SWIFT_FORMAT) >/dev/null 2>&1; then \
		$(SWIFT_FORMAT) format --in-place --recursive PortPeek/Sources PortPeek/Tests PortPeekCapture/Sources; \
		echo "Formatted."; \
	else \
		echo "swift-format not found. Install: brew install swift-format"; \
		exit 1; \
	fi

lint:
	@if command -v $(SWIFT_FORMAT) >/dev/null 2>&1; then \
		$(SWIFT_FORMAT) lint --recursive PortPeek/Sources PortPeek/Tests PortPeekCapture/Sources; \
	else \
		echo "swift-format not found. Install: brew install swift-format"; \
		exit 1; \
	fi

# --- Xcode ---

xcode:
	open PortPeek/Package.swift

# --- Clean ---

clean:
	swift package --package-path PortPeek clean
	swift package --package-path PortPeekCapture clean
	rm -rf $(BUILD_DIR)
	rm -f port-peek-screenshot.png

# --- Help ---

help:
	@echo "PortPeek - Build Targets"
	@echo ""
	@echo "  make build          Debug build (both packages)"
	@echo "  make build-release  Optimized release build"
	@echo "  make bundle         Create .app bundle from release build"
	@echo "  make codesign       Sign the .app (set CODESIGN_IDENTITY for non-adhoc)"
	@echo "  make dmg            Package signed .app into a DMG"
	@echo "  make install        Copy .app to /Applications"
	@echo "  make uninstall      Remove from /Applications"
	@echo "  make all            build-release + bundle + codesign"
	@echo ""
	@echo "  make run            Run debug build"
	@echo "  make snapshot       Capture UI screenshot"
	@echo "  make test           Run test suite"
	@echo "  make test-verbose   Run tests with verbose output"
	@echo ""
	@echo "  make resolve        Resolve Swift package dependencies"
	@echo "  make format         Format sources with swift-format"
	@echo "  make lint           Lint sources (no changes)"
	@echo "  make xcode          Open package in Xcode"
	@echo ""
	@echo "  make clean          Remove all build artifacts"
	@echo "  make help           Show this help"
	@echo ""
	@echo "Variables:"
	@echo "  VERSION=x.y.z          App version (default: $(VERSION))"
	@echo "  BUILD_NUMBER=N         Build number (default: $(BUILD_NUMBER))"
	@echo "  CODESIGN_IDENTITY=id   Signing identity (default: - for ad-hoc)"
