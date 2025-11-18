"""
Document upload API routes.

Handles storing uploaded documents, indexing normative criteria into the
knowledge base, and registering scripts for later analysis.
"""
from __future__ import annotations

import uuid
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional

from fastapi import APIRouter, File, Form, HTTPException, UploadFile
from fastapi.responses import JSONResponse

from app.config import settings
from app.infrastructure.services.runtime_context import (
    document_parser,
    script_store,
    get_knowledge_base,
)
from app.presentation.api.schemas import DocumentType, DocumentUploadResponse, DocumentProcessingStatus, RAGProcessingDetails, ErrorDetail

router = APIRouter()

_DOCUMENT_REGISTRY: Dict[str, Dict[str, object]] = {}


class DocumentProcessingRegistry:
    """Registry for tracking document processing status and details."""

    def __init__(self):
        self._processing_status: Dict[str, Dict[str, object]] = {}

    def register_processing_start(self, document_id: str, uploaded_at: datetime) -> None:
        """Mark document processing as started."""
        self._processing_status[document_id] = {
            "status": "indexing",
            "processing_started_at": datetime.utcnow(),
            "processing_completed_at": None,
            "rag_processing_details": None,
            "error_message": None,
        }

    def update_processing_result(self, document_id: str, rag_processing_details: Optional[RAGProcessingDetails], error: Optional[str] = None) -> None:
        """Update document processing result."""
        if document_id not in self._processing_status:
            return

        status = self._processing_status[document_id]
        status["status"] = "completed" if error is None else "failed"
        status["processing_completed_at"] = datetime.utcnow()
        status["rag_processing_details"] = rag_processing_details
        status["error_message"] = error

    def get_processing_status(self, document_id: str) -> Optional[Dict[str, object]]:
        """Get processing status for a document."""
        return self._processing_status.get(document_id)


# Global processing registry
_processing_registry = DocumentProcessingRegistry()


def _ensure_storage_dir() -> Path:
    documents_root = Path(settings.documents_dir)
    documents_root.mkdir(parents=True, exist_ok=True)
    return documents_root


