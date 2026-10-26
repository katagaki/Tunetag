#!/bin/bash
set -euo pipefail

APP_PATH="$CI_PRIMARY_REPOSITORY_PATH/App"

cd "$APP_PATH"

xcodebuild -resolvePackageDependencies \
    -project Tunetag.xcodeproj \
    -scheme Tunetag \
    -derivedDataPath "$CI_DERIVED_DATA_PATH"

export SRCROOT="$APP_PATH"
export BUILD_DIR="$CI_DERIVED_DATA_PATH/Build/"

"$APP_PATH/Scripts/generate_licenses.sh"
