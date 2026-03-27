#!/bin/bash
TITLE_FMT="${1}"
JAR_FMT="${2}"
ARCH_NAME="${3}"
MC_VER="${4}"
MOD_VER="${5}"
TAG_NAME="${6}"
LOADERS_STR="${7}"
JAR_PATH_FMT="${8}"
if [ -z "$JAR_PATH_FMT" ]; then
    JAR_PATH_FMT="{loader}/build/libs/{jar_name}"
fi
FINAL_TITLE="${TITLE_FMT}"
FINAL_TITLE="${FINAL_TITLE//\{archives_base_name\}/$ARCH_NAME}"
FINAL_TITLE="${FINAL_TITLE//\{minecraft_version\}/$MC_VER}"
FINAL_TITLE="${FINAL_TITLE//\{mod_version\}/$MOD_VER}"
FINAL_TITLE="${FINAL_TITLE//\{version\}/$TAG_NAME}"
JAR_PATHS=""
for LOADER in $LOADERS_STR; do
    JAR_NAME="${JAR_FMT}"
    JAR_NAME="${JAR_NAME//\{archives_base_name\}/$ARCH_NAME}"
    JAR_NAME="${JAR_NAME//\{minecraft_version\}/$MC_VER}"
    JAR_NAME="${JAR_NAME//\{mod_version\}/$MOD_VER}"
    JAR_NAME="${JAR_NAME//\{loader\}/$LOADER}"
    JAR_NAME="${JAR_NAME//\{version\}/$TAG_NAME}"
    J_PATH="${JAR_PATH_FMT}"
    J_PATH="${J_PATH//\{loader\}/$LOADER}"
    J_PATH="${J_PATH//\{jar_name\}/$JAR_NAME}"
    if [ -z "$JAR_PATHS" ]; then
        JAR_PATHS="$J_PATH"
    else
        JAR_PATHS="$JAR_PATHS\n$J_PATH"
    fi
done
echo "final_release_title=$FINAL_TITLE" >> $GITHUB_OUTPUT
{
    echo "final_jar_paths<<PATHS_EOF"
    echo -e "$JAR_PATHS"
    echo "PATHS_EOF"
} >> $GITHUB_OUTPUT
