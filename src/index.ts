import * as core from "@actions/core";
import * as glob from "@actions/glob";
import path from "path";
import { getInputs, loadConfig } from "./config";
import { createModrinthVersion, FileData } from "./modrinth";
import { createCurseForgeVersion } from "./curseforge";

async function resolveFiles(pattern: string, workspaceDir: string): Promise<FileData[]> {
  const globber = await glob.create(path.resolve(workspaceDir, pattern));
  const files = await globber.glob();
  return files.map((f) => ({
    absolutePath: f,
    name: path.basename(f),
  }));
}

import { z } from "zod";

const SupportedLoadersSchema = z.enum(["fabric", "forge", "neoforge", "quilt"]);

function filterFilesForLoader(files: FileData[], loader: string): FileData[] {
  const lowerLoader = loader.toLowerCase();

  const mappedFiles = files.map((f) => {
    const nameLower = f.name.toLowerCase();
    const hasFabric = nameLower.includes(SupportedLoadersSchema.enum.fabric);
    const hasQuilt = nameLower.includes(SupportedLoadersSchema.enum.quilt);
    const hasNeoForge = nameLower.includes(SupportedLoadersSchema.enum.neoforge);
    const hasForge =
      nameLower.includes(SupportedLoadersSchema.enum.forge) &&
      (!nameLower.includes(SupportedLoadersSchema.enum.neoforge) ||
        nameLower
          .replace(SupportedLoadersSchema.enum.neoforge, "")
          .includes(SupportedLoadersSchema.enum.forge));

    return {
      file: f,
      hasFabric,
      hasQuilt,
      hasNeoForge,
      hasForge,
      hasAnyLoader: hasFabric || hasQuilt || hasNeoForge || hasForge,
    };
  });

  const matches = mappedFiles.filter((m) => {
    switch (lowerLoader) {
      case SupportedLoadersSchema.enum.fabric:
        return m.hasFabric;
      case SupportedLoadersSchema.enum.forge:
        return m.hasForge;
      case SupportedLoadersSchema.enum.neoforge:
        return m.hasNeoForge;
      case SupportedLoadersSchema.enum.quilt:
        return m.hasQuilt;
      default:
        return m.file.name.toLowerCase().includes(lowerLoader);
    }
  });

  if (matches.length > 0) {
    return matches.map((m) => m.file);
  }

  const universalFiles = mappedFiles.filter((m) => !m.hasAnyLoader);
  if (universalFiles.length > 0) {
    return universalFiles.map((m) => m.file);
  }

  return [];
}

async function run() {
  try {
    const inputs = getInputs();
    const config = loadConfig(inputs.workingDirectory, inputs.configPath);

    const allFiles = await resolveFiles(inputs.files, inputs.workingDirectory);
    if (allFiles.length === 0) {
      core.setFailed(`No files found matching pattern: ${inputs.files}`);
      return;
    }

    const modrinthPromises: Promise<void>[] = [];
    const curseforgePromises: Promise<void>[] = [];

    if (inputs.modrinthToken && config.modrinth) {
      for (const loader of config.loaders) {
        const loaderFiles = filterFilesForLoader(allFiles, loader);
        const nameAndLoader = `${inputs.versionName}+${loader.toLowerCase()}`;

        modrinthPromises.push(
          createModrinthVersion(
            config.modrinth.project_id,
            inputs.modrinthToken,
            nameAndLoader,
            inputs.changelog,
            loaderFiles,
            [loader],
            config,
          ),
        );
      }
    }

    if (inputs.curseforgeToken && config.curseforge) {
      for (const loader of config.loaders) {
        const loaderFiles = filterFilesForLoader(allFiles, loader);
        const nameAndLoader = `${inputs.versionName}+${loader.toLowerCase()}`;

        for (const file of loaderFiles) {
          curseforgePromises.push(
            createCurseForgeVersion(
              config.curseforge.project_id,
              inputs.curseforgeToken,
              nameAndLoader,
              inputs.changelog,
              file,
              [loader],
              config,
            ),
          );
        }
      }
    }

    await Promise.allSettled([...modrinthPromises, ...curseforgePromises]).then((results) => {
      const failures = results.filter((r) => r.status === "rejected");
      if (failures.length > 0) {
        for (const fail of failures) {
          if (fail.status === "rejected") {
            core.error(fail.reason);
          }
        }
        core.setFailed("One or more publish tasks failed");
      }
    });
  } catch (error: any) {
    core.setFailed(error.message);
  }
}

run();
