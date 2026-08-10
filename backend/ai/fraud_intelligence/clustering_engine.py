"""Fraud clustering — repeated identifiers & campaign detection."""
from __future__ import annotations

import re
from collections import defaultdict
from typing import Any

from backend.ai.utils.patterns import EMAIL, PHONE_IN, UPI

DOMAIN_RE = re.compile(r"@([\w.-]+\.\w+)", re.I)


def extract_fraud_identifiers(text: str) -> dict[str, list[str]]:
    emails = list({m.group(0).lower() for m in EMAIL.regex.finditer(text)})
    phones = list({m.group(0) for m in PHONE_IN.regex.finditer(text)})
    upis = list({m.group(0).lower() for m in UPI.regex.finditer(text)})
    domains = list({m.group(1).lower() for m in DOMAIN_RE.finditer(text)})
    return {
        "emails": emails[:20],
        "phones": phones[:20],
        "upi_ids": upis[:20],
        "domains": domains[:20],
    }


def cluster_reports(
    reports: list[dict[str, Any]],
    min_cluster_size: int = 2,
) -> list[dict[str, Any]]:
    """
    reports: [{id, description, company_name, ...}]
    Groups by shared domain/email/phone across reports.
    """
    domain_map: dict[str, list[str]] = defaultdict(list)
    email_map: dict[str, list[str]] = defaultdict(list)
    phone_map: dict[str, list[str]] = defaultdict(list)

    for r in reports:
        rid = r.get("id", "")
        text = f"{r.get('description', '')} {r.get('company_name', '')}"
        ids = extract_fraud_identifiers(text)
        for d in ids["domains"]:
            domain_map[d].append(rid)
        for e in ids["emails"]:
            email_map[e].append(rid)
        for p in ids["phones"]:
            phone_map[p].append(rid)

    campaigns: list[dict[str, Any]] = []

    def _add(kind: str, key: str, report_ids: list[str]):
        unique = list(dict.fromkeys(report_ids))
        if len(unique) >= min_cluster_size:
            campaigns.append(
                {
                    "cluster_type": kind,
                    "cluster_key": key,
                    "report_ids": unique,
                    "size": len(unique),
                    "campaign_risk": "high" if len(unique) >= 5 else "medium",
                }
            )

    for d, rids in domain_map.items():
        _add("domain", d, rids)
    for e, rids in email_map.items():
        _add("email", e, rids)
    for p, rids in phone_map.items():
        _add("phone", p, rids)

    campaigns.sort(key=lambda c: c["size"], reverse=True)
    return campaigns[:30]
