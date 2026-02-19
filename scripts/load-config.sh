#!/bin/bash
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

if [ -f "$CONFIG_FILE" ]; then
    echo "Loading config from $CONFIG_FILE"
    JAVA_VERSION=$(jq -r '.java // 21' "$CONFIG_FILE")
    LOADERS=$(jq -r '.loaders | join("\n") // "fabric"' "$CONFIG_FILE")
    RELEASE_TITLE_FORMAT=$(jq -r '.release_title_format // "{archives_base_name}-{mod_version}-{minecraft_version}"' "$CONFIG_FILE")
    JAR_NAME_FORMAT=$(jq -r '.jar_name_format // "{archives_base_name}-{mod_version}-{minecraft_version}.jar"' "$CONFIG_FILE")
else
    echo "Config file not found: $CONFIG_FILE, using defaults."
    JAVA_VERSION="21"
    LOADERS="fabric"
    RELEASE_TITLE_FORMAT="{archives_base_name}-{mod_version}-{minecraft_version}"
    JAR_NAME_FORMAT="{archives_base_name}-{mod_version}-{minecraft_version}.jar"
fi

echo "java_version=$JAVA_VERSION" >> $GITHUB_OUTPUT
echo "release_title_format=$RELEASE_TITLE_FORMAT" >> $GITHUB_OUTPUT
echo "jar_name_format=$JAR_NAME_FORMAT" >> $GITHUB_OUTPUT
{
    echo "loaders<<LOADER_EOF"
    echo "$LOADERS"
    echo "LOADER_EOF"
} >> $GITHUB_OUTPUT
