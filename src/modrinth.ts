import * as core from "@actions/core";
import { readFileSync } from "fs";
import path from "path";
import { ReleaserConfig } from "./config";

export interface FileData {
  absolutePath: string;
  name: string;
}

export async function createModrinthVersion(
  projectId: string,
  token: string,
  versionName: string,
  changelog: string,
  files: FileData[],
  loaders: string[],
  config: ReleaserConfig,
) {
  core.info(`Publishing to Modrinth for loaders: ${loaders.join(", ")}`);

  const fileParts = files.map((f) => f.name);

  const dependencies =
    config.modrinth?.relations.map((rel) => ({
      project_id: rel.project_id || rel.slug,
      dependency_type: rel.type,
    })) || [];

  const data = {
    name: versionName,
    version_number: versionName,
    dependencies,
    game_versions: config.game_versions,
    version_type: config.release_type,
    loaders: loaders,
    featured: true,
    project_id: projectId,
    file_parts: fileParts,
    primary_file: fileParts[0],
    changelog,
  };

  const formData = new FormData();
  formData.append("data", JSON.stringify(data));

  for (const file of files) {
    const buffer = readFileSync(file.absolutePath);
    formData.append(file.name, new Blob([buffer]), file.name);
  }

  const response = await fetch("https://api.modrinth.com/v2/version", {
    method: "POST",
    headers: {
      Authorization: token,
    },
    body: formData,
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`Modrinth API returned ${response.status}: ${errorText}`);
  }

  const result = await response.json();
  core.info(`Successfully created Modrinth version: ${result.id}`);
}
