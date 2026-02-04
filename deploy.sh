#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# Check if a version number is provided as an argument.
if [ -z "$1" ]; then
  echo "Error: No version tag provided."
  echo "Usage: ./deploy.sh V<version_number>"
  echo "Example: ./deploy.sh V0.0.2"
  exit 1
fi

VERSION=$1
REPO="omna25data-afk/qlm_guardian_app_4"
APK_PATH="build/app/outputs/flutter-apk/app-prod-release.apk"
ENTRY_POINT="lib/main_prod.dart"

echo "--- Starting build and deployment for version $VERSION ---"

# 1. Build the Flutter APK for the 'prod' flavor using the correct entry point.
echo "--- Building Flutter APK for prod flavor from $ENTRY_POINT... ---"
flutter build apk --flavor prod -t $ENTRY_POINT

# Check if APK was created
if [ ! -f "$APK_PATH" ]; then
    echo "Error: APK file not found at $APK_PATH"
    exit 1
fi

echo "--- APK built successfully at $APK_PATH ---"

# 2. Create GitHub release and upload the APK.
echo "--- Creating GitHub release and uploading APK... ---"
nix-shell -p github-cli --run "gh release create $VERSION '$APK_PATH' --repo '$REPO' --title 'Version $VERSION' --notes 'Release for version $VERSION'"

echo "--- Successfully created release $VERSION and uploaded the APK! ---"
echo "Visit the release at: https://github.com/$REPO/releases/tag/$VERSION"
