"""Public internet intelligence — parallel search + NLP on real snippets only."""
from __future__ import annotations

import logging
import re
from typing import Any
from urllib.parse import quote

import httpx

from backend.ai.company_ai.internet_search_aggregator import aggregate_internet_search

logger = logging.getLogger(__name__)

_HEADERS = {
    "User-Agent": (
        "Mozilla/5.0 (compatible; INTERNSAFE-AI/1.0; +https://internsafe.app) "
        "CompanyVerificationBot"
    ),
}

COMPLAINT_RE = re.compile(
    r"\b(?:scam|fraud|fake|cheat|complaint|blacklist|"
    r"do\s*not\s*join|avoid|warning|fraudulent|"
    r"cyber\s*crime|police|fir|money\s*launder)\b",
    re.I,
)
POSITIVE_RE = re.compile(
    r"\b(?:legitimate|verified|reputed|good\s*company|"
    r"great\s*place\s*to\s*work|recommended)\b",
    re.I,
)
HIRING_RE = re.compile(
    r"\b(?:hiring|internship|job\s*opening|careers|recruit)\b",
    re.I,
)
SOURCE_HINTS = (
    ("reddit", "reddit.com"),
    ("glassdoor", "glassdoor"),
    ("linkedin", "linkedin"),
    ("news", "news"),
    ("review", "review"),
    ("trustpilot", "trustpilot"),
)


def _parse_ddg_json(data: dict[str, Any]) -> list[str]:
    snippets: list[str] = []
    abstract = (data.get("AbstractText") or "").strip()
    if abstract:
        snippets.append(abstract)
    heading = (data.get("Heading") or "").strip()
    if heading and heading not in abstract:
        snippets.append(heading)
    for topic in data.get("RelatedTopics") or []:
        if isinstance(topic, dict):
            text = (topic.get("Text") or "").strip()
            if text:
                snippets.append(text)
            for sub in topic.get("Topics") or []:
                if isinstance(sub, dict):
                    st = (sub.get("Text") or "").strip()
                    if st:
                        snippets.append(st)
    return snippets


def _duckduckgo_entity(name: str, *, timeout: float = 6.0) -> list[str]:
    """Instant Answer for the company name itself (works for Google, TCS, etc.)."""
    try:
        with httpx.Client(timeout=timeout, follow_redirects=True, headers=_HEADERS) as client:
            res = client.get(
                "https://api.duckduckgo.com/",
                params={
                    "q": name.strip(),
                    "format": "json",
                    "no_html": 1,
                    "skip_disambig": 0,
                },
            )
            if res.status_code >= 400:
                return []
            try:
                data = res.json()
            except ValueError:
                return []
            return _parse_ddg_json(data)[:12]
    except Exception as exc:
        logger.warning("DDG entity lookup failed for %r: %s", name, exc)
        return []


def _duckduckgo_snippets(query: str, *, timeout: float = 5.0) -> list[str]:
    snippets: list[str] = []
    try:
        with httpx.Client(timeout=timeout, follow_redirects=True, headers=_HEADERS) as client:
            res = client.get(
                "https://api.duckduckgo.com/",
                params={
                    "q": query,
                    "format": "json",
                    "no_html": 1,
                    "skip_disambig": 0,
                },
            )
            if res.status_code >= 400:
                return snippets
            try:
                data = res.json()
            except ValueError:
                return snippets
            snippets = _parse_ddg_json(data)
    except Exception as exc:
        logger.warning("DuckDuckGo search failed for %r: %s", query, exc)
    return snippets[:15]


def _wikipedia_summary(company_name: str, *, timeout: float = 6.0) -> list[str]:
    title = company_name.strip().replace(" ", "_")
    if len(title) < 2:
        return []
    try:
        with httpx.Client(timeout=timeout, follow_redirects=True, headers=_HEADERS) as client:
            res = client.get(
                f"https://en.wikipedia.org/api/rest_v1/page/summary/{quote(title)}",
            )
            if res.status_code == 404:
                return []
            if res.status_code != 200:
                return []
            data = res.json()
            extract = (data.get("extract") or "").strip()
            desc = (data.get("description") or "").strip()
            out: list[str] = []
            if extract:
                out.append(extract)
            if desc and desc not in extract:
                out.append(desc)
            return out
    except Exception as exc:
        logger.warning("Wikipedia lookup failed for %r: %s", company_name, exc)
        return []


