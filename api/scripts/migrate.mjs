#!/usr/bin/env node
/**
 * D1 migration runner for INTERNSAFE.
 * Usage:
 *   node scripts/migrate.mjs --local
 *   node scripts/migrate.mjs --remote
 *   node scripts/migrate.mjs --local --rollback 0002_indexes
 */
import { execSync } from 'node:child_process';
import { setTimeout as sleep } from 'node:timers/promises';
import {
  readdirSync,
  readFileSync,
  existsSync,
  writeFileSync,
  unlinkSync,
} from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const apiRoot = join(__dirname, '..');
const migrationsDir = join(apiRoot, 'migrations');
const rollbackDir = join(migrationsDir, 'rollback');
const dbName = 'internsafe';

const args = process.argv.slice(2);
const isLocal = args.includes('--local');
const isRemote = args.includes('--remote');
const rollbackIdx = args.indexOf('--rollback');
const rollbackVersion = rollbackIdx >= 0 ? args[rollbackIdx + 1] : null;

if (!isLocal && !isRemote) {
  console.error('Specify --local or --remote');
  process.exit(1);
}

const target = isLocal ? '--local' : '--remote';

function wranglerSql(command) {
  const out = execSync(
    `npx wrangler d1 execute ${dbName} ${target} --command=${JSON.stringify(command)} --json`,
    { cwd: apiRoot, encoding: 'utf8', shell: true },
  );
  try {
    const parsed = JSON.parse(out);
    const results = parsed?.[0]?.results;
    if (Array.isArray(results)) return results;
    return [];
  } catch {
    return [];
  }
}

function getAppliedVersions() {
  try {
    const rows = wranglerSql(
      'SELECT version FROM schema_migrations ORDER BY version',
    );
    return new Set(rows.map((r) => r.version));
  } catch {
    return new Set();
  }
}

function versionFromFile(file) {
  return file.replace(/\.sql$/, '');
}

/** Split SQL file into executable statements (skips comments / empty). */
function splitStatements(sql) {
  const statements = [];
  let buf = '';
  for (const line of sql.split('\n')) {
    const trimmed = line.trim();
    if (trimmed.startsWith('--')) continue;
    buf += `${line}\n`;
    if (trimmed.endsWith(';')) {
      const stmt = buf.trim();
      if (stmt && stmt !== ';') statements.push(stmt);
      buf = '';
    }
  }
  const tail = buf.trim();
  if (tail) statements.push(tail);
  return statements;
}

function isIgnorableError(stderr) {
  const s = String(stderr).toLowerCase();
  return (
    s.includes('duplicate column name') ||
    s.includes('already exists') ||
    s.includes('unique constraint failed: schema_migrations.version')
  );
}

async function runStatement(stmt, retries = 4) {
  const tmp = join(apiRoot, '.migrate-tmp.sql');
  writeFileSync(tmp, stmt);
  let lastErr;
  for (let attempt = 1; attempt <= retries; attempt++) {
    try {
      execSync(`npx wrangler d1 execute ${dbName} ${target} --file="${tmp}"`, {
        cwd: apiRoot,
        stdio: 'pipe',
        shell: true,
      });
      if (existsSync(tmp)) unlinkSync(tmp);
      return;
    } catch (e) {
      lastErr = e;
      const out = `${e.stderr?.toString() ?? ''}${e.stdout?.toString() ?? ''}${e.message ?? ''}`;
      if (isIgnorableError(out)) {
        if (existsSync(tmp)) unlinkSync(tmp);
        return 'skipped';
      }
      const transient =
        out.toLowerCase().includes('fetch failed') ||
        out.toLowerCase().includes('network') ||
        out.toLowerCase().includes('timed out');
      if (transient && attempt < retries) {
        const wait = attempt * 2000;
        console.log(`  ⟳ network error, retry ${attempt}/${retries - 1} in ${wait / 1000}s…`);
        await sleep(wait);
        continue;
      }
      if (existsSync(tmp)) unlinkSync(tmp);
      throw e;
    }
  }
  if (existsSync(tmp)) unlinkSync(tmp);
  throw lastErr;
}

async function executeStatements(statements, label) {
  for (let i = 0; i < statements.length; i++) {
    const stmt = statements[i];
    const result = await runStatement(stmt);
    if (result === 'skipped') {
      console.log(`  ↷ skipped (${i + 1}/${statements.length}): already applied`);
    }
  }
}

async function executeFile(filePath, label) {
  const sql = readFileSync(filePath, 'utf8');
  const statements = splitStatements(sql);
  console.log(`\n▶ ${label} (${statements.length} statement(s))`);
  await executeStatements(statements, label);
}

function recordMigration(version) {
  try {
    wranglerSql(
      `INSERT OR IGNORE INTO schema_migrations (version) VALUES ('${version}')`,
    );
  } catch {
    /* table may not exist yet on first bootstrap */
  }
}

async function main() {
  if (rollbackVersion) {
    const downFile = join(rollbackDir, `${rollbackVersion}_down.sql`);
    if (!existsSync(downFile)) {
      console.error(`Rollback file not found: ${downFile}`);
      process.exit(1);
    }
    await executeFile(downFile, `Rolling back ${rollbackVersion} (${target})`);
    console.log('\n✓ Rollback complete');
    return;
  }

  const applied = getAppliedVersions();
  console.log(
    `Applied migrations (${target}): ${
      applied.size ? [...applied].join(', ') : '(none recorded)'
    }`,
  );

  const files = readdirSync(migrationsDir)
    .filter((f) => /^\d{4}_.*\.sql$/.test(f))
    .sort();

  for (const file of files) {
    const version = versionFromFile(file);
    if (applied.has(version)) {
      console.log(`\n○ Skipping ${file} (already in schema_migrations)`);
      continue;
    }
    await executeFile(join(migrationsDir, file), `Applying ${file} (${target})`);
    recordMigration(version);
  }

  console.log('\n✓ Migrations complete');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
