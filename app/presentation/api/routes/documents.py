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
    knowledge_base,
    script_store,
)
from app.presentation.api.schemas import DocumentType, DocumentUploadResponse, ErrorDetail

router = APIRouter()

_DOCUMENT_REGISTRY: Dict[str, Dict[str, object]] = {}


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

    if document_type == DocumentType.CRITERIA:
        paragraph_details = parsed_document.metadata.get("paragraph_details", [])
        await knowledge_base.ingest_document(
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
        status=status,
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
        await knowledge_base.remove_document(document_id)
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
