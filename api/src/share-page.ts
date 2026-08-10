import type { ShareEnv } from './share';

function shareUrl(host: string, token: string): string {
  return `https://${host}/share/${token}`;
}

function appDeepLink(token: string): string {
  return `internsafe://share/${token}`;
}

function legacyAppDeepLink(token: string): string {
  return `internsafe://s/${token}`;
}
import { internsafeLogoImg } from './share-brand';

function esc(s: string): string {
  return s
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function scoreColor(score: number): string {
  if (score >= 70) return '#4ade80';
  if (score >= 40) return '#fbbf24';
  return '#f87171';
}

function gaugeSvg(score: number, label: string): string {
  const pct = Math.max(0, Math.min(100, score));
  const color = scoreColor(pct);
  const dash = (pct / 100) * 251;
  return `<div class="gauge" aria-label="${esc(label)} ${pct}">
  <svg viewBox="0 0 120 70" width="140" height="80">
    <path d="M10 60 A50 50 0 0 1 110 60" fill="none" stroke="rgba(255,255,255,.08)" stroke-width="10" stroke-linecap="round"/>
    <path d="M10 60 A50 50 0 0 1 110 60" fill="none" stroke="${color}" stroke-width="10" stroke-linecap="round"
      stroke-dasharray="${dash} 251" style="filter:drop-shadow(0 0 8px ${color}55)"/>
  </svg>
  <div class="gauge-val" style="color:${color}">${pct}</div>
  <div class="gauge-lbl">${esc(label)}</div>
</div>`;
}

function riskChip(risk: string): string {
  const r = (risk || 'unknown').toLowerCase();
  const cls =
    r.includes('high') || r.includes('danger') || r.includes('critical')
      ? 'chip-danger'
      : r.includes('med') || r.includes('warn')
        ? 'chip-warn'
        : r.includes('low') || r.includes('safe')
          ? 'chip-safe'
          : 'chip-neutral';
  return `<span class="chip ${cls}">${esc(risk)}</span>`;
}

function section(title: string, body: string, id?: string): string {
  if (!body.trim()) return '';
  const sid = id ? ` id="${esc(id)}"` : '';
  return `<section class="panel"${sid}>
    <button type="button" class="panel-head" aria-expanded="true" data-toggle>
      <h2>${esc(title)}</h2>
      <span class="chev" aria-hidden="true">▾</span>
    </button>
    <div class="panel-body">${body}</div>
  </section>`;
}

function buildSharedBy(snapshot: Record<string, unknown>): string {
  const by = snapshot.sharedBy as Record<string, unknown> | undefined;
  if (!by) return '';
  const name = String(by.name ?? 'INTERNSAFE user');
  const email = by.emailMasked ? String(by.emailMasked) : '';
  const initials = String(by.initials ?? 'IN');
  const verified = by.verified === true;
  const when = snapshot.sharedAtIst
    ? String(snapshot.sharedAtIst)
    : snapshot.sharedAt
      ? String(snapshot.sharedAt)
      : '';
  return `<div class="shared-by glass">
    <div class="avatar" aria-hidden="true">${esc(initials)}</div>
    <div class="shared-meta">
      <p class="lbl">Shared by</p>
      <p class="name">${esc(name)}</p>
      ${email ? `<p class="email">${esc(email)}</p>` : ''}
      ${verified ? '<p class="badge-verified">✓ Verified INTERNSAFE member</p>' : ''}
      ${when ? `<p class="when">Shared on ${esc(when)}</p>` : ''}
    </div>
  </div>`;
}

function buildDocument(
  snapshot: Record<string, unknown>,
  docUrl: string | undefined,
): string {
  const doc = snapshot.document as Record<string, unknown> | undefined;
  if (!doc && !snapshot.fileName) return '';
  const name = String(doc?.fileName ?? snapshot.fileName ?? 'Document');
  const mime = String(doc?.mimeType ?? snapshot.mimeType ?? '');
  const size = doc?.fileSize != null ? formatBytes(Number(doc.fileSize)) : '';
  const uploaded = doc?.uploadedAt ? formatWhen(String(doc.uploadedAt)) : '';
  const hasPreview = doc?.hasPreview === true && docUrl;
  let preview = '';
  if (hasPreview && mime.startsWith('image/')) {
    preview = `<img class="doc-preview" src="${esc(docUrl!)}" alt="${esc(name)}"/>`;
  } else if (hasPreview && mime === 'application/pdf') {
    preview = `<iframe class="doc-preview pdf" src="${esc(docUrl!)}" title="${esc(name)}"></iframe>`;
  } else {
    preview = `<div class="doc-placeholder">
      <span class="doc-icon">📄</span>
      <p>Preview available in app or after opening document endpoint.</p>
    </div>`;
  }
  return section(
    'Document preview',
    `<div class="doc-card glass">
      <div class="doc-meta">
        <strong>${esc(name)}</strong>
        <span>${esc(mime || 'file')}${size ? ` · ${esc(size)}` : ''}</span>
        ${uploaded ? `<span>Uploaded ${esc(uploaded)}</span>` : ''}
      </div>
      ${preview}
    </div>`,
    'document',
  );
}

function formatBytes(n: number): string {
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(1)} MB`;
}

function formatWhen(iso: string): string {
  try {
    return new Date(iso).toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });
  } catch {
    return iso;
  }
}

function buildFindingsList(findings: unknown[]): string {
  if (!Array.isArray(findings) || findings.length === 0) return '';
  const items = findings
    .map((f) => {
      const row = f as Record<string, unknown>;
      const type = String(row.type ?? row.finding_type ?? 'Finding');
      const risk = String(row.risk ?? row.risk_level ?? 'unknown');
      const conf =
        row.confidence != null ? ` · ${Math.round(Number(row.confidence) * (Number(row.confidence) <= 1 ? 100 : 1))}% confidence` : '';
      const val = row.value ? `<p class="finding-val">${esc(String(row.value))}</p>` : '';
      const rec = row.recommendation
        ? `<p class="finding-rec">${esc(String(row.recommendation))}</p>`
        : '';
      return `<article class="finding glass">
        <header>${riskChip(risk)} <strong>${esc(type)}</strong>${esc(conf)}</header>
        ${val}${rec}
      </article>`;
    })
    .join('');
  return section('Detected risks & findings', `<div class="findings">${items}</div>`, 'findings');
}

function buildScanAnalysis(snapshot: Record<string, unknown>): string {
  const gauges: string[] = [];
  if (snapshot.safetyScore != null) {
    gauges.push(gaugeSvg(Number(snapshot.safetyScore), 'Safety score'));
  }
  if (snapshot.dangerScore != null) {
    gauges.push(gaugeSvg(Number(snapshot.dangerScore), 'Danger score'));
  }
  const verdict = snapshot.verdict
    ? `<p class="verdict">${esc(String(snapshot.verdict))}</p>`
    : '';
  const ai = snapshot.aiRecommendation as Record<string, unknown> | undefined;
  const aiBlock = ai?.explanation
    ? `<div class="ai-box glass"><p class="ai-lbl">AI recommendation</p><p>${esc(String(ai.explanation))}</p></div>`
    : '';
  const findings = buildFindingsList((snapshot.findings as unknown[]) ?? []);
  const recs = (snapshot.recommendations as unknown[]) ?? [];
  const recHtml =
    recs.length > 0
      ? section(
          'Recommendations',
          `<ul class="rec-list">${recs
            .map((r) => `<li>${esc(typeof r === 'string' ? r : JSON.stringify(r))}</li>`)
            .join('')}</ul>`,
        )
      : '';
  return `${section(
    'AI analysis',
    `<div class="gauge-row">${gauges.join('')}</div>
     ${snapshot.riskLevel ? `<p>Risk level: ${riskChip(String(snapshot.riskLevel))}</p>` : ''}
     ${verdict}${aiBlock}`,
    'analysis',
  )}${findings}${recHtml}`;
}

function buildOfferAnalysis(snapshot: Record<string, unknown>): string {
  const analysis = (snapshot.analysis as Record<string, unknown>) ?? snapshot;
  const gauges: string[] = [];
  const fraud = analysis.fraudScore ?? analysis.scamProbability ?? snapshot.fraudScore;
  if (fraud != null) gauges.push(gaugeSvg(Number(fraud), 'Scam probability'));
  const reasons = (analysis.reasons as unknown[]) ?? [];
  const reasonHtml =
    reasons.length > 0
      ? `<ul class="reason-list">${reasons
          .map((r) => {
            const item = r as Record<string, unknown>;
            const msg = String(item.message ?? item.description ?? r);
            const sev = item.severity ? riskChip(String(item.severity)) : '';
            return `<li>${sev} ${esc(msg)}</li>`;
          })
          .join('')}</ul>`
      : '';
  const summary = snapshot.summary ?? snapshot.message ?? analysis.recommendation;
  return section(
    'Offer fraud analysis',
    `<div class="gauge-row">${gauges.join('')}</div>
     ${summary ? `<p class="summary">${esc(String(summary))}</p>` : ''}
     ${reasonHtml}`,
    'analysis',
  );
}

function buildCompanyAnalysis(snapshot: Record<string, unknown>): string {
  const gauges: string[] = [];
  if (snapshot.trustScore != null) {
    gauges.push(gaugeSvg(Number(snapshot.trustScore), 'Trust score'));
  }
  if (snapshot.dangerScore != null) {
    gauges.push(gaugeSvg(Number(snapshot.dangerScore), 'Danger score'));
  }
  const name = snapshot.companyName ? `<h3 class="company">${esc(String(snapshot.companyName))}</h3>` : '';
  const reports = snapshot.reportCount != null ? `<p>${Number(snapshot.reportCount)} community report(s)</p>` : '';
  const verdict = snapshot.verdict ? `<p class="verdict">${esc(String(snapshot.verdict))}</p>` : '';
  return section(
    'Company intelligence',
    `${name}<div class="gauge-row">${gauges.join('')}</div>${reports}${verdict}<p>${esc(String(snapshot.message ?? ''))}</p>`,
    'analysis',
  );
}

function buildDataSafety(snapshot: Record<string, unknown>): string {
  const lists = [
    ['Safe to share now', snapshot.safeNow],
    ['Share later', snapshot.shareLater],
    ['Never share', snapshot.neverShare],
  ];
  const body = lists
    .map(([title, items]) => {
      const arr = (items as unknown[]) ?? [];
      if (arr.length === 0) return '';
      return `<h4>${esc(String(title))}</h4><ul>${arr
        .map((i) => `<li>${esc(typeof i === 'string' ? i : JSON.stringify(i))}</li>`)
        .join('')}</ul>`;
    })
    .join('');
  const warnings = (snapshot.warnings as unknown[]) ?? [];
  const warn =
    warnings.length > 0
      ? `<div class="warnings">${warnings.map((w) => `<p class="warn">⚠ ${esc(String(w))}</p>`).join('')}</div>`
      : '';
  return section(
    'Data safety guidance',
    `<p class="summary">${esc(String(snapshot.summary ?? snapshot.message ?? ''))}</p>${body}${warn}`,
    'analysis',
  );
}

function buildAnalysis(snapshot: Record<string, unknown>): string {
  const type = String(snapshot.type ?? '');
  switch (type) {
    case 'scan':
      return buildScanAnalysis(snapshot);
    case 'offer_check':
      return buildOfferAnalysis(snapshot);
    case 'company_verify':
    case 'blacklist':
      return buildCompanyAnalysis(snapshot);
    case 'data_safety':
      return buildDataSafety(snapshot);
    case 'upload':
      if (
        snapshot.safetyScore != null ||
        (snapshot.findings as unknown[])?.length ||
        snapshot.analysis
      ) {
        if (snapshot.analysis) return buildOfferAnalysis(snapshot);
        return buildScanAnalysis(snapshot);
      }
      return snapshot.message
        ? section('Document', `<p>${esc(String(snapshot.message))}</p>`)
        : '';
    default:
      return snapshot.message
        ? section('Summary', `<p>${esc(String(snapshot.message))}</p>`)
        : '';
  }
}

export function renderPremiumSharePage(
  host: string,
  token: string,
  snapshot: Record<string, unknown>,
  env: ShareEnv,
  options?: { documentPreviewUrl?: string },
): string {
  const title = String(snapshot.title ?? 'INTERNSAFE AI Report');
  const subtitle = String(
    snapshot.subtitle ?? 'AI-Powered Internship Fraud Intelligence Platform',
  );
  const summary = String(
    snapshot.message ??
      snapshot.summary ??
      snapshot.explanation ??
      'Secure AI cybersecurity report shared via INTERNSAFE.',
  );
  const ogDesc = `${title} · ${summary}`.slice(0, 200);
  const pageUrl = shareUrl(host, token);
  const appUrl = appDeepLink(token);
  const legacyApp = legacyAppDeepLink(token);
  const playStore =
    env.PLAY_STORE_URL?.trim() ||
    'https://play.google.com/store/apps/details?id=com.internsafe.internsfe';
  const appStore = env.APP_STORE_URL?.trim() || playStore;
  const apkUrl = env.APK_DOWNLOAD_URL?.trim() || '';
  const docUrl = options?.documentPreviewUrl;
  const type = String(snapshot.type ?? 'report');

  const analysisHtml = buildAnalysis(snapshot);
  const docHtml = buildDocument(snapshot, docUrl);
  const sharedByHtml = buildSharedBy(snapshot);

  return `<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover"/>
  <title>${esc(title)} · INTERNSAFE AI</title>
  <meta name="description" content="${esc(ogDesc)}"/>
  <meta property="og:type" content="website"/>
  <meta property="og:url" content="${esc(pageUrl)}"/>
  <meta property="og:title" content="INTERNSAFE AI Report"/>
  <meta property="og:description" content="${esc(ogDesc)}"/>
  <meta property="og:site_name" content="INTERNSAFE AI"/>
  <meta property="og:image" content="https://${host}/brand/internsafe_ai_logo.png"/>
  <meta name="twitter:card" content="summary_large_image"/>
  <meta name="twitter:image" content="https://${host}/brand/internsafe_ai_logo.png"/>
  <meta name="twitter:title" content="${esc(title)}"/>
  <meta name="twitter:description" content="${esc(ogDesc)}"/>
  <link rel="preconnect" href="https://fonts.googleapis.com"/>
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin/>
  <link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@400;500;600;700&display=swap" rel="stylesheet"/>
  <style>
    :root,[data-theme="light"]{
      --bg:#f3f6fb;--bg2:#e8f2ee;--glass:rgba(255,255,255,.88);
      --border:rgba(11,122,87,.14);--text:#0b1220;--muted:#5a6b82;
      --mint:#0b7a57;--green:#12c48a;--glow:rgba(18,196,138,.2);
      --radius:16px;--max:920px;--grid:rgba(11,18,32,.04);
    }
    [data-theme="dark"]{
      --bg:#050a12;--bg2:#0a1220;--glass:rgba(15,23,36,.72);
      --border:rgba(94,234,212,.12);--text:#e8eef7;--muted:#94a3b8;
      --mint:#5eead4;--green:#22c55e;--glow:rgba(34,197,94,.25);--grid:rgba(255,255,255,.02);
    }
    *{box-sizing:border-box;margin:0;padding:0}
    body{
      font-family:"Plus Jakarta Sans",system-ui,sans-serif;
      background:radial-gradient(ellipse 80% 50% at 50% -10%,var(--glow),transparent),
        radial-gradient(ellipse 60% 40% at 100% 0%,rgba(94,234,212,.06),transparent),
        var(--bg);color:var(--text);min-height:100vh;line-height:1.55;
      transition:background .35s ease,color .35s ease;
    }
    .theme-toggle{
      position:fixed;top:16px;right:16px;z-index:300;
      display:flex;align-items:center;gap:8px;padding:8px 14px 8px 10px;
      border-radius:999px;border:1px solid var(--border);
      background:var(--glass);backdrop-filter:blur(14px);cursor:pointer;
      color:var(--text);font:inherit;font-size:.85rem;font-weight:600;
      box-shadow:0 4px 20px rgba(0,0,0,.12);
    }
    .theme-toggle .icon{font-size:1.1rem;line-height:1}
    .bg-grid{position:fixed;inset:0;background-image:linear-gradient(var(--grid) 1px,transparent 1px),
      linear-gradient(90deg,var(--grid) 1px,transparent 1px);
      background-size:48px 48px;mask-image:linear-gradient(180deg,#000,transparent 85%);pointer-events:none;z-index:0}
    .wrap{position:relative;z-index:1;max-width:var(--max);margin:0 auto;padding:24px 20px 120px}
    .glass{background:var(--glass);backdrop-filter:blur(16px);border:1px solid var(--border);
      border-radius:var(--radius);box-shadow:0 8px 32px rgba(0,0,0,.35),inset 0 1px 0 rgba(255,255,255,.04)}
    header.hero{padding:28px 24px;margin-bottom:20px;display:flex;gap:16px;align-items:center}
    .brand-text h1{font-size:1.35rem;font-weight:700;letter-spacing:-.02em}
    .brand-text p{color:var(--muted);font-size:.9rem;margin-top:4px}
    .report-head{margin:24px 0 16px}
    .report-head h2{font-size:1.5rem;font-weight:700}
    .report-head .type{color:var(--mint);font-size:.8rem;text-transform:uppercase;letter-spacing:.12em;font-weight:600}
    .summary-lead{color:var(--muted);margin-top:8px;font-size:1rem}
    .shared-by{display:flex;gap:16px;padding:20px;margin-bottom:20px;align-items:center}
    .avatar{width:52px;height:52px;border-radius:14px;background:linear-gradient(135deg,var(--mint),var(--green));
      display:flex;align-items:center;justify-content:center;font-weight:700;color:#041008;font-size:1rem;
      box-shadow:0 0 24px var(--glow)}
    .shared-meta .lbl{font-size:.72rem;text-transform:uppercase;letter-spacing:.1em;color:var(--muted)}
    .shared-meta .name{font-size:1.1rem;font-weight:600}
    .shared-meta .email{color:var(--muted);font-size:.9rem}
    .badge-verified{color:var(--green);font-size:.8rem;margin-top:4px}
    .shared-meta .when{color:var(--muted);font-size:.85rem;margin-top:6px}
    .panel{margin-bottom:14px;overflow:hidden}
    .panel-head{width:100%;display:flex;justify-content:space-between;align-items:center;
      padding:16px 20px;background:transparent;border:0;color:var(--text);cursor:pointer;font:inherit;text-align:left}
    .panel-head h2{font-size:1rem;font-weight:600}
    .panel-body{padding:0 20px 20px}
    .panel.collapsed .panel-body{display:none}
    .panel.collapsed .chev{transform:rotate(-90deg)}
    .chev{transition:transform .2s;color:var(--muted)}
    .gauge-row{display:flex;flex-wrap:wrap;gap:20px;margin:12px 0}
    .gauge{text-align:center}
    .gauge-val{font-size:1.75rem;font-weight:700;margin-top:-42px}
    .gauge-lbl{font-size:.8rem;color:var(--muted)}
    .chip{display:inline-block;padding:3px 10px;border-radius:999px;font-size:.72rem;font-weight:600;text-transform:capitalize}
    .chip-danger{background:rgba(248,113,113,.15);color:#fca5a5}
    .chip-warn{background:rgba(251,191,36,.15);color:#fcd34d}
    .chip-safe{background:rgba(74,222,128,.15);color:#86efac}
    .chip-neutral{background:rgba(148,163,184,.15);color:#cbd5e1}
    .finding{padding:14px;margin-bottom:10px}
    .finding header{margin-bottom:8px;display:flex;flex-wrap:wrap;gap:8px;align-items:center}
    .finding-val{font-family:ui-monospace,monospace;font-size:.85rem;color:var(--mint)}
    .finding-rec{color:var(--muted);font-size:.9rem;margin-top:6px}
    .ai-box{padding:16px;margin-top:12px;border-left:3px solid var(--green)}
    .ai-lbl{font-size:.72rem;text-transform:uppercase;color:var(--mint);margin-bottom:6px}
    .doc-card{padding:16px}
    .doc-meta{display:flex;flex-direction:column;gap:4px;margin-bottom:12px;font-size:.9rem}
    .doc-meta strong{font-size:1rem}
    .doc-preview{width:100%;max-height:480px;border-radius:12px;border:1px solid var(--border);margin-top:8px}
    .doc-preview.pdf{min-height:420px;background:#0f1724}
    .doc-placeholder{padding:32px;text-align:center;color:var(--muted)}
    .doc-icon{font-size:2rem;display:block;margin-bottom:8px}
    .rec-list,.reason-list{padding-left:20px;color:var(--muted)}
    .rec-list li,.reason-list li{margin:6px 0}
    .verdict{font-weight:600;color:var(--mint);margin:8px 0}
    .company{font-size:1.2rem;margin-bottom:8px}
    .sticky-cta{position:fixed;bottom:0;left:0;right:0;padding:16px 20px;
      background:linear-gradient(180deg,transparent,rgba(5,10,18,.95) 30%);
      display:flex;gap:10px;justify-content:center;flex-wrap:wrap;z-index:50}
  .btn{padding:14px 22px;border-radius:12px;font-weight:600;font-size:.95rem;border:none;cursor:pointer;text-decoration:none;display:inline-block;text-align:center}
    .btn-primary{background:linear-gradient(135deg,var(--mint),var(--green));color:#041008;box-shadow:0 4px 24px var(--glow)}
    .btn-ghost{background:rgba(30,41,59,.8);color:var(--text);border:1px solid var(--border)}
    .modal-backdrop{position:fixed;inset:0;background:rgba(0,0,0,.65);backdrop-filter:blur(6px);
      display:flex;align-items:center;justify-content:center;padding:20px;z-index:100;opacity:0;pointer-events:none;transition:opacity .25s}
    .modal-backdrop.show{opacity:1;pointer-events:auto}
    .modal{max-width:400px;width:100%;padding:28px;text-align:center}
    .modal h3{font-size:1.2rem;margin-bottom:10px}
    .modal p{color:var(--muted);font-size:.9rem;margin-bottom:20px;line-height:1.5}
    .modal .actions{display:flex;flex-direction:column;gap:10px}
    .store-row{display:flex;gap:8px;margin-top:12px;flex-wrap:wrap}
    .store-row a{flex:1;min-width:120px;font-size:.85rem;padding:10px}
    .loader{position:fixed;inset:0;background:var(--bg);display:flex;flex-direction:column;
      align-items:center;justify-content:center;z-index:200;transition:opacity .4s}
    .loader.hide{opacity:0;pointer-events:none}
    .loader p{color:var(--muted);margin-top:16px;font-size:.9rem}
    .pulse{width:56px;height:56px;border-radius:50%;background:var(--glow);
      animation:pulse 1.2s ease-in-out infinite}
    @keyframes pulse{0%,100%{transform:scale(1);opacity:.6}50%{transform:scale(1.08);opacity:1}}
    @media(min-width:768px){
      .wrap{padding:40px 32px 140px}
      header.hero{padding:32px 28px}
      .sticky-cta{padding:20px}
    }
  </style>
</head>
<body>
  <button type="button" class="theme-toggle" id="theme-toggle" aria-label="Toggle light or dark theme">
    <span class="icon" id="theme-icon">☀️</span><span id="theme-label">Light</span>
  </button>
  <div class="bg-grid" aria-hidden="true"></div>
  <div class="loader" id="loader"><div class="pulse"></div><p>Loading AI intelligence report…</p></div>
  <main class="wrap" id="content" hidden>
    <header class="hero glass">
      ${internsafeLogoImg(host, 44)}
      <div class="brand-text">
        <h1>INTERNSAFE AI</h1>
        <p>${esc(subtitle)}</p>
      </div>
    </header>
    <div class="report-head">
      <p class="type">${esc(type.replace(/_/g, ' '))}</p>
      <h2>${esc(title)}</h2>
      <p class="summary-lead">${esc(summary)}</p>
    </div>
    ${sharedByHtml}
    ${docHtml}
    ${analysisHtml}
  </main>
  <div class="sticky-cta">
    <button type="button" class="btn btn-primary" id="btn-open-app">View in App</button>
    <button type="button" class="btn btn-ghost" id="btn-stay-web">Continue on Web</button>
  </div>
  <div class="modal-backdrop" id="modal-open" role="dialog" aria-modal="true" aria-labelledby="m1">
    <div class="modal glass">
      <h3 id="m1">Open in INTERNSAFE AI App?</h3>
      <p>Get the full interactive report, AI assistant, and real-time fraud alerts.</p>
      <div class="actions">
        <button type="button" class="btn btn-primary" id="confirm-open-app">Open App</button>
        <button type="button" class="btn btn-ghost" id="confirm-stay-web">Continue on Web</button>
      </div>
    </div>
  </div>
  <div class="modal-backdrop" id="modal-install" role="dialog" aria-modal="true" aria-labelledby="m2">
    <div class="modal glass">
      <h3 id="m2">Get the Full INTERNSAFE AI Experience</h3>
      <p>Install the app to view complete AI reports, fraud intelligence, verify companies, and protect your internship journey.</p>
      <div class="actions">
        <a class="btn btn-primary" href="${esc(playStore)}" id="btn-download" data-event="download_click">Download App</a>
        <button type="button" class="btn btn-ghost" id="install-stay-web">Continue on Web</button>
      </div>
      <div class="store-row">
        <a class="btn btn-ghost" href="${esc(playStore)}">Play Store</a>
        <a class="btn btn-ghost" href="${esc(appStore)}">App Store</a>
        ${apkUrl ? `<a class="btn btn-ghost" href="${esc(apkUrl)}">APK</a>` : ''}
      </div>
    </div>
  </div>
  <script>
  (function(){
    var THEME_KEY = 'internsafe_theme';
    var root = document.documentElement;
    function applyTheme(mode){
      root.setAttribute('data-theme', mode);
      try{ localStorage.setItem(THEME_KEY, mode); }catch(e){}
      var icon = document.getElementById('theme-icon');
      var label = document.getElementById('theme-label');
      if(icon) icon.textContent = mode === 'dark' ? '🌙' : '☀️';
      if(label) label.textContent = mode === 'dark' ? 'Dark' : 'Light';
    }
  var stored = 'light';
  try{ stored = localStorage.getItem(THEME_KEY) || 'light'; }catch(e){}
  applyTheme(stored === 'dark' ? 'dark' : 'light');
  document.getElementById('theme-toggle').onclick = function(){
    var next = root.getAttribute('data-theme') === 'dark' ? 'light' : 'dark';
    applyTheme(next);
  };

    var TOKEN = ${JSON.stringify(token)};
    var APP = ${JSON.stringify(appUrl)};
    var LEGACY = ${JSON.stringify(legacyApp)};
    var PAGE = ${JSON.stringify(pageUrl)};
    var isMobile = /Android|iPhone|iPad|iPod/i.test(navigator.userAgent);
    var loader = document.getElementById('loader');
    var content = document.getElementById('content');
    var modalOpen = document.getElementById('modal-open');
    var modalInstall = document.getElementById('modal-install');
    var choseWeb = sessionStorage.getItem('is_web_' + TOKEN) === '1';
    var dismissedApp = sessionStorage.getItem('is_app_dismiss_' + TOKEN) === '1';

    function track(evt){
      try{
        fetch('/public/share/' + TOKEN + '/event', {
          method:'POST',
          headers:{'Content-Type':'application/json'},
          body: JSON.stringify({eventType: evt}),
          keepalive: true
        });
      }catch(e){}
    }
    track('web_view');

    setTimeout(function(){
      loader.classList.add('hide');
      content.hidden = false;
    }, 480);

    document.querySelectorAll('[data-toggle]').forEach(function(btn){
      btn.addEventListener('click', function(){
        var panel = btn.closest('.panel');
        if(panel) panel.classList.toggle('collapsed');
      });
    });

    function show(el){ el.classList.add('show'); }
    function hide(el){ el.classList.remove('show'); }

    function tryOpenApp(){
      track('app_open_attempt');
      window.location.href = APP;
      setTimeout(function(){ window.location.href = LEGACY; }, 400);
    }

    function autoOpenApp(){
      if(choseWeb || dismissedApp || !isMobile) return;
      tryOpenApp();
      sessionStorage.setItem('is_web_' + TOKEN, '1');
      sessionStorage.setItem('is_app_dismiss_' + TOKEN, '1');
    }

    document.getElementById('btn-open-app').onclick = function(){
      track('view_in_app_click');
      tryOpenApp();
    };
    document.getElementById('btn-stay-web').onclick = function(){
      sessionStorage.setItem('is_web_' + TOKEN, '1');
      sessionStorage.setItem('is_app_dismiss_' + TOKEN, '1');
      track('web_continue');
      var cta = document.querySelector('.sticky-cta');
      if (cta) cta.style.display = 'none';
    };

    autoOpenApp();
    var start = Date.now();
    window.addEventListener('pagehide', function(){
      track('time_on_page');
    });
  })();
  </script>
</body>
</html>`;
}

export function renderShareErrorPage(
  host: string,
  title: string,
  message: string,
): string {
  return `<!DOCTYPE html>
<html lang="en"><head>
<meta charset="utf-8"/><meta name="viewport" content="width=device-width,initial-scale=1"/>
<title>${esc(title)} · INTERNSAFE AI</title>
<link href="https://fonts.googleapis.com/css2?family=Plus+Jakarta+Sans:wght@500;600&display=swap" rel="stylesheet"/>
<style>
body{margin:0;min-height:100vh;display:flex;align-items:center;justify-content:center;
  font-family:"Plus Jakarta Sans",sans-serif;background:#050a12;color:#e8eef7;padding:24px}
.card{max-width:420px;text-align:center;padding:40px 28px;background:rgba(15,23,36,.8);
  border:1px solid rgba(94,234,212,.12);border-radius:20px}
h1{font-size:1.25rem;margin-bottom:12px}
p{color:#94a3b8;line-height:1.6}
.logo{margin-bottom:20px}
</style></head><body>
<div class="card">
  <div class="logo">${internsafeLogoImg(host, 48)}</div>
  <h1>${esc(title)}</h1>
  <p>${esc(message)}</p>
</div></body></html>`;
}
