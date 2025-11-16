"""
RAG (Retrieval Augmented Generation) API routes.

This module provides endpoints for RAG-related operations including corpus management and queries.
Now integrated with the new RAG infrastructure (EmbeddingService, VectorDatabaseService, RAGOrchestrator).
"""
import uuid
import logging
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, HTTPException, Query, Depends
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

logger = logging.getLogger(__name__)
router = APIRouter()

# Global instances (will be initialized in main.py)
_rag_orchestrator = None
_knowledge_base = None

# Mock storage for backward compatibility
_mock_corpus = {}
_mock_rag_queries = {}


def get_rag_orchestrator():
    """Dependency to get RAG orchestrator instance."""
    if _rag_orchestrator is None:
        raise HTTPException(
            status_code=503,
            detail="RAG orchestrator not initialized"
        )
    return _rag_orchestrator


def get_knowledge_base():
    """Dependency to get knowledge base instance."""
    if _knowledge_base is None:
        raise HTTPException(
            status_code=503,
            detail="Knowledge base not initialized"
        )
    return _knowledge_base


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
    description="Query the RAG system for relevant legal and reference content using vector search."
)
async def query_rag(request: RAGQueryRequest) -> RAGQueryResponse:
    """
    Query the RAG system using vector search.

    Args:
        request: RAG query request with search parameters

    Returns:
        RAG query results with relevant content and citations
    """
    try:
        # Try to use knowledge base (which may use RAG orchestrator internally)
        if _knowledge_base:
            legacy_results = await _knowledge_base.query(
                text=request.query,
                top_k=request.top_k,
            )
            
            # Convert to API format
            results = []
            for doc in legacy_results:
                # Map category from metadata if available
                category = request.category or Category.VIOLENCE  # Default
                if "category" in doc.get("metadata", {}):
                    try:
                        category = Category(doc["metadata"]["category"])
                    except (ValueError, KeyError):
                        pass
                
                results.append(RAGResult(
                    content=doc["excerpt"],
                    relevance_score=doc["score"],
                    source=CitationSource(
                        source_id=doc.get("document_id", "unknown"),
                        title=doc.get("title", "Unknown Document"),
                        section=f"Page {doc.get('page', 1)}, Para {doc.get('paragraph', 1)}"
                    ),
                    category=category
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
                total_found=len(legacy_results)
            )
        
        # Fallback to mock implementation
        relevant_docs = []
        for doc in _mock_corpus.values():
            if request.category and doc["category"] != request.category:
                continue
            if any(word.lower() in doc["content"].lower() for word in request.query.split()):
                relevant_docs.append(doc)

        relevant_docs.sort(key=lambda x: x["relevance_score"], reverse=True)
        limited_docs = relevant_docs[:request.top_k]

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
    
    except Exception as e:
        logger.error(f"Error in RAG query: {e}")
        raise HTTPException(
            status_code=500,
            detail=f"RAG query failed: {str(e)}"
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


@router.get(
    "/health",
    summary="RAG system health check",
    description="Check the health status of RAG components."
)
async def rag_health_check():
    """
    Check RAG system health.
    
    Returns:
        Health status of all RAG components
    """
    health = {
        "status": "healthy",
        "timestamp": datetime.utcnow().isoformat(),
        "components": {},
    }
    
    try:
        # Check knowledge base
        if _knowledge_base:
            kb_status = await _knowledge_base.get_rag_status()
            health["components"]["knowledge_base"] = kb_status
            
            # Check RAG orchestrator if available
            if kb_status.get("rag_enabled") and _rag_orchestrator:
                rag_health = await _rag_orchestrator.health_check()
                health["components"]["rag_orchestrator"] = rag_health
                
                if rag_health.get("status") != "healthy":
                    health["status"] = "degraded"
        else:
            health["status"] = "degraded"
            health["components"]["knowledge_base"] = {
                "available": False,
                "message": "Knowledge base not initialized"
            }
    
    except Exception as e:
        logger.error(f"Health check error: {e}")
        health["status"] = "unhealthy"
        health["error"] = str(e)
    
    return health


@router.get(
    "/metrics",
    summary="RAG system metrics",
    description="Get performance metrics for the RAG system."
)
async def rag_metrics():
    """
    Get RAG system metrics.
    
    Returns:
        Performance and usage metrics
    """
    metrics = {
        "timestamp": datetime.utcnow().isoformat(),
        "legacy_corpus_size": len(_mock_corpus),
        "total_queries": len(_mock_rag_queries),
    }
    
    try:
        # Get RAG orchestrator metrics if available
        if _rag_orchestrator:
            rag_metrics = await _rag_orchestrator.get_metrics()
            metrics["rag_orchestrator"] = {
                "indexed_documents": rag_metrics.total_indexed_documents,
                "total_searches": rag_metrics.total_searches,
                "average_search_time_ms": rag_metrics.average_search_time_ms,
                "cache_hit_rate": rag_metrics.cache_hit_rate,
                "vector_db_status": rag_metrics.vector_db_status,
                "embedding_service_status": rag_metrics.embedding_service_status,
            }
        
        # Get knowledge base stats
        if _knowledge_base:
            kb_stats = await _knowledge_base.get_document_stats()
            metrics["knowledge_base"] = {
                "documents_count": len(kb_stats),
                "total_paragraphs": sum(
                    doc.get("paragraphs_indexed", 0) for doc in kb_stats
                ),
            }
    
    except Exception as e:
        logger.error(f"Error getting metrics: {e}")
        metrics["error"] = str(e)
    
    return metrics


def set_rag_orchestrator(orchestrator):
    """Set the global RAG orchestrator instance."""
    global _rag_orchestrator
    _rag_orchestrator = orchestrator


def set_knowledge_base(knowledge_base):
    """Set the global knowledge base instance."""
    global _knowledge_base
    _knowledge_base = knowledge_base