@router.post(
    "/upload",
    response_model=DocumentUploadResponse,
    summary="Upload a document",
    description="Upload script or criteria documents. Criteria files are indexed into the knowledge base.",
)
async def upload_document(
    file: UploadFile = File(...),
    filename: Optional[str] = Form(None),
    document_type: DocumentType = Form(DocumentType.SCRIPT),
) -> DocumentUploadResponse:
    """Handle document upload and optional indexing."""
    allowed_types = {
        "application/pdf",
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        "text/plain",
    }
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=ErrorDetail(
                code="INVALID_FILE_TYPE",
                message="Supported formats: PDF, DOCX, TXT",
                details={"received_type": file.content_type, "allowed_types": sorted(allowed_types)},
            ).dict(),
        )

    content = await file.read()
    file_size = len(content)
    if file_size > settings.max_upload_size:
        raise HTTPException(
            status_code=413,
            detail=ErrorDetail(
                code="FILE_TOO_LARGE",
                message=f"File size {file_size} exceeds limit {settings.max_upload_size}",
                details={"file_size": file_size, "limit": settings.max_upload_size},
            ).dict(),
        )

    document_id = str(uuid.uuid4())
    safe_filename = (filename or file.filename or "uploaded").split("/")[-1]
    documents_root = _ensure_storage_dir()
    document_dir = documents_root / document_type.value / document_id
    document_dir.mkdir(parents=True, exist_ok=True)
    stored_path = document_dir / safe_filename
    stored_path.write_bytes(content)

    if not document_parser.supports_format(stored_path):
        stored_path.unlink(missing_ok=True)
        raise HTTPException(
            status_code=400,
            detail=ErrorDetail(
                code="UNSUPPORTED_FORMAT",
                message=f"Формат файла {stored_path.suffix} не поддерживается",
                details={"supported": document_parser.get_supported_formats()},
            ).dict(),
        )

    parsed_document = await document_parser.parse_document(stored_path)
    uploaded_at = datetime.utcnow()
    status = "uploaded"
    chunks_indexed: Optional[int] = None
    rag_processing_details: Optional[RAGProcessingDetails] = None

    # Get the properly initialized knowledge base with RAG orchestrator
    kb = await get_knowledge_base()

    if document_type == DocumentType.CRITERIA:
        paragraph_details = parsed_document.metadata.get("paragraph_details", [])

        # Mark processing as started
        _processing_registry.register_processing_start(document_id, uploaded_at)

        # Try to ingest into knowledge base with RAG processing
        try:
            import logging
            logger = logging.getLogger(__name__)

            logger.info(f"=== RAG PROCESSING START for document {document_id} ===")
            logger.info(f"Knowledge base RAG status: {await kb.get_rag_status()}")
            logger.info(f"Checking RAG availability: hasattr(kb, '_rag_orchestrator')={hasattr(kb, '_rag_orchestrator')}")
            if hasattr(kb, '_rag_orchestrator'):
                logger.info(f"RAG orchestrator attribute exists: {kb._rag_orchestrator is not None}")
                if kb._rag_orchestrator:
                    logger.info(f"RAG orchestrator type: {type(kb._rag_orchestrator)}")
            else:
                logger.info("RAG orchestrator attribute does not exist on knowledge_base")

            if hasattr(kb, '_rag_orchestrator') and kb._rag_orchestrator:
                # Use RAG orchestrator for detailed processing
                from app.domain.services.rag_orchestrator import RAGDocument

                # Convert paragraph details to RAG documents
                rag_documents = []
                for detail in paragraph_details:
                    if detail.get("text", "").strip():
                        rag_doc = RAGDocument(
                            id=f"{document_id}_{len(rag_documents)}",
                            text=detail.get("text", "").strip(),
                            metadata={
                                "document_id": document_id,
                                "document_title": parsed_document.filename,
                                "page": detail.get("page", 1),
                                "paragraph_index": detail.get("paragraph_index", len(rag_documents) + 1),
                                **{k: v for k, v in detail.items() if k not in {"text", "page", "paragraph_index"}}
                            },
                        )
                        rag_documents.append(rag_doc)

                # Index with RAG and get detailed results
                logger.info(f"Starting RAG indexing for document {document_id} with {len(rag_documents)} chunks")
                logger.info(f"RAG orchestrator type: {type(kb._rag_orchestrator)}")
                logger.info(f"RAG orchestrator methods: {[method for method in dir(kb._rag_orchestrator) if not method.startswith('_')]}")

                indexing_result = await kb._rag_orchestrator.index_documents_batch(
                    rag_documents,
                    wait_for_indexing=True
                )
                logger.info(f"RAG indexing completed for document {document_id}: {indexing_result}")
                logger.info(f"Indexing result type: {type(indexing_result)}")
                logger.info(f"Indexing result attributes: {dir(indexing_result)}")

                # Convert to response format
                rag_processing_details = RAGProcessingDetails(
                    total_chunks=indexing_result.total_chunks,
                    chunks_processed=indexing_result.chunks_processed,
                    embedding_generation_status=indexing_result.embedding_generation_status,
                    embedding_model_used=indexing_result.embedding_model_used,
                    vector_db_indexing_status=indexing_result.vector_db_indexing_status,
                    documents_indexed=indexing_result.documents_indexed,
                    indexing_time_ms=indexing_result.indexing_time_ms,
                    processing_errors=indexing_result.processing_errors if indexing_result.processing_errors else None,
                )
                logger.info(f"Created RAGProcessingDetails for document {document_id}: {rag_processing_details}")
                logger.info(f"RAGProcessingDetails dict: {rag_processing_details.dict() if hasattr(rag_processing_details, 'dict') else rag_processing_details.__dict__}")

                # Update processing status
                _processing_registry.update_processing_result(document_id, rag_processing_details)
                logger.info(f"Updated processing registry for document {document_id} with details: {rag_processing_details is not None}")
                logger.info(f"=== RAG PROCESSING END for document {document_id} - SUCCESS ===")

                # Also sync to legacy knowledge base for backward compatibility
                await kb.ingest_document(
                    document_id=document_id,
                    document_title=parsed_document.filename,
                    paragraph_details=paragraph_details,
                )
            else:
                # Fallback to legacy knowledge base only
                await kb.ingest_document(
                    document_id=document_id,
                    document_title=parsed_document.filename,
                    paragraph_details=paragraph_details,
                )

                # Update processing status for legacy indexing
                _processing_registry.update_processing_result(document_id, None)

        except Exception as e:
            # Log error and update processing status
            import logging
            logger = logging.getLogger(__name__)
            logger.warning(f"=== RAG PROCESSING END for document {document_id} - FAILED ===")
            logger.warning(f"RAG processing failed, falling back to legacy indexing: {e}")
            logger.warning(f"RAG orchestrator state: {kb._rag_orchestrator if hasattr(kb, '_rag_orchestrator') else 'No _rag_orchestrator attribute'}")
            logger.warning(f"Exception type: {type(e)}, args: {e.args}")

            # Update processing status with error - explicitly set None for rag_processing_details
            logger.info(f"Setting rag_processing_details to None due to RAG failure for document {document_id}")
            _processing_registry.update_processing_result(document_id, None, str(e))

            # Ensure legacy indexing happens even if RAG fails
            await kb.ingest_document(
                document_id=document_id,
                document_title=parsed_document.filename,
                paragraph_details=paragraph_details,
            )

        chunks_indexed = len(paragraph_details)
        status = "indexed"
    else:
        payload = {
            "document_id": document_id,
            "filename": parsed_document.filename,
            "text": parsed_document.text,
            "paragraphs": parsed_document.paragraphs,
            "paragraph_details": parsed_document.metadata.get("paragraph_details", []),
            "page_count": parsed_document.metadata.get("page_count"),
        }
        await script_store.save_script(document_id, payload)

    _DOCUMENT_REGISTRY[document_id] = {
        "document_id": document_id,
        "filename": parsed_document.filename,
        "document_type": document_type,
        "content_type": file.content_type,
        "size": file_size,
        "uploaded_at": uploaded_at,
        "path": str(stored_path),
        "status": status,
        "chunks_indexed": chunks_indexed,
    }

    return DocumentUploadResponse(
        document_id=document_id,
        filename=parsed_document.filename,
        uploaded_at=uploaded_at,
        document_type=document_type,
        chunks_indexed=chunks_indexed,
        rag_processing_details=rag_processing_details,
        status=status,
    )


