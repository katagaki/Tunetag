#!/bin/bash
set -euo pipefail

cd "$CI_PRIMARY_REPOSITORY_PATH"

xcodebuild -resolvePackageDependencies \
    -project Tunetag.xcodeproj \
    -scheme Tunetag \
    -derivedDataPath "$CI_DERIVED_DATA_PATH"

export SRCROOT="$CI_PRIMARY_REPOSITORY_PATH"
export BUILD_DIR="$CI_DERIVED_DATA_PATH/Build/"

"$CI_PRIMARY_REPOSITORY_PATH/Scripts/generate_licenses.sh"