def _html_lite_snippets(query: str, *, timeout: float = 6.0) -> list[str]:
    out: list[str] = []
    try:
        with httpx.Client(timeout=timeout, follow_redirects=True, headers=_HEADERS) as client:
            res = client.get(
                "https://lite.duckduckgo.com/lite/",
                params={"q": query},
            )
            if res.status_code >= 400:
                return out
            for m in re.finditer(
                r'class="result-snippet"[^>]*>([^<]+)<',
                res.text,
                re.I,
            ):
                t = re.sub(r"\s+", " ", m.group(1)).strip()
                if len(t) > 20:
                    out.append(t)
    except Exception as exc:
        logger.warning("DDG lite search failed: %s", exc)
    return out[:10]


def _html_search_snippets(query: str, *, timeout: float = 8.0) -> list[str]:
    """DuckDuckGo HTML results — richer snippets than lite for company names."""
    out: list[str] = []
    try:
        with httpx.Client(timeout=timeout, follow_redirects=True, headers=_HEADERS) as client:
            res = client.post(
                "https://html.duckduckgo.com/html/",
                data={"q": query, "b": "", "kl": "wt-wt"},
            )
            if res.status_code >= 400:
                return out
            text = res.text
            for m in re.finditer(
                r'class="result__snippet"[^>]*>([\s\S]*?)</(?:a|span|div)>',
                text,
                re.I,
            ):
                raw = re.sub(r"<[^>]+>", " ", m.group(1))
                t = re.sub(r"\s+", " ", raw).strip()
                if len(t) > 25:
                    out.append(t[:400])
            if not out:
                for m in re.finditer(
                    r'class="result__body"[^>]*>([\s\S]*?)</div>',
                    text,
                    re.I,
                ):
                    raw = re.sub(r"<[^>]+>", " ", m.group(1))
                    t = re.sub(r"\s+", " ", raw).strip()
                    if len(t) > 25:
                        out.append(t[:400])
    except Exception as exc:
        logger.warning("DDG HTML search failed for %r: %s", query[:60], exc)
    return out[:12]


