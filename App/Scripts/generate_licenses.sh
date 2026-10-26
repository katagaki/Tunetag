#!/bin/bash
set -euo pipefail

RESOLVED="${SRCROOT}/Tunetag.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved"
CHECKOUTS="${BUILD_DIR%Build/*}SourcePackages/checkouts"
OUTPUT="${SRCROOT}/Tunetag/Licenses.plist"

if [ ! -f "$RESOLVED" ]; then
    echo "error: Package.resolved not found at $RESOLVED"
    exit 1
fi

if [ ! -d "$CHECKOUTS" ]; then
    echo "error: SourcePackages/checkouts not found at $CHECKOUTS"
    exit 1
fi

mkdir -p "$(dirname "$OUTPUT")"

PIN_COUNT=$(plutil -extract pins raw -o - "$RESOLVED")

ENTRIES_TSV=$(mktemp)
trap 'rm -f "$ENTRIES_TSV"' EXIT

for ((i = 0; i < PIN_COUNT; i++)); do
    LOCATION=$(plutil -extract "pins.$i.location" raw -o - "$RESOLVED")
    NAME=${LOCATION%/}
    NAME=${NAME##*/}
    NAME=${NAME%.git}
    [ -z "$NAME" ] && continue

    ACTUAL_DIR=""
    NAME_LOWER=$(printf '%s' "$NAME" | tr '[:upper:]' '[:lower:]')
    for entry in "$CHECKOUTS"/*; do
        [ -d "$entry" ] || continue
        BASE=$(basename "$entry")
        BASE_LOWER=$(printf '%s' "$BASE" | tr '[:upper:]' '[:lower:]')
        if [ "$BASE_LOWER" = "$NAME_LOWER" ]; then
            ACTUAL_DIR=$BASE
            break
        fi
    done

    if [ -z "$ACTUAL_DIR" ]; then
        echo "warning: no checkout directory for $NAME"
        continue
    fi

    LICENSE_PATHS=()
    while IFS= read -r path; do
        LICENSE_PATHS+=("$path")
    done < <(find "$CHECKOUTS/$ACTUAL_DIR" -maxdepth 1 -type f \
        \( -iname 'LICENSE' -o -iname 'LICENSE.*' -o -iname 'LICENSE-*' \) | sort)

    if [ "${#LICENSE_PATHS[@]}" -eq 0 ]; then
        echo "warning: no LICENSE file found for $NAME"
        continue
    fi

    SORT_KEY=$(printf '%s' "$ACTUAL_DIR" | tr '[:upper:]' '[:lower:]')
    JOINED_PATHS=$(IFS='|'; printf '%s' "${LICENSE_PATHS[*]}")
    printf '%s\t%s\t%s\n' "$SORT_KEY" "$ACTUAL_DIR" "$JOINED_PATHS" >> "$ENTRIES_TSV"
done

SORTED_TSV=$(mktemp)
sort -t $'\t' -k1,1 "$ENTRIES_TSV" > "$SORTED_TSV"

echo '{}' | plutil -convert xml1 -o "$OUTPUT" -
plutil -insert dependencies -array "$OUTPUT"

INDEX=0
COUNT=0
while IFS=$'\t' read -r _ name paths; do
    IFS='|' read -r -a path_array <<< "$paths"

    if [ "${#path_array[@]}" -gt 1 ]; then
        TEXT=""
        for path in "${path_array[@]}"; do
            BODY=$(tr -d '\000-\010\013\014\016-\037' < "$path")
            if [ -n "$TEXT" ]; then
                TEXT+=$'\n\n'
            fi
            TEXT+="--- $(basename "$path") ---"$'\n'"$BODY"
        done
    else
        TEXT=$(tr -d '\000-\010\013\014\016-\037' < "${path_array[0]}")
    fi

    plutil -insert "dependencies.$INDEX" -dictionary "$OUTPUT"
    plutil -insert "dependencies.$INDEX.name" -string "$name" "$OUTPUT"
    plutil -insert "dependencies.$INDEX.licenseText" -string "$TEXT" "$OUTPUT"

    INDEX=$((INDEX + 1))
    COUNT=$((COUNT + 1))
done < "$SORTED_TSV"

rm -f "$SORTED_TSV"

echo "Generated $OUTPUT with $COUNT entries"
