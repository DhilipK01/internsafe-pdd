#!/usr/bin/env node
/**
 * Prints SHA-256 fingerprints for Android App Links (assetlinks.json).
 * Usage: npm run android:sha256
 */
import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { homedir } from 'node:os';
import { join } from 'node:path';

const debugKeystore = join(homedir(), '.android', 'debug.keystore');

function printKeystore(label, keystore, storepass, alias) {
  if (!existsSync(keystore)) {
    console.log(`\n[skip] ${label}: keystore not found at ${keystore}`);
    return;
  }
  console.log(`\n${label} (${keystore}):`);
  try {
    const out = execSync(
      `keytool -list -v -keystore "${keystore}" -alias ${alias} -storepass ${storepass} -keypass ${storepass}`,
      { encoding: 'utf8' },
    );
    const m = out.match(/SHA256:\s*([^\n]+)/i);
    if (m) {
      const fp = m[1].trim().replace(/:/g, '').toLowerCase();
      console.log(`  SHA256: ${fp}`);
      console.log(`  (colon form: ${m[1].trim()})`);
    } else {
      console.log(out);
    }
  } catch (e) {
    console.error(e.message ?? e);
  }
}

console.log('Add comma-separated SHA256 values (no colons) to wrangler.toml ANDROID_SHA256_FINGERPRINTS');
printKeystore('Debug', debugKeystore, 'android', 'androiddebugkey');

const release = process.env.RELEASE_KEYSTORE;
if (release) {
  printKeystore(
    'Release',
    release,
    process.env.RELEASE_STORE_PASS ?? '',
    process.env.RELEASE_KEY_ALIAS ?? 'upload',
  );
} else {
  console.log('\nSet RELEASE_KEYSTORE (+ RELEASE_STORE_PASS, RELEASE_KEY_ALIAS) to print release fingerprint.');
}
