#!/bin/bash

# FaithLock - TestFlight Build Script
# Usage: ./scripts/build_testflight.sh [--preflight-only]

set -e  # Exit on error

echo "🚀 Building FaithLock for TestFlight..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PREFLIGHT_ONLY=0
if [ "${1:-}" = "--preflight-only" ]; then
  PREFLIGHT_ONLY=1
fi

# 0. Preflight — fail before any expensive work.
# `lib/config/env.g.dart` is generated from `.env` and is git-ignored, and
# `PostHogService.init` silently disables analytics when the API key is empty.
# A build without these values compiles but emits no analytics, which makes a
# measurement test read as "no events" instead of "broken build input".
PREFLIGHT_FAILED=0

for tool in flutter dart; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo -e "${RED}❌ $tool not found in PATH.${NC} Run this script from a macOS host with the Flutter SDK installed."
    PREFLIGHT_FAILED=1
  fi
done

if [ ! -f ".env" ]; then
  echo -e "${RED}❌ .env is missing.${NC} It is git-ignored and required to generate lib/config/env.g.dart."
  echo "   Create it from the team secret store; never commit it."
  PREFLIGHT_FAILED=1
else
  # Read a key's value from .env, ignoring surrounding whitespace and one layer
  # of matching quotes. envied reads the value literally, so `KEY=""` and
  # `KEY="  "` produce an empty string at build time even though the line
  # matches a naive pattern.
  env_value() {
    local key="$1" raw line
    line=$(grep -E "^${key}=" .env | head -n 1 || true)
    raw="${line#*=}"
    raw="${raw#"${raw%%[![:space:]]*}"}"
    raw="${raw%"${raw##*[![:space:]]}"}"
    if [[ "$raw" == \"*\" || "$raw" == \'*\' ]]; then
      raw="${raw:1:${#raw}-2}"
      raw="${raw#"${raw%%[![:space:]]*}"}"
      raw="${raw%"${raw##*[![:space:]]}"}"
    fi
    printf '%s' "$raw"
  }

  # Fields without a default in lib/config/env.dart: the build cannot be
  # generated without them. Report only the names, never the values.
  for key in POSTHOG_API_KEY REVENUECAT_API_KEY OPENAI_API_KEY; do
    if [ -z "$(env_value "$key")" ]; then
      echo -e "${RED}❌ ${key} is missing or empty in .env.${NC}"
      PREFLIGHT_FAILED=1
    fi
  done

  # A present-but-empty key would let the build succeed with analytics off, so
  # the check above already rejects it: no silent-disable path is allowed for
  # a build whose measurement test depends on these events.
fi

if [ "$PREFLIGHT_FAILED" -ne 0 ]; then
  echo ""
  echo -e "${RED}Preflight failed. No build was started.${NC}"
  exit 1
fi

APP_VERSION=$(grep -E '^version:' pubspec.yaml | awk '{print $2}')
echo -e "${GREEN}✅ Preflight passed.${NC} Building version ${APP_VERSION} (record this build number with any measurement test)."

if [ "$PREFLIGHT_ONLY" -eq 1 ]; then
  echo "Preflight-only mode: stopping before build."
  exit 0
fi

# 1. Clean
echo -e "${BLUE}📦 Cleaning previous builds...${NC}"
flutter clean

# 2. Get dependencies
echo -e "${BLUE}📥 Getting dependencies...${NC}"
flutter pub get

# 3. Generate build-time constants (lib/config/env.g.dart from .env).
# This used to be gated on a file named "build_runner", which never exists, so
# code generation never ran and a fresh checkout could not compile.
echo -e "${BLUE}⚙️  Running code generation...${NC}"
dart run build_runner build --delete-conflicting-outputs

if [ ! -f "lib/config/env.g.dart" ]; then
  echo -e "${RED}❌ Code generation did not produce lib/config/env.g.dart.${NC}"
  exit 1
fi

# 4. Build IPA for TestFlight (Development Export)
echo -e "${BLUE}🔨 Building IPA for TestFlight...${NC}"
echo -e "${BLUE}Using Development provisioning profile...${NC}"
flutter build ipa --release --export-options-plist=ios/ExportOptions.plist

# 5. Locate the IPA
IPA_PATH="build/ios/ipa/faithlock.ipa"

echo ""
echo -e "${GREEN}✅ Build complete!${NC}"
echo ""
echo -e "${BLUE}📱 Your IPA is ready:${NC}"
echo -e "${GREEN}${IPA_PATH}${NC}"
echo -e "${BLUE}   Version ${APP_VERSION}${NC}"
echo ""
echo -e "${BLUE}📤 Next steps:${NC}"
echo "Option A - Xcode Organizer:"
echo "  1. Open Xcode → Window → Organizer"
echo "  2. Click 'Distribute App'"
echo "  3. Select 'TestFlight & App Store'"
echo "  4. Upload"
echo ""
echo "Option B - Transporter App:"
echo "  1. Open Transporter app"
echo "  2. Drag ${IPA_PATH}"
echo "  3. Click 'Deliver'"
echo ""
echo "Option C - Command Line:"
echo "  xcrun altool --upload-app --type ios --file ${IPA_PATH} \\"
echo "    --apiKey YOUR_KEY --apiIssuer YOUR_ISSUER"
echo ""
echo -e "${GREEN}🎉 Ready for TestFlight!${NC}"
