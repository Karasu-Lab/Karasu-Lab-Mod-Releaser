#!/bin/bash
set -euo pipefail

TARGET_DIR="${1}"
CONFIG_PATH="${2}"

if [ "$TARGET_DIR" != "." ]; then
    if [ -f "$TARGET_DIR/$CONFIG_PATH" ]; then
        CONFIG_FILE="$TARGET_DIR/$CONFIG_PATH"
    elif [ -f "$CONFIG_PATH" ]; then
        CONFIG_FILE="$CONFIG_PATH"
    else
        CONFIG_FILE="$TARGET_DIR/$CONFIG_PATH"
    fi
else
    CONFIG_FILE="$CONFIG_PATH"
fi

BUILD_GRADLE="$TARGET_DIR/build.gradle"

if [ -f "$BUILD_GRADLE" ]; then
    GRADLE_DEPS=$(grep -oP '(modImplementation|modApi|implementation)\s*[\("]+([^"]+):([^":]+):' "$BUILD_GRADLE" \
    | grep -oP '[a-z][a-z0-9._-]+:[a-z][a-z0-9._-]+' \
    | sort -u || true)
else
    GRADLE_DEPS=""
fi

if [ -f "$CONFIG_FILE" ]; then
    EXTRA_DEPS=$(jq -r '.extra_dependencies[] // empty' "$CONFIG_FILE")
    if [ -n "$EXTRA_DEPS" ]; then
        GRADLE_DEPS="${GRADLE_DEPS}"$'\n'"${EXTRA_DEPS}"
    fi
fi

MC_PUBLISH_DEPS=""

if [ -n "$GRADLE_DEPS" ] && [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r maven_coord; do
    [ -z "$maven_coord" ] && continue
    
    ENTRY=$(jq -r --arg key "$maven_coord" '.dependencies[$key] // empty' "$CONFIG_FILE")
    [ -z "$ENTRY" ] && continue

    NAME=$(echo "$ENTRY" | jq -r '.name')
    TYPE=$(echo "$ENTRY" | jq -r '.type')
    MODRINTH_ID=$(echo "$ENTRY" | jq -r '.modrinth // empty')
    CF_ID=$(echo "$ENTRY" | jq -r '.curseforge // empty')

    PLATFORM_BLOCK=""
    [ -n "$MODRINTH_ID" ] && PLATFORM_BLOCK="${PLATFORM_BLOCK}{modrinth:${MODRINTH_ID}}"
    [ -n "$CF_ID" ] && PLATFORM_BLOCK="${PLATFORM_BLOCK}{curseforge:${CF_ID}}"

    MC_PUBLISH_DEPS="${MC_PUBLISH_DEPS}${NAME}@*($TYPE)${PLATFORM_BLOCK}"$'\n'
    done <<< "$GRADLE_DEPS"
fi

{
    echo "mc_publish_deps<<DEPS_EOF"
    echo "$MC_PUBLISH_DEPS"
    echo "DEPS_EOF"
} >> $GITHUB_OUTPUT
