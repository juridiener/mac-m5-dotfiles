#!/usr/bin/env node
// Global Stop-hook reminder (runs on every project, every machine this config
// is synced to). Advisory only, never blocks: warns when code changed this
// session but no plan/progress/decisions/lessons.md changed under a detected
// docs/features/ convention. No-ops silently on any repo that doesn't use
// that convention, so it's safe to run everywhere.
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

// Look for docs/features at the project root, or one level down (e.g. a
// "my_workspace"-style subdir), so this works across differently laid out repos.
function findFeaturesDir(root) {
  const direct = path.join(root, 'docs', 'features');
  if (fs.existsSync(direct)) return direct;
  let entries = [];
  try {
    entries = fs.readdirSync(root, { withFileTypes: true });
  } catch {
    return null;
  }
  for (const e of entries) {
    if (!e.isDirectory() || e.name.startsWith('.') || e.name === 'node_modules') continue;
    const candidate = path.join(root, e.name, 'docs', 'features');
    if (fs.existsSync(candidate)) return candidate;
  }
  return null;
}

const featuresDir = findFeaturesDir(projectDir);
if (!featuresDir) process.exit(0);

let status;
try {
  status = execFileSync('git', ['status', '--porcelain', '--untracked-files=all'], {
    cwd: projectDir,
    encoding: 'utf8',
  });
} catch {
  process.exit(0);
}

const featuresRel = path.relative(projectDir, featuresDir).split(path.sep).join('/');
const lines = status.split('\n').filter(Boolean);
const filePath = (line) => {
  const p = line.slice(3).trim().replace(/^"|"$/g, '');
  const renameSplit = p.indexOf(' -> ');
  return renameSplit === -1 ? p : p.slice(renameSplit + 4); // rename: use the new path
};
const ignoreDirs = ['node_modules/', 'dist/', 'build/', '.next/', '.nx/'];

const codeChanged = lines.some((l) => {
  const p = filePath(l);
  if (p.startsWith(featuresRel + '/')) return false;
  if (p.startsWith('docs/') && !p.startsWith(featuresRel)) return false;
  if (ignoreDirs.some((d) => p.includes('/' + d) || p.startsWith(d))) return false;
  return true;
});

const docsChanged = lines.some((l) => {
  const p = filePath(l);
  return p.startsWith(featuresRel + '/') && /\/(plan|progress|decisions|lessons)\.md$/.test(p);
});

if (codeChanged && !docsChanged) {
  console.log(
    `[feature-docs-gate] "${featuresRel}" convention detected here, but code changed this session ` +
      'with no matching plan/progress/decisions/lessons.md update alongside it. If this was tracked ' +
      'feature work, update the docs before calling it done. If this was untracked/ad-hoc work, ignore this.'
  );
}
