#!/bin/bash
# Build Pock from source and install it to /Applications, replacing whatever
# is already there (a backup of the previous app is kept in build/).
#
# Prerequisites:
#   - Full Xcode (xcode-select -p must point at Xcode.app, not CommandLineTools)
#   - CocoaPods (`brew install cocoapods`)
#   - Network access to github.com and the CocoaPods CDN (set HTTPS_PROXY if needed)
#
# Usage:
#   ./build-and-install.sh              # build Release + install
#   ./build-and-install.sh --build-only # leave the product in build/
#   HTTPS_PROXY=http://proxy.example:8080 ./build-and-install.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

BUILD_ONLY=0
if [[ "${1:-}" == "--build-only" ]]; then
    BUILD_ONLY=1
fi

die() { echo "Error: $*" >&2; exit 1; }

# --- Environment checks -------------------------------------------------------

DEV_DIR="$(xcode-select -p 2>/dev/null || true)"
if [[ -z "$DEV_DIR" || "$DEV_DIR" == *CommandLineTools* ]]; then
    XCODE_APP="$(ls -d /Applications/Xcode*.app 2>/dev/null | head -1)"
    [[ -n "$XCODE_APP" ]] && HINT="sudo xcode-select -s ${XCODE_APP}/Contents/Developer" \
                          || HINT="install Xcode from the App Store, then: sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
    die "Full Xcode is required (xcode-select -p reports '${DEV_DIR:-none}'). $HINT"
fi
if ! xcodebuild -version >/dev/null 2>&1; then
    die "xcodebuild is not usable at $DEV_DIR"
fi

command -v xcodebuild >/dev/null || die "xcodebuild not found"
command -v pod >/dev/null || die "CocoaPods not found. Run: brew install cocoapods"

# Propagate any user-provided proxy settings to the tools spawned below
# (pod, git) — some of them only read the lowercase variants.
export HTTPS_PROXY="${HTTPS_PROXY:-}"
export HTTP_PROXY="${HTTP_PROXY:-}"
export https_proxy="${HTTPS_PROXY}"
export http_proxy="${HTTP_PROXY}"
export ALL_PROXY="${ALL_PROXY:-${HTTPS_PROXY}}"

echo "==> Xcode: $(xcodebuild -version | tr '\n' ' ')"
echo "==> Proxy: ${HTTPS_PROXY:-<none>}"

# --- Confirm the crash fix is present ----------------------------------------

if ! grep -q 'guard let parent = parentView' \
    Pock/UI/TouchBar/EmptyTouchBarController/EmptyTouchBarController.swift; then
    die "Source fix missing from EmptyTouchBarController.button(at:). Wrong branch?"
fi
echo "==> Source fix present (EmptyTouchBarController.button(at:))"

# --- CocoaPods ----------------------------------------------------------------

echo "==> pod install (also refreshes existing Pods)"
pod install

# --- Build --------------------------------------------------------------------

DERIVED="$ROOT/build/DerivedData"
rm -rf "$DERIVED"
mkdir -p "$DERIVED"

echo "==> Building Pock (Release, ad-hoc signed)"
# CODE_SIGN_IDENTITY=- : ad-hoc signing, so the app runs without a developer
# account.
# The project's Run Script no longer copies to /Applications; installing here
# keeps the build idempotent and lets us back up the previous app first.
xcodebuild \
    -workspace Pock.xcworkspace \
    -scheme Pock \
    -configuration Release \
    -derivedDataPath "$DERIVED" \
    -destination 'generic/platform=macOS' \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=YES \
    build

APP="$DERIVED/Build/Products/Release/Pock.app"
[[ -d "$APP" ]] || die "Build product not found at $APP"

echo "==> Built: $APP"
codesign -dv "$APP" 2>&1 | head -5 || true

if [[ "$BUILD_ONLY" -eq 1 ]]; then
    echo "==> --build-only: skipping install"
    exit 0
fi

# --- Install ------------------------------------------------------------------

echo "==> Stopping running Pock"
killall Pock 2>/dev/null || true
sleep 1

# Keep a one-shot rollback of whatever is currently installed.
BACKUP_DIR="$ROOT/build/previous-install"
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"
if [[ -d /Applications/Pock.app ]]; then
    echo "==> Backing up current /Applications/Pock.app -> $BACKUP_DIR/Pock.app"
    ditto /Applications/Pock.app "$BACKUP_DIR/Pock.app"
fi

echo "==> Installing to /Applications/Pock.app"
rm -rf /Applications/Pock.app
ditto "$APP" /Applications/Pock.app

# Ad-hoc re-sign after ditto (ditto can drop the signature).
codesign -f -s - /Applications/Pock.app

echo "==> Launching Pock"
open -a Pock

echo "==> Done. Source-built Pock is now at /Applications/Pock.app"
echo "    Previous install (if any) backed up under build/previous-install/."
echo "    If Pock was previously installed via Homebrew, do not let brew"
echo "    upgrade it over this build ('brew uninstall --cask pock' would also"
echo "    delete /Applications/Pock.app)."
