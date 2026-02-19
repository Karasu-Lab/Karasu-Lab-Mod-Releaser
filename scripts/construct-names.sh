#!/bin/bash
TITLE_FMT="${1}"
JAR_FMT="${2}"
ARCHIVES_BASE_NAME="${3}"
MC_VERSION="${4}"
MOD_VERSION="${5}"
TAG_NAME="${6}"

FINAL_TITLE=$(echo "$TITLE_FMT" | sed -e "s/{archives_base_name}/$ARCHIVES_BASE_NAME/g" \
    -e "s/{minecraft_version}/$MC_VERSION/g" \
    -e "s/{mod_version}/$MOD_VERSION/g" \
    -e "s/{version}/$TAG_NAME/g")
    
FINAL_JAR=$(echo "$JAR_FMT" | sed -e "s/{archives_base_name}/$ARCHIVES_BASE_NAME/g" \
    -e "s/{minecraft_version}/$MC_VERSION/g" \
    -e "s/{mod_version}/$MOD_VERSION/g" \
    -e "s/{version}/$TAG_NAME/g")
    
echo "final_release_title=$FINAL_TITLE" >> $GITHUB_OUTPUT
echo "final_jar_name=$FINAL_JAR" >> $GITHUB_OUTPUT
