# KarasuLab Mod Releaser

GitHub Action to automate the release process for Minecraft mods.  
This action handles semantic versioning, changelog generation, building, and publishing to GitHub Releases, Modrinth, and CurseForge.

## Features

- **Automated releases**: Uses [Release Please](https://github.com/googleapis/release-please-action) to manage versions and changelogs.
- **Multi-platform publishing**: Publishes to [Modrinth](https://modrinth.com/) and [CurseForge](https://www.curseforge.com/) using [mc-publish](https://github.com/Kir-Antipov/mc-publish).
- **Dynamic configuration**: Automatically detects Java version and loaders from a config file.
- **Dependency management**: Resolves mod dependencies defined in `build.gradle` and configures them for publishing.

## Usage

Create a workflow file (e.g., `.github/workflows/release.yml`) in your repository:

```yaml
name: Release

on:
  push:
    branches:
      - main

permissions:
  contents: write
  pull-requests: write

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - name: KarasuLab Mod Releaser
        uses: Karasu-Lab/Karasu-Lab-Mod-Releaser@v1
        with:
          modrinth_project_id: ${{ vars.MODRINTH_PROJECT_ID }}
          modrinth_token: ${{ secrets.MODRINTH_TOKEN }}
          curseforge_project_id: ${{ vars.CURSEFORGE_PROJECT_ID }}
          curseforge_token: ${{ secrets.CURSEFORGE_TOKEN }}
```

## Inputs

| Input                     | Description                              | Required | Default                              |
| :------------------------ | :--------------------------------------- | :------: | :----------------------------------- |
| `modrinth_project_id`     | Project ID for Modrinth.                 | **Yes**  | -                                    |
| `modrinth_token`          | API Token for Modrinth.                  | **Yes**  | -                                    |
| `curseforge_project_id`   | Project ID for CurseForge.               | **Yes**  | -                                    |
| `curseforge_token`        | API Token for CurseForge.                | **Yes**  | -                                    |
| `config_path`             | Path to the mod releaser config file.    |    No    | `karasulab-mod-releaser-config.json` |
| `release_please_config`   | Path to `release-please-config.json`.    |    No    | `release-please-config.json`         |
| `release_please_manifest` | Path to `.release-please-manifest.json`. |    No    | `.release-please-manifest.json`      |
| `working_directory`       | Working directory for the mod project.   |    No    | `.`                                  |

## Configuration

### 1. `gradle.properties`

Your `gradle.properties` must contain the following keys, which are used to name the artifacts:

- `archives_base_name`
- `minecraft_version`
- `mod_version`

### 2. `karasulab-mod-releaser-config.json`

This file configures project-specific settings like Java version, dependencies, and file naming.

| Field                  | Description                                        | Default                                                      |
| :--------------------- | :------------------------------------------------- | :----------------------------------------------------------- |
| `java`                 | Java version to use.                               | `21`                                                         |
| `loaders`              | List of mod loaders (e.g., `["fabric", "forge"]`). | `["fabric"]`                                                 |
| `dependencies`         | Mod dependencies map.                              | `{}`                                                         |
| `release_title_format` | Format for the release title on platforms.         | `{archives_base_name}-{mod_version}-{minecraft_version}`     |
| `jar_name_format`      | Format for the JAR filename to be uploaded.        | `{archives_base_name}-{mod_version}-{minecraft_version}.jar` |

#### Supported Placeholders

You can use the following placeholders in `release_title_format` and `jar_name_format`:

- `{archives_base_name}`: Extracted from `gradle.properties`.
- `{mod_version}`: Extracted from `gradle.properties`.
- `{minecraft_version}`: Extracted from `gradle.properties`.
- `{version}`: The Git release tag (e.g., `v1.0.0`).

#### Example

```json
{
  "java": 21,
  "loaders": ["fabric"],
  "release_title_format": "{archives_base_name} {mod_version} for MC {minecraft_version}",
  "jar_name_format": "{archives_base_name}-{mod_version}.jar",
  "dependencies": {
    "fabric-api": {
      "name": "fabric-api",
      "type": "required",
      "modrinth": "P7dR8mSH",
      "curseforge": "306616"
    }
  }
}
```
