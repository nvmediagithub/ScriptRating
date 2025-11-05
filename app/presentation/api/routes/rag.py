"""
RAG (Retrieval Augmented Generation) API routes.

This module provides endpoints for RAG-related operations including corpus management and queries.
"""
import uuid
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, HTTPException, Query
from fastapi.responses import JSONResponse

from app.presentation.api.schemas import (
    RAGQueryRequest,
    RAGQueryResponse,
    RAGResult,
    CitationSource,
    CorpusUpdateRequest,
    CorpusUpdateResponse,
    Category,
    ErrorResponse,
    ErrorDetail
)

router = APIRouter()


# Mock storage for RAG corpus and queries
_mock_corpus = {}
_mock_rag_queries = {}


def _generate_mock_corpus():
    """Generate mock RAG corpus data."""
    if not _mock_corpus:
        corpus_data = [
            {
                "content": "Согласно Федеральному закону № 436-ФЗ, информационная продукция для детей должна оцениваться по категориям: насилие, язык, сексуальное содержание и т.д.",
                "category": Category.VIOLENCE,
                "source": {"source_id": "fz436-1", "title": "ФЗ-436", "section": "Статья 8"},
                "relevance_score": 0.95
            },
            {
                "content": "Насилие в аудиовизуальных произведениях включает физическое насилие, угрозы, жестокое обращение с животными и демонстрацию оружия.",
                "category": Category.VIOLENCE,
                "source": {"source_id": "fz436-2", "title": "ФЗ-436", "section": "Статья 9"},
                "relevance_score": 0.92
            },
            {
                "content": "Классификация по возрастным категориям: 0+ (без ограничений), 6+, 12+, 16+, 18+ (запрещено для детей).",
                "category": Category.LANGUAGE,
                "source": {"source_id": "methodology-1", "title": "Методические рекомендации", "section": "Глава 2"},
                "relevance_score": 0.88
            },
            {
                "content": "Сексуальное содержание включает nudity, sexual acts, sexual innuendo и discussions of sexual themes.",
                "category": Category.SEXUAL_CONTENT,
                "source": {"source_id": "parents-guide-1", "title": "Parents Guide", "section": "Sexual Content"},
                "relevance_score": 0.90
            }
        ]

        for item in corpus_data:
            doc_id = str(uuid.uuid4())
            _mock_corpus[doc_id] = {
                "id": doc_id,
                **item,
                "embedding": [0.1 * i for i in range(384)],  # Mock embedding vector
                "added_at": datetime.utcnow()
            }


_generate_mock_corpus()


@router.post(
    "/query",
    response_model=RAGQueryResponse,
    summary="Query RAG system",
    description="Query the RAG system for relevant legal and reference content."
)
async def query_rag(request: RAGQueryRequest) -> RAGQueryResponse:
    """
    Query the RAG system.

    Args:
        request: RAG query request with search parameters

    Returns:
        RAG query results with relevant content and citations
    """
    # Filter corpus by category if specified
    relevant_docs = []
    for doc in _mock_corpus.values():
        if request.category and doc["category"] != request.category:
            continue
        # Simple mock relevance scoring based on content matching
        if any(word.lower() in doc["content"].lower() for word in request.query.split()):
            relevant_docs.append(doc)

    # Sort by relevance and limit results
    relevant_docs.sort(key=lambda x: x["relevance_score"], reverse=True)
    limited_docs = relevant_docs[:request.top_k]

    # Convert to response format
    results = []
    for doc in limited_docs:
        results.append(RAGResult(
            content=doc["content"],
            relevance_score=doc["relevance_score"],
            source=CitationSource(**doc["source"]),
            category=doc["category"]
        ))

    query_id = str(uuid.uuid4())
    _mock_rag_queries[query_id] = {
        "query_id": query_id,
        "query": request.query,
        "category": request.category,
        "top_k": request.top_k,
        "results": results,
        "timestamp": datetime.utcnow()
    }

    return RAGQueryResponse(
        query=request.query,
        results=results,
        total_found=len(relevant_docs)
    )


@router.post(
    "/corpus/update",
    response_model=CorpusUpdateResponse,
    summary="Update corpus",
    description="Add new content to the RAG knowledge corpus."
)
async def update_corpus(request: CorpusUpdateRequest) -> CorpusUpdateResponse:
    """
    Update the RAG corpus with new content.

    Args:
        request: Corpus update request with content and metadata

    Returns:
        Corpus update confirmation
    """
    # Generate mock content hash
    content_hash = str(hash(request.content))[:16]

    doc_id = str(uuid.uuid4())
    _mock_corpus[doc_id] = {
        "id": doc_id,
        "content": request.content,
        "category": request.category,
        "source": {
            "source_id": f"user-{doc_id[:8]}",
            "title": request.source_title,
            **(request.source_metadata or {})
        },
        "relevance_score": 0.85,  # Mock score for user content
        "embedding": [0.1 * i for i in range(384)],  # Mock embedding
        "added_at": datetime.utcnow()
    }

    return CorpusUpdateResponse(
        update_id=doc_id,
        content_hash=content_hash,
        updated_at=_mock_corpus[doc_id]["added_at"]
    )


