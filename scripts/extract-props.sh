#!/bin/bash
TARGET_DIR="${1}"
PROPS_FILE="$TARGET_DIR/gradle.properties"

if [ -f "$PROPS_FILE" ]; then
    ARCHIVES_BASE_NAME=$(grep -oP '(?i)^(archives_?base_?name)\s*=\s*\K[^\s]+' "$PROPS_FILE" || echo "")
    MINECRAFT_VERSION=$(grep -oP '(?i)^(minecraft_?version)\s*=\s*\K[^\s]+' "$PROPS_FILE" || echo "")
    MOD_VERSION=$(grep -oP '(?i)^(mod_?version)\s*=\s*\K[^\s]+' "$PROPS_FILE" || echo "")
    
    echo "Extracted properties from $PROPS_FILE:"
    echo "ARCHIVES_BASE_NAME: '$ARCHIVES_BASE_NAME'"
    echo "MINECRAFT_VERSION: '$MINECRAFT_VERSION'"
    echo "MOD_VERSION: '$MOD_VERSION'"

    if [ -z "$ARCHIVES_BASE_NAME" ] || [ -z "$MINECRAFT_VERSION" ] || [ -z "$MOD_VERSION" ]; then
        echo "Error: Failed to extract one or more required properties from $PROPS_FILE."
        echo "Please ensure archives_base_name, minecraft_version, and mod_version are defined."
        exit 1
    fi
    
    echo "archives_base_name=$ARCHIVES_BASE_NAME" >> $GITHUB_OUTPUT
    echo "minecraft_version=$MINECRAFT_VERSION" >> $GITHUB_OUTPUT
    echo "mod_version=$MOD_VERSION" >> $GITHUB_OUTPUT
else
        echo "$PROPS_FILE not found!"
        exit 1
fi
