/**
 * Format UTC timestamps for display in India Standard Time (Asia/Kolkata).
 */
const IST_TZ = 'Asia/Kolkata';

/** Parse D1/SQLite datetime as UTC. */
export function parseUtc(iso: string | null | undefined): Date | null {
  if (!iso?.trim()) return null;
  let raw = iso.trim();
  if (!raw.includes('T')) raw = raw.replace(' ', 'T');
  if (!raw.endsWith('Z') && !raw.includes('+')) raw += 'Z';
  const d = new Date(raw);
  return Number.isNaN(d.getTime()) ? null : d;
}

/** Example: 16 May 2026, 07:45 PM IST */
export function formatIST(iso: string | null | undefined): string {
  const d = parseUtc(iso);
  if (!d) return '';
  const parts = new Intl.DateTimeFormat('en-IN', {
    timeZone: IST_TZ,
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: true,
  }).formatToParts(d);
  const get = (type: Intl.DateTimeFormatPartTypes) =>
    parts.find((p) => p.type === type)?.value ?? '';
  return `${get('day')} ${get('month')} ${get('year')}, ${get('hour')}:${get('minute')} ${get('dayPeriod').toUpperCase()} IST`;
}

export function withIST<T extends { created_at?: string | null }>(
  row: T,
): T & { created_at_ist: string; timezone: string } {
  return {
    ...row,
    created_at_ist: formatIST(row.created_at ?? null),
    timezone: IST_TZ,
  };
}

export function mapRowsWithIST<T extends { created_at?: string | null }>(
  rows: T[],
): (T & { created_at_ist: string; timezone: string })[] {
  return rows.map((r) => withIST(r));
}