@router.get(
    "/corpus",
    summary="List corpus documents",
    description="Get a list of documents in the RAG corpus."
)
async def list_corpus(
    category: Optional[Category] = Query(None, description="Filter by category"),
    limit: int = Query(50, ge=1, le=200, description="Maximum number of documents to return")
):
    """
    List corpus documents with optional filtering.

    Args:
        category: Filter by content category
        limit: Maximum number of documents to return

    Returns:
        List of corpus documents
    """
    docs = []
    for doc in _mock_corpus.values():
        if category and doc["category"] != category:
            continue
        docs.append({
            "id": doc["id"],
            "content_preview": doc["content"][:200] + "..." if len(doc["content"]) > 200 else doc["content"],
            "category": doc["category"].value,
            "source": doc["source"],
            "added_at": doc["added_at"],
            "content_length": len(doc["content"])
        })

    # Sort by addition date (newest first)
    docs.sort(key=lambda x: x["added_at"], reverse=True)
    docs = docs[:limit]

    return {
        "documents": docs,
        "count": len(docs),
        "total_in_corpus": len(_mock_corpus)
    }


@router.get(
    "/corpus/{document_id}",
    summary="Get corpus document",
    description="Get detailed information about a specific corpus document."
)
async def get_corpus_document(document_id: str):
    """
    Get corpus document details.

    Args:
        document_id: Unique document identifier

    Returns:
        Detailed document information
    """
    if document_id not in _mock_corpus:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Corpus document with ID {document_id} not found"
            ).dict()
        )

    doc = _mock_corpus[document_id]
    return {
        "id": doc["id"],
        "content": doc["content"],
        "category": doc["category"].value,
        "source": doc["source"],
        "relevance_score": doc["relevance_score"],
        "added_at": doc["added_at"],
        "embedding_dimensions": len(doc["embedding"])
    }


@router.delete(
    "/corpus/{document_id}",
    summary="Delete corpus document",
    description="Remove a document from the RAG corpus."
)
async def delete_corpus_document(document_id: str):
    """
    Delete a corpus document.

    Args:
        document_id: Unique document identifier

    Returns:
        Deletion confirmation
    """
    if document_id not in _mock_corpus:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Corpus document with ID {document_id} not found"
            ).dict()
        )

    # Remove from mock storage
    del _mock_corpus[document_id]

    return JSONResponse(
        content={"message": "Corpus document deleted successfully", "document_id": document_id},
        status_code=200
    )


@router.get(
    "/queries",
    summary="List RAG queries",
    description="Get a list of recent RAG queries and their results."
)
async def list_rag_queries(limit: int = Query(20, ge=1, le=100, description="Maximum number of queries to return")):
    """
    List recent RAG queries.

    Args:
        limit: Maximum number of queries to return

    Returns:
        List of recent queries
    """
    queries = []
    for query in list(_mock_rag_queries.values())[-limit:]:
        queries.append({
            "query_id": query["query_id"],
            "query": query["query"],
            "category": query["category"].value if query["category"] else None,
            "results_count": len(query["results"]),
            "timestamp": query["timestamp"]
        })

    return {
        "queries": queries,
        "count": len(queries)
    }


@router.get(
    "/stats",
    summary="Get RAG statistics",
    description="Get statistical information about the RAG system."
)
async def get_rag_stats():
    """
    Get RAG system statistics.

    Returns:
        RAG statistics
    """
    category_counts = {}
    for doc in _mock_corpus.values():
        cat = doc["category"].value
        category_counts[cat] = category_counts.get(cat, 0) + 1

    return {
        "corpus_stats": {
            "total_documents": len(_mock_corpus),
            "category_distribution": category_counts,
            "average_content_length": sum(len(doc["content"]) for doc in _mock_corpus.values()) / len(_mock_corpus) if _mock_corpus else 0
        },
        "query_stats": {
            "total_queries": len(_mock_rag_queries),
            "average_results_per_query": sum(len(q["results"]) for q in _mock_rag_queries.values()) / len(_mock_rag_queries) if _mock_rag_queries else 0
        }
    }