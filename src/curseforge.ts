import * as core from "@actions/core";
import { readFileSync } from "fs";
import { ReleaserConfig } from "./config";

export interface FileData {
  absolutePath: string;
  name: string;
}

async function getGameVersionIds(token: string, versionsAndLoaders: string[]): Promise<number[]> {
  const response = await fetch("https://minecraft.curseforge.com/api/game/versions", {
    headers: { "X-Api-Token": token },
  });
  if (!response.ok) {
    throw new Error(`Failed to fetch CurseForge game versions: ${response.statusText}`);
  }

  const data: any[] = await response.json();
  const ids: number[] = [];

  for (const name of versionsAndLoaders) {
    const lowerName = name.toLowerCase();
    const match = data.find(
      (item) => item.name.toLowerCase() === lowerName || item.slug.toLowerCase() === lowerName,
    );
    if (match) {
      ids.push(match.id);
    } else {
      core.warning(`Could not find CurseForge game version ID for '${name}'. It will be ignored.`);
    }
  }
  return ids;
}

function mapDependencyType(type: string): string {
  switch (type) {
    case "required":
      return "requiredDependency";
    case "optional":
      return "optionalDependency";
    case "incompatible":
      return "incompatible";
    case "embedded":
      return "embeddedLibrary";
    default:
      return "requiredDependency";
  }
}

export async function createCurseForgeVersion(
  projectId: string,
  token: string,
  versionName: string,
  changelog: string,
  file: FileData,
  loaders: string[],
  config: ReleaserConfig,
) {
  core.info(`Publishing ${file.name} to CurseForge for loaders: ${loaders.join(", ")}`);

  const combinedVersions = [...config.game_versions, ...loaders];
  const gameVersionIds = await getGameVersionIds(token, combinedVersions);

  const projects =
    config.curseforge?.relations.map((rel) => {
      const relation: any = { type: mapDependencyType(rel.type) };
      if (rel.slug) relation.slug = rel.slug;
      return relation;
    }) || [];

  const metadata = {
    changelog,
    changelogType: "markdown",
    displayName: versionName,
    gameVersions: gameVersionIds,
    releaseType: config.release_type,
    relations: projects.length > 0 ? { projects } : undefined,
  };

  const formData = new FormData();
  formData.append("metadata", JSON.stringify(metadata));

  const buffer = readFileSync(file.absolutePath);
  formData.append("file", new Blob([buffer]), file.name);

  const response = await fetch(
    `https://minecraft.curseforge.com/api/projects/${projectId}/upload-file`,
    {
      method: "POST",
      headers: {
        "X-Api-Token": token,
      },
      body: formData,
    },
  );

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`CurseForge API returned ${response.status}: ${errorText}`);
  }

  const result = await response.json();
  core.info(`Successfully uploaded to CurseForge. File ID: ${result.id}`);
}
