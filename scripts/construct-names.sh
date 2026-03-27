#!/bin/bash
TITLE_FMT="${1}"
JAR_FMT="${2}"
ARCHIVES_BASE_NAME="${3}"
MC_VERSION="${4}"
MOD_VERSION="${5}"
TAG_NAME="${6}"
LOADERS="${7}"
JAR_PATH_FMT="${8:-{loader}/build/libs/{jar_name}}"
FINAL_TITLE=$(echo "$TITLE_FMT" | sed -e "s/{archives_base_name}/$ARCHIVES_BASE_NAME/g" -e "s/{minecraft_version}/$MC_VERSION/g" -e "s/{mod_version}/$MOD_VERSION/g" -e "s/{version}/$TAG_NAME/g")
JAR_PATHS=""
for LOADER in $LOADERS; do
    JAR_NAME=$(echo "$JAR_FMT" | sed -e "s/{archives_base_name}/$ARCHIVES_BASE_NAME/g" -e "s/{minecraft_version}/$MC_VERSION/g" -e "s/{mod_version}/$MOD_VERSION/g" -e "s/{loader}/$LOADER/g" -e "s/{version}/$TAG_NAME/g")
    JAR_PATH=$(echo "$JAR_PATH_FMT" | sed -e "s/{loader}/$LOADER/g" -e "s/{jar_name}/$JAR_NAME/g")
    JAR_PATHS="${JAR_PATHS}${JAR_PATH}\n"
done
echo "final_release_title=$FINAL_TITLE" >> $GITHUB_OUTPUT
{
    echo "final_jar_paths<<PATHS_EOF"
    echo -e "$JAR_PATHS"
    echo "PATHS_EOF"
} >> $GITHUB_OUTPUT
