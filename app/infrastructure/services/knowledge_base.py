"""
In-memory knowledge base for normative documents used in RAG lookups.

The knowledge base stores paragraph-level chunks with metadata (page, paragraph
number, document id) and exposes simple TF-IDF based retrieval to provide
references for LLM reasoning and reporting.
"""
from __future__ import annotations

import asyncio
import uuid
from dataclasses import dataclass
from typing import Any, Dict, List, Optional

import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


@dataclass
class KnowledgeEntry:
    """Normalized representation of a paragraph-sized knowledge chunk."""

    entry_id: str
    document_id: str
    document_title: str
    page: int
    paragraph: int
    text: str
    metadata: Dict[str, Any]


class KnowledgeBase:
    """Manage normative knowledge entries and perform similarity search."""

    def __init__(self) -> None:
        self._entries: List[KnowledgeEntry] = []
        self._vectorizer: Optional[TfidfVectorizer] = None
        self._matrix = None
        self._lock = asyncio.Lock()

    async def ingest_document(
        self,
        document_id: str,
        document_title: str,
        paragraph_details: List[Dict[str, Any]],
    ) -> None:
        """
        Ingest (or re-ingest) a document into the knowledge base.

        Existing entries for the same document will be replaced.
        """
        cleaned_entries = [
            KnowledgeEntry(
                entry_id=str(uuid.uuid4()),
                document_id=document_id,
                document_title=document_title,
                page=int(detail.get("page", 1)),
                paragraph=int(detail.get("paragraph_index", 1)),
                text=detail.get("text", "").strip(),
                metadata={
                    key: value
                    for key, value in detail.items()
                    if key not in {"text", "page", "paragraph_index"}
                },
            )
            for detail in paragraph_details
            if detail.get("text", "").strip()
        ]

        async with self._lock:
            self._entries = [
                entry for entry in self._entries if entry.document_id != document_id
            ]
            self._entries.extend(cleaned_entries)
            self._rebuild_index_locked()

    async def remove_document(self, document_id: str) -> None:
        """Remove all knowledge entries associated with a document."""
        async with self._lock:
            self._entries = [
                entry for entry in self._entries if entry.document_id != document_id
            ]
            self._rebuild_index_locked()

    async def query(self, text: str, top_k: int = 3) -> List[Dict[str, Any]]:
        """Retrieve the top-k most relevant knowledge chunks for the query."""
        query_text = text.strip()
        if not query_text:
            return []

        async with self._lock:
            if not self._entries or self._vectorizer is None or self._matrix is None:
                return []

            query_vector = self._vectorizer.transform([query_text])
            similarities = cosine_similarity(query_vector, self._matrix)[0]
            if not np.any(similarities):
                return []

            ranked_indices = np.argsort(similarities)[::-1][:top_k]
            results: List[Dict[str, Any]] = []
            for index in ranked_indices:
                entry = self._entries[int(index)]
                score = float(similarities[int(index)])
                results.append(
                    {
                        "document_id": entry.document_id,
                        "title": entry.document_title,
                        "page": entry.page,
                        "paragraph": entry.paragraph,
                        "excerpt": entry.text,
                        "score": score,
                        "metadata": entry.metadata,
                    }
                )
            return results

    async def get_document_stats(self) -> List[Dict[str, Any]]:
        """Return aggregated statistics for indexed documents."""
        async with self._lock:
            stats: Dict[str, Dict[str, Any]] = {}
            for entry in self._entries:
                doc_stats = stats.setdefault(
                    entry.document_id,
                    {
                        "document_id": entry.document_id,
                        "title": entry.document_title,
                        "paragraphs_indexed": 0,
                    },
                )
                doc_stats["paragraphs_indexed"] += 1
            return list(stats.values())

    def _rebuild_index_locked(self) -> None:
        """Rebuild the TF-IDF index; caller must hold the lock."""
        texts = [entry.text for entry in self._entries if entry.text]
        if not texts:
            self._vectorizer = None
            self._matrix = None
            return

        self._vectorizer = TfidfVectorizer(
            lowercase=True,
            ngram_range=(1, 2),
            max_features=5000,
        )
        self._matrix = self._vectorizer.fit_transform(texts)
