import { arrayBufferToBase64 } from './ai-client';
import type { DatabaseService } from './db/database-service';

export const INLINE_MAX_BYTES = 3 * 1024 * 1024;

export type FileMeta = {
  id: string;
  r2_key: string;
  mime_type: string;
  file_name: string;
  original_name: string;
};

export function isR2ObjectKey(userId: string, r2Key: string): boolean {
  return r2Key.startsWith(`${userId}/`);
}

export async function resolveFileBase64(
  env: { FILES?: R2Bucket },
  db: DatabaseService,
  userId: string,
  fileMeta: FileMeta,
  bodyBase64?: string | null,
): Promise<string | null> {
  if (bodyBase64?.trim()) return bodyBase64.trim();

  if (env.FILES && isR2ObjectKey(userId, fileMeta.r2_key)) {
    const obj = await env.FILES.get(fileMeta.r2_key);
    if (obj) return arrayBufferToBase64(await obj.arrayBuffer());
  }

  return db.getFileContentBase64(userId, fileMeta.id);
}

export async function resolveFileBytes(
  env: { FILES?: R2Bucket },
  db: DatabaseService,
  userId: string,
  fileMeta: FileMeta,
): Promise<{ bytes: ArrayBuffer; mimeType: string } | null> {
  if (env.FILES && isR2ObjectKey(userId, fileMeta.r2_key)) {
    const obj = await env.FILES.get(fileMeta.r2_key);
    if (obj) {
      return {
        bytes: await obj.arrayBuffer(),
        mimeType: fileMeta.mime_type,
      };
    }
  }

  const b64 = await db.getFileContentBase64(userId, fileMeta.id);
  if (!b64) return null;

  const binary = atob(b64);
  const bytes = new Uint8Array(binary.length);
  for (let i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  return { bytes: bytes.buffer, mimeType: fileMeta.mime_type };
}
