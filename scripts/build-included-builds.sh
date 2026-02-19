#!/bin/bash
TARGET_DIR="${1:-.}"
SETTINGS_FILE="$TARGET_DIR/settings.gradle"

if [ -f "$SETTINGS_FILE" ]; then
    echo "Checking for included builds in $SETTINGS_FILE..."
    grep -oP "includeBuild\s*[\(\"']+\K[^\"'\)]+" "$SETTINGS_FILE" | while read -r build_path; do
        FULL_PATH="$TARGET_DIR/$build_path"
        if [ -d "$FULL_PATH" ]; then
             echo "Found included build at: $build_path"
             (
                cd "$FULL_PATH" || exit 1
                if [ -f "gradlew" ]; then
                    chmod +x gradlew
                    ./gradlew build
                fi
             )
        fi
    done
    
    grep -oP "\.projectDir\s*=\s*file\s*[\(\"']+\K[^\"'\)]+" "$SETTINGS_FILE" | while read -r build_path; do
         FULL_PATH="$TARGET_DIR/$build_path"
         if [ -d "$FULL_PATH" ]; then
             echo "Found defined submodule path at: $build_path"
             if [ -f "$FULL_PATH/gradlew" ] || [ -f "$FULL_PATH/build.gradle" ]; then
                 echo "Executing pre-build for submodule project..."
                 (
                    cd "$FULL_PATH" || exit 1
                     if [ -f "gradlew" ]; then
                        chmod +x gradlew
                        ./gradlew build
                     else
                        echo "Warning: Submodule at $FULL_PATH does not have gradlew. Skipping pre-build."
                     fi
    done
else
    echo "No settings.gradle found in $TARGET_DIR"
fi
