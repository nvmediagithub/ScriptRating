"""
RAG Document domain entity.

This module defines the RAGDocument entity representing documents in the vector store.
"""
from dataclasses import dataclass
from typing import List, Dict, Optional
from datetime import datetime


class DocumentType:
    """Enumeration of document types in the RAG corpus."""
    LEGAL = "legal"
    GUIDELINE = "guideline"
    EXAMPLE = "example"
    USER_FEEDBACK = "user_feedback"
    TEMPLATE = "template"


@dataclass
class RAGDocument:
    """
    Domain entity representing a document in the RAG vector store.

    Attributes:
        id: Unique identifier
        title: Document title
        content: Full document content
        content_type: Type of document (legal, guideline, example, etc.)
        source: Original source reference
        metadata: Additional metadata (author, date, tags, etc.)
        embedding: Vector embedding (optional, computed at indexing time)
        indexed_at: Timestamp of indexing
    """
    id: str
    title: str
    content: str
    content_type: str
    source: str
    metadata: Dict[str, str]
    embedding: Optional[List[float]] = None
    indexed_at: datetime = None

    def __post_init__(self):
        """Set default indexing timestamp."""
        if self.indexed_at is None:
            self.indexed_at = datetime.utcnow()

    def get_metadata_value(self, key: str) -> Optional[str]:
        """Get a metadata value by key."""
        return self.metadata.get(key)

    def has_embedding(self) -> bool:
        """Check if document has computed embedding."""
        return self.embedding is not None

    def get_content_chunks(self, chunk_size: int = 1000) -> List[str]:
        """
        Split content into chunks for embedding.

        Args:
            chunk_size: Maximum characters per chunk

        Returns:
            List[str]: Content chunks
        """
        if len(self.content) <= chunk_size:
            return [self.content]

        chunks = []
        words = self.content.split()
        current_chunk = ""

        for word in words:
            if len(current_chunk) + len(word) + 1 <= chunk_size:
                current_chunk += " " + word if current_chunk else word
            else:
                if current_chunk:
                    chunks.append(current_chunk)
                current_chunk = word

        if current_chunk:
            chunks.append(current_chunk)

        return chunks