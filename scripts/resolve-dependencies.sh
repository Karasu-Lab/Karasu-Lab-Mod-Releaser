#!/bin/bash
TARGET_DIR="${1}"
CONFIG_PATH="${2}"
if [ "$TARGET_DIR" != "." ]; then
    CONFIG_FILE="$TARGET_DIR/$CONFIG_PATH"
else
    CONFIG_FILE="$CONFIG_PATH"
fi
GRADLE_DEPS=""
while IFS= read -r f; do
    DEPS=$(grep -oP '(modImplementation|modApi|modRuntimeOnly|implementation|api|runtimeOnly)\s*[\("]+([^"'\':]+):([^"'\':]+)[:"'\']' "$f" \
    | sed -E 's/.*["'\'']([^"'\':]+:[^"'\':]+)["'\''].*/\1/' \
    | sort -u || true)
    if [ -n "$DEPS" ]; then
        GRADLE_DEPS="${GRADLE_DEPS}"$'\n'"${DEPS}"
    fi
done < <(find "$TARGET_DIR" -name "build.gradle" -not -path "*/build/*")
GRADLE_DEPS=$(echo -e "$GRADLE_DEPS" | sed '/^$/d' | sort -u)
if [ -f "$CONFIG_FILE" ]; then
    EXTRA_DEPS=$(jq -r '.extra_dependencies // [] | .[]' "$CONFIG_FILE")
    if [ -n "$EXTRA_DEPS" ]; then
        GRADLE_DEPS="${GRADLE_DEPS}"$'\n'"${EXTRA_DEPS}"
    fi
fi
MC_PUBLISH_DEPS=""
if [ -n "$GRADLE_DEPS" ] && [ -f "$CONFIG_FILE" ]; then
    while IFS= read -r maven_coord; do
        [ -z "$maven_coord" ] && continue
        ENTRY=$(jq -c -r --arg key "$maven_coord" '.dependencies[$key] // empty' "$CONFIG_FILE")
        [ -z "$ENTRY" ] && continue
        NAME=$(echo "$ENTRY" | jq -r '.name')
        TYPE=$(echo "$ENTRY" | jq -r '.type')
        MODRINTH_ID=$(echo "$ENTRY" | jq -r '.modrinth // empty')
        CF_ID=$(echo "$ENTRY" | jq -r '.curseforge // empty')
        PLATFORM_BLOCK=""
        if [ -n "$MODRINTH_ID" ]; then
            PLATFORM_BLOCK="${PLATFORM_BLOCK}{modrinth:${MODRINTH_ID}}"
        fi
        if [ -n "$CF_ID" ]; then
            PLATFORM_BLOCK="${PLATFORM_BLOCK}{curseforge:${CF_ID}}"
        fi
        MC_PUBLISH_DEPS="${MC_PUBLISH_DEPS}${NAME}@*($TYPE)${PLATFORM_BLOCK}"$'\n'
    done <<< "$GRADLE_DEPS"
fi
{
    echo "mc_publish_deps<<DEPS_EOF"
    echo -e "$MC_PUBLISH_DEPS" | sed '/^$/d'
    echo "DEPS_EOF"
} >> $GITHUB_OUTPUT
