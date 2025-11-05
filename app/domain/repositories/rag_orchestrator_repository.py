"""
RAG Orchestrator Repository interface.

This module defines the interface for RAG (Retrieval Augmented Generation) operations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any

from ..entities.rag_document import RAGDocument


class RAGOrchestratorRepository(ABC):
    """
    Abstract repository for RAG operations.

    This interface defines the contract for managing the RAG knowledge base,
    including document indexing, retrieval, and context augmentation.
    """

    @abstractmethod
    async def retrieve_context(
        self,
        query: str,
        top_k: int = 5,
        filters: Optional[Dict[str, Any]] = None
    ) -> List[RAGDocument]:
        """
        Retrieve relevant documents from the vector store.

        Args:
            query: Search query
            top_k: Number of top results to return
            filters: Optional filters (content_type, metadata, etc.)

        Returns:
            List[RAGDocument]: Relevant documents

        Raises:
            RetrievalError: If retrieval fails
        """
        pass

    @abstractmethod
    async def index_document(self, document: RAGDocument) -> str:
        """
        Index a new document in the vector store.

        Args:
            document: RAGDocument to index

        Returns:
            str: Document ID in the store

        Raises:
            IndexingError: If indexing fails
        """
        pass

    @abstractmethod
    async def update_document(self, document_id: str, content: str) -> None:
        """
        Update an existing document's content and re-index.

        Args:
            document_id: ID of document to update
            content: New content

        Raises:
            DocumentNotFoundError: If document doesn't exist
        """
        pass

    @abstractmethod
    async def delete_document(self, document_id: str) -> None:
        """
        Remove a document from the vector store.

        Args:
            document_id: ID of document to delete

        Raises:
            DocumentNotFoundError: If document doesn't exist
        """
        pass

    @abstractmethod
    def get_document_count(self, content_type: Optional[str] = None) -> int:
        """
        Get the count of documents in the store.

        Args:
            content_type: Optional filter by content type

        Returns:
            int: Number of documents
        """
        pass

    @abstractmethod
    def get_supported_content_types(self) -> List[str]:
        """
        Get list of supported document content types.

        Returns:
            List[str]: Supported content types
        """
        pass

    @abstractmethod
    def build_prompt_context(
        self,
        documents: List[RAGDocument],
        max_tokens: Optional[int] = None
    ) -> str:
        """
        Build formatted context string for LLM prompts.

        Args:
            documents: Documents to include in context
            max_tokens: Maximum token limit for context

        Returns:
            str: Formatted context string
        """
        pass

    @abstractmethod
    def get_indexing_stats(self) -> Dict[str, Any]:
        """
        Get statistics about the vector index.

        Returns:
            Dict[str, Any]: Statistics (total_docs, avg_embedding_time, etc.)
        """
        pass