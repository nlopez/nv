#!/usr/bin/env bash
set -euo pipefail

CONFIGURATION="${1:-Deployment}"
PROJECT="Notation.xcodeproj"
TARGET="Notation"
OUTPUT="build/$CONFIGURATION/Notational Velocity.app"

# ── Prerequisites ────────────────────────────────────────────────────────────

check_xcode() {
    if ! xcode-select -p &>/dev/null || [[ "$(xcode-select -p)" == *"CommandLineTools"* ]]; then
        echo "error: Full Xcode is required (not just Command Line Tools)."
        echo "       Install from the App Store, then run:"
        echo "         sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"
        exit 1
    fi

    if ! xcodebuild -version &>/dev/null; then
        echo "error: Xcode license not accepted. Run:"
        echo "         sudo xcodebuild -license accept"
        exit 1
    fi
}

check_openssl() {
    for prefix in /opt/homebrew /usr/local; do
        if [[ -f "$prefix/opt/openssl@3/include/openssl/evp.h" || \
              -f "$prefix/opt/openssl/include/openssl/evp.h" ]]; then
            return 0
        fi
    done
    echo "error: OpenSSL not found. Install with:"
    echo "         brew install openssl@3"
    exit 1
}

echo "Checking prerequisites..."
check_xcode
check_openssl

# ── Build ────────────────────────────────────────────────────────────────────

LOG=$(mktemp)
trap 'rm -f "$LOG"' EXIT

echo "Building $TARGET ($CONFIGURATION)..."

set +e
xcodebuild \
    -project "$PROJECT" \
    -target   "$TARGET" \
    -configuration "$CONFIGURATION" \
    build \
    > "$LOG" 2>&1
BUILD_STATUS=$?
set -e

# Always show errors; on success show a compact step summary
if [[ $BUILD_STATUS -ne 0 ]]; then
    grep -E "^(error:|.*: error:)" "$LOG" | head -20 || true
    echo ""
    echo "Full log: $LOG"
    trap - EXIT   # keep the log around for inspection
    exit $BUILD_STATUS
else
    grep -E "^(CompileC |Ld |CopyFiles|PhaseScript)" "$LOG" \
        | sed -E 's|^(CompileC\|Ld\|CopyFiles\|PhaseScript) .*/([^/]+\.[^/ ]+) .*|\1 \2|' \
        || true
fi

# ── Result ───────────────────────────────────────────────────────────────────

echo ""
echo "✓ Built: $OUTPUT"
echo "  arch:    $(file "$OUTPUT/Contents/MacOS/Notational Velocity" | grep -oE 'arm64|x86_64')"
echo "  version: $(defaults read "$PWD/$OUTPUT/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '?')"
