import type { DatabaseService } from './db/database-service';
import {
  buildShareSnapshot,
  buildSharedBy,
  type ShareResourceType,
} from './share';
import { formatIST } from './utils/ist';

export type LibraryKind =
  | 'activity'
  | 'history'
  | 'upload'
  | 'scan'
  | 'offer'
  | 'offer_check'
  | 'analysis'
  | 'data_safety'
  | 'company'
  | 'blacklist';

function normalizeKind(kind: string): LibraryKind {
  const k = kind.toLowerCase();
  if (k === 'history') return 'activity';
  if (k === 'offer') return 'offer_check';
  return k as LibraryKind;
}

function activityToResourceType(
  actionType: string,
  targetType?: string | null,
): ShareResourceType | null {
  const t = (actionType || '').toLowerCase();
  if (t === 'resume' || t === 'scan' || targetType === 'scan') return 'scan';
  if (t === 'offer' || targetType === 'offer_check') return 'offer_check';
  if (t === 'company' || targetType === 'company') return 'company_verify';
  if (t === 'blacklist') return 'blacklist';
  if (t === 'data_safety') return 'data_safety';
  if (t === 'upload' || targetType === 'upload' || targetType === 'file') {
    return 'upload';
  }
  return null;
}

async function mergeDbFindings(
  db: DatabaseService,
  userId: string,
  scanId: string,
  snapshot: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const rows = await db.getScanFindingsForScan(userId, scanId);
  if (!rows.length) return snapshot;
  const existing = (snapshot.findings as unknown[]) ?? [];
  if (existing.length > 0) return snapshot;
  const findings = rows.map((r) => {
    const row = r as Record<string, unknown>;
    return {
      type: row.finding_type,
      message: row.finding_value,
      severity: row.risk_level,
      recommendation: row.recommendation,
      page: row.page_number,
    };
  });
  return {
    ...snapshot,
    findings,
    findingCount: findings.length,
  };
}

async function buildSnapshotForResource(
  db: DatabaseService,
  userId: string,
  resourceType: ShareResourceType,
  resourceId: string,
  extras?: { companyName?: string; query?: string },
): Promise<Record<string, unknown>> {
  return buildShareSnapshot(db, userId, resourceType, resourceId, {
    confirmSensitive: true,
    ...extras,
  });
}

