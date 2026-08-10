"""Fraud graph — link entities across intelligence records."""
from __future__ import annotations

from typing import Any

from backend.ai.fraud_intelligence.clustering_engine import extract_fraud_identifiers


def build_entity_graph(texts: list[dict[str, Any]]) -> dict[str, Any]:
    """
    texts: [{id, text, type}]
    Returns nodes/edges for coordinated scam visualization.
    """
    nodes: dict[str, dict] = {}
    edges: list[dict] = []

    def _node(nid: str, ntype: str, label: str):
        if nid not in nodes:
            nodes[nid] = {"id": nid, "type": ntype, "label": label}

    for doc in texts:
        doc_id = doc.get("id", "")
        extracted = extract_fraud_identifiers(doc.get("text", ""))
        doc_node = f"doc:{doc_id}"
        _node(doc_node, "document", doc.get("type", "doc"))

        for email in extracted["emails"]:
            en = f"email:{email}"
            _node(en, "email", email)
            edges.append({"source": doc_node, "target": en, "relation": "mentions"})
        for domain in extracted["domains"]:
            dn = f"domain:{domain}"
            _node(dn, "domain", domain)
            edges.append({"source": doc_node, "target": dn, "relation": "mentions"})

    return {
        "nodes": list(nodes.values()),
        "edges": edges,
        "node_count": len(nodes),
        "edge_count": len(edges),
    }