def _analyze_snippets(
    unique: list[str],
    *,
    sources_ok: list[str],
    sources_failed: list[str],
    partial_message: str = "",
    has_wikipedia: bool = False,
) -> dict[str, Any]:
    if not unique:
        limited = _limited_response(
            partial_message or "Limited public information available."
        )
        limited["sources_ok"] = sources_ok
        limited["sources_failed"] = sources_failed
        limited["partial_message"] = partial_message
        return limited

    complaint_hits = 0
    positive_hits = 0
    hiring_hits = 0
    indicators: list[str] = []
    sources_found: list[str] = []

    for snippet in unique:
        low = snippet.lower()
        if COMPLAINT_RE.search(snippet):
            complaint_hits += 1
            if len(indicators) < 8:
                indicators.append(snippet[:200])
        if POSITIVE_RE.search(snippet):
            positive_hits += 1
        if HIRING_RE.search(snippet):
            hiring_hits += 1
        for label, hint in SOURCE_HINTS:
            if hint in low and label not in sources_found:
                sources_found.append(label)

    snippet_count = len(unique)
    complaint_ratio = complaint_hits / max(1, snippet_count)

    if complaint_hits >= 3 or complaint_ratio >= 0.4:
        activity_status = "high_risk_signals"
    elif complaint_hits >= 1:
        activity_status = "some_complaints"
    elif hiring_hits >= 2 and complaint_hits == 0:
        activity_status = "active_hiring"
    elif snippet_count >= 3 and complaint_hits == 0:
        activity_status = "neutral_presence"
    else:
        activity_status = "limited_activity"

    danger_from_web = min(85, complaint_hits * 12 + (15 if complaint_ratio >= 0.35 else 0))
    if complaint_hits == 0 and snippet_count >= 4 and positive_hits >= 1:
        trust_from_web = min(88, 72 + positive_hits * 3 + min(10, hiring_hits * 2))
    elif complaint_hits == 0 and snippet_count >= 2:
        trust_from_web = 68
    elif complaint_hits == 0 and snippet_count < 2:
        trust_from_web = 58
    else:
        trust_from_web = max(8, 100 - danger_from_web)

    if has_wikipedia and complaint_hits == 0:
        trust_from_web = max(trust_from_web, 78)
        if activity_status == "limited_activity":
            activity_status = "neutral_presence"

    summary_parts = [
        f"Analyzed {snippet_count} public snippet(s) from web search.",
    ]
    if partial_message:
        summary_parts.insert(0, partial_message)
    if complaint_hits:
        summary_parts.append(
            f"Found {complaint_hits} snippet(s) mentioning scams, fraud, or complaints."
        )
    else:
        summary_parts.append("No explicit scam/fraud keywords in retrieved snippets.")
    if hiring_hits:
        summary_parts.append(f"Hiring/internship mentions in {hiring_hits} snippet(s).")
    if has_wikipedia:
        summary_parts.append("Wikipedia company profile retrieved.")
    if sources_found:
        summary_parts.append(f"Sources touched: {', '.join(sources_found)}.")

    recommendation = _recommendation(
        complaint_hits, hiring_hits, positive_hits, activity_status
    )

    status = "completed" if snippet_count >= 1 else "limited"
    if sources_failed and snippet_count > 0:
        status = "partial"

    return {
        "internet_status": status,
        "internet_reputation_summary": " ".join(summary_parts),
        "complaint_count": complaint_hits,
        "snippet_count": snippet_count,
        "positive_mentions": positive_hits,
        "hiring_mentions": hiring_hits,
        "recent_activity_summary": _activity_summary(
            activity_status, hiring_hits, complaint_hits
        ),
        "activity_status": activity_status,
        "suspicious_indicators": indicators[:6],
        "sources_checked": ["duckduckgo_public", *sources_found],
        "sources_ok": sources_ok,
        "sources_failed": sources_failed,
        "web_trust_score": trust_from_web,
        "web_danger_score": danger_from_web,
        "ai_recommendation": recommendation,
        "evidence_snippets": unique[:5],
        "partial_message": partial_message,
    }


def _dedupe_snippets(snippets: list[str]) -> list[str]:
    seen: set[str] = set()
    unique: list[str] = []
    for s in snippets:
        key = s.lower()[:120]
        if key not in seen:
            seen.add(key)
            unique.append(s)
    return unique


def _seed_public_sources(company_name: str) -> tuple[list[str], list[str]]:
    """High-signal lookups before parallel scam-focused queries."""
    name = company_name.strip()
    snippets: list[str] = []
    sources: list[str] = []

    entity = _duckduckgo_entity(name)
    if entity:
        snippets.extend(entity)
        sources.append("duckduckgo_entity")

    wiki = _wikipedia_summary(name)
    if wiki:
        snippets.extend(wiki)
        sources.append("wikipedia")

    general_q = f"{name} company careers internship"
    html = _html_search_snippets(general_q)
    if html:
        snippets.extend(html)
        sources.append("duckduckgo_html")

    return _dedupe_snippets(snippets), sources


def gather_internet_intelligence(company_name: str) -> dict[str, Any]:
    logger.info("gather_internet_intelligence start company=%r", company_name)
    seed_snippets, seed_sources = _seed_public_sources(company_name)
    agg = aggregate_internet_search(company_name)
    combined = _dedupe_snippets(seed_snippets + (agg.get("snippets") or []))
    sources_ok = list(dict.fromkeys(seed_sources + (agg.get("sources_ok") or [])))
    sources_failed = agg.get("sources_failed") or []

    partial_message = agg.get("message") or ""
    if combined and (
        partial_message.startswith("Limited")
        or partial_message.startswith("Could not retrieve")
    ):
        partial_message = ""

    result = _analyze_snippets(
        combined,
        sources_ok=sources_ok,
        sources_failed=sources_failed,
        partial_message=partial_message,
        has_wikipedia="wikipedia" in seed_sources,
    )
    logger.info(
        "gather_internet_intelligence done company=%r status=%s snippets=%s",
        company_name,
        result.get("internet_status"),
        result.get("snippet_count"),
    )
    return result


