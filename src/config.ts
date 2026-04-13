import * as core from "@actions/core";
import { z } from "zod";
import { readFileSync, existsSync } from "fs";
import path from "path";

export const RelationSchema = z
  .object({
    slug: z.string().optional(),
    project_id: z.string().optional(),
    type: z.enum(["required", "optional", "incompatible", "embedded"]),
  })
  .refine((data) => data.slug || data.project_id, {
    message: "Either slug or project_id must be provided for a relation",
  });

export const PlatformConfigSchema = z.object({
  project_id: z.string(),
  relations: z.array(RelationSchema).optional().default([]),
});

export const ReleaserConfigSchema = z.object({
  loaders: z.array(z.string()).default(["fabric"]),
  game_versions: z.array(z.string()).default([]),
  environment: z
    .object({
      client: z.enum(["required", "optional", "unsupported"]).default("required"),
      server: z.enum(["required", "optional", "unsupported"]).default("required"),
    })
    .optional(),
  modrinth: PlatformConfigSchema.optional(),
  curseforge: PlatformConfigSchema.optional(),
  release_type: z.enum(["release", "beta", "alpha"]).default("release"),
});

export type ReleaserConfig = z.infer<typeof ReleaserConfigSchema>;

export function loadConfig(workspaceDir: string, configPath: string): ReleaserConfig {
  const fullPath = path.resolve(workspaceDir, configPath);
  if (!existsSync(fullPath)) {
    core.warning(`Config file not found at ${fullPath}. Using default configuration.`);
    return ReleaserConfigSchema.parse({});
  }

  try {
    const fileContent = readFileSync(fullPath, "utf8");
    const json = JSON.parse(fileContent);
    return ReleaserConfigSchema.parse(json);
  } catch (error) {
    if (error instanceof z.ZodError) {
      core.error(`Configuration validation failed: ${JSON.stringify(error.format(), null, 2)}`);
      throw new Error("Invalid configuration file");
    }
    throw error;
  }
}

export interface ActionInputs {
  modrinthToken: string;
  curseforgeToken: string;
  configPath: string;
  workingDirectory: string;
  files: string;
  versionName: string;
  changelog: string;
}

export function getInputs(): ActionInputs {
  return {
    modrinthToken: core.getInput("modrinth_token"),
    curseforgeToken: core.getInput("curseforge_token"),
    configPath: core.getInput("config_path") || "karasulab-mod-releaser-config.json",
    workingDirectory: core.getInput("working_directory") || ".",
    files: core.getInput("files", { required: true }),
    versionName: core.getInput("version_name", { required: true }),
    changelog: core.getInput("changelog") || "",
  };
}
