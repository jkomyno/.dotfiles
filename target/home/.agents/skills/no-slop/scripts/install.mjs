#!/usr/bin/env node
import { cpSync, existsSync, mkdirSync } from "node:fs";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const skillRoot = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const sources = ["anti-slop", "no-slop"];
const arguments_ = process.argv.slice(2);
const targetArgument = arguments_.find((argument) => !argument.startsWith("--"));
const targetRoot = resolve(process.cwd(), targetArgument ?? "tools/oxlint");
const force = arguments_.includes("--force");

for (const name of sources) {
  const target = resolve(targetRoot, name);
  if (existsSync(target) && !force) {
    console.error(
      `Refusing to overwrite ${target}. Re-run with --force only after reviewing the existing files.`,
    );
    process.exit(1);
  }
}

mkdirSync(targetRoot, { recursive: true });
for (const name of sources) {
  const source = resolve(skillRoot, `assets/${name}`);
  const target = resolve(targetRoot, name);
  mkdirSync(dirname(target), { recursive: true });
  cpSync(source, target, { recursive: true, force });
  console.log(`Copied the ${name} plugin to ${target}`);
}
console.log(`Configure Oxlint with plugins under ${targetRoot}`);