def _limited_response(message: str) -> dict[str, Any]:
    return {
        "internet_status": "limited",
        "internet_reputation_summary": message,
        "complaint_count": 0,
        "snippet_count": 0,
        "positive_mentions": 0,
        "hiring_mentions": 0,
        "recent_activity_summary": message,
        "activity_status": "unknown",
        "suspicious_indicators": [],
        "sources_checked": [],
        "sources_ok": [],
        "sources_failed": [],
        "web_trust_score": None,
        "web_danger_score": None,
        "ai_recommendation": (
            "Limited public web data. Verify via official website and INTERNSAFE "
            "community reports before sharing documents."
        ),
        "evidence_snippets": [],
        "partial_message": message,
    }


def _activity_summary(status: str, hiring: int, complaints: int) -> str:
    mapping = {
        "high_risk_signals": "Multiple public complaint/scam signals detected.",
        "some_complaints": "Some negative public mentions found — proceed with caution.",
        "active_hiring": "Public hiring/internship activity detected without scam keywords.",
        "neutral_presence": "Company has online presence; no strong fraud signals in snippets.",
        "limited_activity": "Very limited public footprint from search results.",
        "unknown": "Could not determine activity level.",
    }
    base = mapping.get(status, status)
    if hiring:
        base += f" Hiring mentions: {hiring}."
    if complaints:
        base += f" Complaint-like mentions: {complaints}."
    return base


def _recommendation(complaints: int, hiring: int, positive: int, status: str) -> str:
    if complaints >= 3:
        return (
            "Multiple public sources mention scams or fraud related to this name. "
            "Do not pay fees or share Aadhaar/PAN until the employer is independently verified."
        )
    if complaints >= 1:
        return (
            "Some negative public mentions exist. Cross-check with INTERNSAFE community "
            "reports, official company domain email, and LinkedIn before proceeding."
        )
    if status == "active_hiring" and positive:
        return (
            "Public snippets show hiring activity without fraud keywords. "
            "Still verify offer letters and avoid upfront payment requests."
        )
    if status == "limited_activity":
        return (
            "Limited public information available. Treat as higher risk until "
            "you confirm registration, website, and recruiter identity."
        )
    return (
        "No strong fraud signals in public snippets, but always verify offers "
        "and never share bank/Aadhaar details before onboarding."
    )


def merge_company_intelligence(
    trust_result: dict[str, Any], internet: dict[str, Any]
) -> dict[str, Any]:
    from backend.ai.company_ai.trust_score_engine import compute_trust_score

    merged_ctx = {
        **trust_result,
        "web_trust_score": internet.get("web_trust_score"),
        "web_complaint_count": internet.get("complaint_count"),
        "snippet_count": internet.get("snippet_count"),
        "positive_mentions": internet.get("positive_mentions"),
        "hiring_mentions": internet.get("hiring_mentions"),
        "activity_status": internet.get("activity_status"),
    }
    final = compute_trust_score(merged_ctx)

    factors = list(final.get("factors") or [])
    summary = internet.get("internet_reputation_summary")
    if summary:
        factors.append(str(summary)[:160])

    internet_out = {**internet, **final}
    return {
        **final,
        "internet_intelligence": internet_out,
        "factors": factors,
        "recommendation": internet.get("ai_recommendation")
        or _recommendation(
            int(internet.get("complaint_count") or 0),
            int(internet.get("hiring_mentions") or 0),
            int(internet.get("positive_mentions") or 0),
            str(internet.get("activity_status") or ""),
        ),
    }