export async function buildLibraryDetail(
  db: DatabaseService,
  userId: string,
  rawKind: string,
  id: string,
): Promise<Record<string, unknown>> {
  const kind = normalizeKind(rawKind);
  const owner = await buildSharedBy(db, userId);

  if (kind === 'analysis') {
    const resolved = await resolveAnalysisTarget(db, userId, id);
    if (!resolved) throw new Error('NOT_FOUND');
    return buildLibraryDetail(db, userId, resolved.kind, resolved.id);
  }

  if (kind === 'activity' || kind === 'history') {
    const act = await db.getActivityLog(userId, id);
    if (!act) throw new Error('NOT_FOUND');
    const row = act as Record<string, unknown>;
    const resourceType = activityToResourceType(
      (row.action_type ?? row.activity_type) as string,
      row.target_type as string | null,
    );
    const targetId = (row.target_id as string) ?? id;
    let snapshot: Record<string, unknown>;
    if (resourceType === 'company_verify') {
      const name =
        (row.subtitle as string)?.trim() || (row.title as string)?.trim();
      snapshot = await buildSnapshotForResource(
        db,
        userId,
        resourceType,
        targetId,
        { companyName: name },
      );
    } else if (resourceType === 'blacklist') {
      const q =
        (row.subtitle as string)?.trim() || (row.title as string)?.trim();
      snapshot = await buildSnapshotForResource(db, userId, resourceType, targetId, {
        query: q,
      });
    } else if (resourceType && targetId) {
      snapshot = await buildSnapshotForResource(
        db,
        userId,
        resourceType,
        targetId,
      );
      if (resourceType === 'scan') {
        const scanRow = await db.getScanForShare(userId, targetId);
        const scanId = (scanRow as { id?: string } | null)?.id ?? targetId;
        snapshot = await mergeDbFindings(db, userId, scanId, snapshot);
      }
    } else {
      snapshot = {
        type: 'activity',
        title: row.title as string,
        subtitle: row.subtitle as string,
        message: row.result_label as string,
      };
    }
    return wrapDetail(snapshot, row, owner, {
      activityId: id,
      resourceType,
      resourceId: targetId,
    });
  }

  if (kind === 'upload') {
    const meta = await db.getUserFileMeta(userId, id);
    if (!meta) throw new Error('NOT_FOUND');
    const snapshot = await buildSnapshotForResource(db, userId, 'upload', id);
    return wrapDetail(
      snapshot,
      {
        created_at: meta.created_at,
        updated_at: meta.updated_at,
        file_name: meta.file_name,
        mime_type: meta.mime_type,
        upload_type: meta.upload_type,
      },
      owner,
      { resourceType: 'upload', resourceId: id },
    );
  }

  if (kind === 'scan') {
    const scan = await db.getScanForShare(userId, id);
    if (!scan) throw new Error('NOT_FOUND');
    let snapshot = await buildSnapshotForResource(db, userId, 'scan', id);
    const scanId = (scan as { id: string }).id;
    snapshot = await mergeDbFindings(db, userId, scanId, snapshot);
    return wrapDetail(snapshot, scan as Record<string, unknown>, owner, {
      resourceType: 'scan',
      resourceId: scanId,
    });
  }

  if (kind === 'offer' || kind === 'offer_check') {
    const row = await db.getOfferCheck(userId, id);
    if (!row) throw new Error('NOT_FOUND');
    const snapshot = await buildSnapshotForResource(db, userId, 'offer_check', id);
    return wrapDetail(snapshot, row as Record<string, unknown>, owner, {
      resourceType: 'offer_check',
      resourceId: id,
    });
  }

  if (kind === 'data_safety') {
    const row = await db.getDataSafetyCheck(userId, id);
    if (!row) throw new Error('NOT_FOUND');
    const snapshot = await buildSnapshotForResource(
      db,
      userId,
      'data_safety',
      id,
    );
    return wrapDetail(snapshot, row as Record<string, unknown>, owner, {
      resourceType: 'data_safety',
      resourceId: id,
    });
  }

  if (kind === 'company') {
    const snapshot = await buildSnapshotForResource(
      db,
      userId,
      'company_verify',
      id,
      { companyName: id },
    );
    return wrapDetail(snapshot, { company_name: id }, owner, {
      resourceType: 'company_verify',
      resourceId: id,
    });
  }

  if (kind === 'blacklist') {
    const snapshot = await buildSnapshotForResource(db, userId, 'blacklist', id, {
      query: id,
    });
    return wrapDetail(snapshot, { query: id }, owner, {
      resourceType: 'blacklist',
      resourceId: id,
    });
  }

  throw new Error('INVALID_KIND');
}

async function resolveAnalysisTarget(
  db: DatabaseService,
  userId: string,
  id: string,
): Promise<{ kind: string; id: string } | null> {
  const act = await db.getActivityLog(userId, id);
  if (act) return { kind: 'activity', id };
  if (await db.getScanForShare(userId, id)) return { kind: 'scan', id };
  if (await db.getOfferCheck(userId, id)) return { kind: 'offer_check', id };
  if (await db.getUserFileMeta(userId, id)) return { kind: 'upload', id };
  if (await db.getDataSafetyCheck(userId, id)) {
    return { kind: 'data_safety', id };
  }
  return null;
}

function wrapDetail(
  snapshot: Record<string, unknown>,
  row: Record<string, unknown>,
  owner: Record<string, unknown>,
  links: {
    activityId?: string;
    resourceType?: ShareResourceType | null;
    resourceId?: string;
  },
): Record<string, unknown> {
  const createdAt = (row.created_at as string) ?? null;
  const updatedAt =
    (row.updated_at as string) ??
    (row.completed_at as string) ??
    createdAt;
  const doc = snapshot.document as Record<string, unknown> | undefined;
  return {
    snapshot,
    owner,
    meta: {
      activityId: links.activityId ?? null,
      resourceType: links.resourceType ?? snapshot.type ?? null,
      resourceId: links.resourceId ?? null,
      reportType: snapshot.type ?? links.resourceType,
      status: snapshot.status ?? row.status ?? row.scan_status ?? null,
      riskLevel: snapshot.riskLevel ?? row.risk_level ?? null,
      fileType: doc?.mimeType ?? row.mime_type ?? null,
      fileName: doc?.fileName ?? row.file_name ?? null,
      createdAt,
      createdAtIst: createdAt ? formatIST(createdAt) : null,
      analyzedAt: updatedAt,
      analyzedAtIst: updatedAt ? formatIST(updatedAt) : null,
      hasAnalysis:
        snapshot.status === 'completed' ||
        (snapshot.findings as unknown[])?.length > 0 ||
        snapshot.summary != null,
      hasDocument: doc?.hasPreview === true || doc?.fileId != null,
    },
  };
}
