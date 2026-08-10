"""Parallel public web search aggregation — partial results on source failure."""
from __future__ import annotations

import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Any

logger = logging.getLogger(__name__)

# Per-query network budget (seconds)
_QUERY_TIMEOUT = 5.0
_LITE_TIMEOUT = 6.0
_POOL_TIMEOUT = 28.0
_MAX_WORKERS = 4


def build_search_queries(company_name: str) -> list[tuple[str, str]]:
    """(source_id, query) pairs — general presence + fraud/review signals."""
    name = company_name.strip()
    # Unquoted queries work better for well-known brands (Google, TCS, Infosys).
    return [
        ("general", f"{name} company employer"),
        ("careers", f"{name} careers internship hiring"),
        ("web_reviews", f"{name} company reviews"),
        ("web_scam", f"{name} internship scam fraud"),
        ("web_complaints", f"{name} complaints fake offer"),
        ("linkedin", f"{name} LinkedIn company page"),
        ("reddit", f"site:reddit.com {name} internship"),
        ("glassdoor", f"{name} Glassdoor OR Trustpilot reviews"),
    ]


def _fetch_query(source_id: str, query: str) -> tuple[str, list[str], str | None]:
    """HTML-based search only — DDG JSON API is called once in seed to avoid rate limits."""
    from backend.ai.company_ai.internet_intelligence import (
        _html_lite_snippets,
        _html_search_snippets,
    )

    try:
        snippets = _html_search_snippets(query, timeout=_LITE_TIMEOUT)
        if len(snippets) < 2:
            snippets.extend(_html_lite_snippets(query, timeout=_LITE_TIMEOUT))
        logger.info(
            "internet_search source=%s query=%r snippets=%d",
            source_id,
            query[:80],
            len(snippets),
        )
        return source_id, snippets, None
    except Exception as exc:
        logger.warning(
            "internet_search source=%s failed query=%r err=%s",
            source_id,
            query[:80],
            exc,
        )
        return source_id, [], str(exc)


def aggregate_internet_search(company_name: str) -> dict[str, Any]:
    """
    Run all search queries in parallel. Never raises — returns partial aggregates.
    """
    name = company_name.strip()
    if len(name) < 2:
        return {
            "snippets": [],
            "sources_ok": [],
            "sources_failed": ["all"],
            "partial": True,
            "message": "Company name too short for search.",
        }

    queries = build_search_queries(name)
    all_snippets: list[str] = []
    sources_ok: list[str] = []
    sources_failed: list[str] = []

    with ThreadPoolExecutor(max_workers=_MAX_WORKERS) as pool:
        futures = {
            pool.submit(_fetch_query, sid, q): sid for sid, q in queries
        }
        try:
            for fut in as_completed(futures, timeout=_POOL_TIMEOUT):
                source_id, snippets, err = fut.result()
                if err:
                    sources_failed.append(source_id)
                elif snippets:
                    sources_ok.append(source_id)
                    all_snippets.extend(snippets)
                else:
                    sources_failed.append(source_id)
        except TimeoutError:
            logger.error(
                "internet_search pool timeout company=%r after %.0fs",
                name,
                _POOL_TIMEOUT,
            )
            for fut, sid in futures.items():
                if not fut.done():
                    sources_failed.append(sid)
                    fut.cancel()

    seen: set[str] = set()
    unique: list[str] = []
    for s in all_snippets:
        key = s.lower()[:120]
        if key not in seen:
            seen.add(key)
            unique.append(s)

    partial = len(sources_failed) > 0 or len(unique) == 0
    msg = ""
    if not unique:
        msg = (
            "Could not retrieve public web snippets for this exact name. "
            "Try the full legal company name or check community reports below."
        )
    elif sources_failed:
        msg = (
            f"Partial web intelligence ({len(sources_ok)}/{len(queries)} sources). "
            f"Unavailable: {', '.join(sources_failed[:4])}."
        )

    logger.info(
        "internet_search done company=%r snippets=%d ok=%s failed=%s",
        name,
        len(unique),
        sources_ok,
        sources_failed,
    )

    return {
        "snippets": unique,
        "sources_ok": sources_ok,
        "sources_failed": sources_failed,
        "partial": partial,
        "message": msg,
    }
