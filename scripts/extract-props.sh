#!/bin/bash
TARGET_DIR="${1}"
PROPS_FILE="$TARGET_DIR/gradle.properties"
if [ -f "$PROPS_FILE" ]; then
    ARCHIVES_BASE_NAME=$(grep -oP '(?i)^(archives_?base_?name|archives_?name)\s*=\s*\K[^\s]+' "$PROPS_FILE" || echo "")
    MINECRAFT_VERSION=$(grep -oP '(?i)^(minecraft_?version)\s*=\s*\K[^\s]+' "$PROPS_FILE" || echo "")
    MOD_VERSION=$(grep -oP '(?i)^(mod_?version)\s*=\s*\K[^\s]+' "$PROPS_FILE" || echo "")
    if [ -n "${RELEASE_VERSION:-}" ]; then
        MOD_VERSION="${RELEASE_VERSION}"
    fi
    if [ -z "$ARCHIVES_BASE_NAME" ] || [ -z "$MINECRAFT_VERSION" ] || [ -z "$MOD_VERSION" ]; then
        exit 1
    fi
    echo "archives_base_name=$ARCHIVES_BASE_NAME" >> $GITHUB_OUTPUT
    echo "minecraft_version=$MINECRAFT_VERSION" >> $GITHUB_OUTPUT
    echo "mod_version=$MOD_VERSION" >> $GITHUB_OUTPUT
else
    exit 1
fi
