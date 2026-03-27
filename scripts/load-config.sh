#!/bin/bash
TARGET_DIR="${1}"
CONFIG_PATH="${2}"
if [ "$TARGET_DIR" != "." ]; then
    CONFIG_FILE="$TARGET_DIR/$CONFIG_PATH"
else
    CONFIG_FILE="$CONFIG_PATH"
fi
if [ -f "$CONFIG_FILE" ]; then
    JAVA_VERSION=$(jq -r '.java // 21' "$CONFIG_FILE")
    LOADERS=$(jq -r '.loaders | join("\n") // "fabric"' "$CONFIG_FILE")
    TITLE_FMT=$(jq -r '.release_title_format // "{archives_base_name} {mod_version} for MC {minecraft_version}"' "$CONFIG_FILE")
    JAR_FMT=$(jq -r '.jar_name_format // "{archives_base_name}-{mod_version}-{minecraft_version}.jar"' "$CONFIG_FILE")
    JAR_PATH_FMT=$(jq -r '.jar_path_format // "{loader}/build/libs/{jar_name}"' "$CONFIG_FILE")
    ENV=$(jq -r '.environment // "both"' "$CONFIG_FILE")
    CHANNEL=$(jq -r '.release_channel // "release"' "$CONFIG_FILE")
else
    JAVA_VERSION="21"
    LOADERS="fabric"
    TITLE_FMT="{archives_base_name} {mod_version} for MC {minecraft_version}"
    JAR_FMT="{archives_base_name}-{mod_version}-{minecraft_version}.jar"
    JAR_PATH_FMT="{loader}/build/libs/{jar_name}"
    ENV="both"
    CHANNEL="release"
fi
echo "java_version=$JAVA_VERSION" >> $GITHUB_OUTPUT
echo "release_title_format=$TITLE_FMT" >> $GITHUB_OUTPUT
echo "jar_name_format=$JAR_FMT" >> $GITHUB_OUTPUT
echo "jar_path_format=$JAR_PATH_FMT" >> $GITHUB_OUTPUT
echo "environment=$ENV" >> $GITHUB_OUTPUT
echo "release_channel=$CHANNEL" >> $GITHUB_OUTPUT
{
    echo "loaders<<LOADER_EOF"
    echo "$LOADERS"
    echo "LOADER_EOF"
} >> $GITHUB_OUTPUT
