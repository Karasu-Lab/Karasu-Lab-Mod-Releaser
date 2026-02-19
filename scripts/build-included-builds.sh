#!/bin/bash
TARGET_DIR="${1:-.}"
SETTINGS_FILE="$TARGET_DIR/settings.gradle"

if [ -f "$SETTINGS_FILE" ]; then
    echo "Checking for included builds in $SETTINGS_FILE..."
    # Extract paths from includeBuild("path") or includeBuild 'path'
    # Use grep -oP to extract the path string
    grep -oP "includeBuild\s*[\(\"']+\K[^\"'\)]+" "$SETTINGS_FILE" | while read -r build_path; do
        # construct full path
        FULL_PATH="$TARGET_DIR/$build_path"
        
        if [ -d "$FULL_PATH" ]; then
            echo "Found included build at: $build_path"
            echo "Executing build for included project..."
            
            # Run build in subshell or pushd
            (
                cd "$FULL_PATH" || exit 1
                if [ -f "gradlew" ]; then
                    chmod +x gradlew
                    ./gradlew build
                else
                    echo "Warning: No gradlew found in $FULL_PATH, skipping build."
                fi
            )
        else
            echo "Warning: Included build path '$FULL_PATH' not found."
        fi
    done
else
    echo "No settings.gradle found in $TARGET_DIR"
fi