@router.get(
    "/{document_id}/status",
    summary="Get document processing status and details",
    description="Retrieve detailed processing status and RAG processing reports for an uploaded document.",
    response_model=DocumentProcessingStatus,
)
async def get_document_processing_status(document_id: str) -> DocumentProcessingStatus:
    """Return detailed processing status and RAG details for a document."""
    if document_id not in _DOCUMENT_REGISTRY:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Document with ID {document_id} not found",
            ).dict(),
        )

    doc = _DOCUMENT_REGISTRY[document_id]
    processing_status = _processing_registry.get_processing_status(document_id)

    # For criteria documents, try to get processing details
    rag_processing_details = None
    processing_started_at = None
    processing_completed_at = None
    error_message = None
    current_status = doc["status"]

    if processing_status:
        rag_processing_details = processing_status.get("rag_processing_details")
        processing_started_at = processing_status.get("processing_started_at")
        processing_completed_at = processing_status.get("processing_completed_at")
        error_message = processing_status.get("error_message")
        current_status = processing_status.get("status", current_status)
        import logging
        logger = logging.getLogger(__name__)
        logger.info(f"Retrieved processing status for document {document_id}: rag_processing_details={rag_processing_details}, status={current_status}")
    else:
        import logging
        logger = logging.getLogger(__name__)
        logger.warning(f"No processing status found for document {document_id}")

    return DocumentProcessingStatus(
        document_id=doc["document_id"],
        filename=doc["filename"],
        document_type=doc["document_type"],
        status=current_status,
        uploaded_at=doc["uploaded_at"],
        processing_started_at=processing_started_at,
        processing_completed_at=processing_completed_at,
        rag_processing_details=rag_processing_details,
        error_message=error_message,
    )


@router.get(
    "/{document_id}",
    summary="Get document metadata",
    description="Retrieve metadata for an uploaded document.",
)
async def get_document(document_id: str):
    """Return stored metadata for a single document."""
    if document_id not in _DOCUMENT_REGISTRY:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Document with ID {document_id} not found",
            ).dict(),
        )

    doc = _DOCUMENT_REGISTRY[document_id]
    return {
        "document_id": doc["document_id"],
        "filename": doc["filename"],
        "document_type": doc["document_type"],
        "content_type": doc["content_type"],
        "size": doc["size"],
        "uploaded_at": doc["uploaded_at"],
        "status": doc["status"],
        "chunks_indexed": doc.get("chunks_indexed"),
    }


@router.delete(
    "/{document_id}",
    summary="Delete a document",
    description="Delete an uploaded document and its associated data.",
)
async def delete_document(document_id: str):
    """Delete stored metadata, files, and index entries."""
    if document_id not in _DOCUMENT_REGISTRY:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Document with ID {document_id} not found",
            ).dict(),
        )

    doc = _DOCUMENT_REGISTRY.pop(document_id)
    stored_path = Path(str(doc.get("path")))
    if stored_path.exists():
        stored_path.unlink()
        try:
            stored_path.parent.rmdir()
        except OSError:
            pass

    if doc["document_type"] == DocumentType.CRITERIA:
        kb = await get_knowledge_base()
        await kb.remove_document(document_id)
    else:
        await script_store.delete_script(document_id)

    return JSONResponse(
        content={"message": "Document deleted successfully", "document_id": document_id},
        status_code=200,
    )


@router.get(
    "/",
    summary="List uploaded documents",
    description="Get a list of all uploaded documents.",
)
async def list_documents():
    """Return metadata for all uploaded documents."""
    documents = []
    for doc in _DOCUMENT_REGISTRY.values():
        documents.append(
            {
                "document_id": doc["document_id"],
                "filename": doc["filename"],
                "document_type": doc["document_type"],
                "content_type": doc["content_type"],
                "size": doc["size"],
                "uploaded_at": doc["uploaded_at"],
                "status": doc["status"],
                "chunks_indexed": doc.get("chunks_indexed"),
            }
        )

    return {"documents": documents, "count": len(documents)}
