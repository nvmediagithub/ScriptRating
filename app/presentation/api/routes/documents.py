"""
Document upload API routes.

This module provides endpoints for uploading and managing documents.
"""
import uuid
from datetime import datetime
from typing import Optional
from fastapi import APIRouter, UploadFile, File, HTTPException, Form
from fastapi.responses import JSONResponse

from app.presentation.api.schemas import (
    DocumentUploadRequest,
    DocumentUploadResponse,
    ErrorResponse,
    ErrorDetail
)

router = APIRouter()


# Mock storage for uploaded documents
_mock_documents = {}


@router.post(
    "/upload",
    response_model=DocumentUploadResponse,
    summary="Upload a document",
    description="Upload a script document (PDF or DOCX) for analysis."
)
async def upload_document(
    file: UploadFile = File(...),
    filename: Optional[str] = Form(None)
) -> DocumentUploadResponse:
    """
    Upload a document file.

    Args:
        file: The uploaded file
        filename: Optional custom filename

    Returns:
        DocumentUploadResponse: Upload confirmation with document ID
    """
    # Validate file type
    allowed_types = ["application/pdf", "application/vnd.openxmlformats-officedocument.wordprocessingml.document"]
    if file.content_type not in allowed_types:
        raise HTTPException(
            status_code=400,
            detail=ErrorDetail(
                code="INVALID_FILE_TYPE",
                message="Only PDF and DOCX files are supported",
                details={"received_type": file.content_type, "allowed_types": allowed_types}
            ).dict()
        )

    # Validate file size (mock limit: 10MB)
    file_size = len(await file.read())
    max_size = 10 * 1024 * 1024  # 10MB
    if file_size > max_size:
        raise HTTPException(
            status_code=413,
            detail=ErrorDetail(
                code="FILE_TOO_LARGE",
                message=f"File size {file_size} bytes exceeds maximum {max_size} bytes",
                details={"file_size": file_size, "max_size": max_size}
            ).dict()
        )

    # Generate document ID and store mock data
    document_id = str(uuid.uuid4())
    final_filename = filename or file.filename

    _mock_documents[document_id] = {
        "id": document_id,
        "filename": final_filename,
        "content_type": file.content_type,
        "size": file_size,
        "uploaded_at": datetime.utcnow(),
        "content": await file.read()  # Store content for mock purposes
    }

    return DocumentUploadResponse(
        document_id=document_id,
        filename=final_filename,
        uploaded_at=_mock_documents[document_id]["uploaded_at"],
        status="uploaded"
    )


@router.get(
    "/{document_id}",
    summary="Get document metadata",
    description="Retrieve metadata for an uploaded document."
)
async def get_document(document_id: str):
    """
    Get document information.

    Args:
        document_id: Unique document identifier

    Returns:
        Document metadata
    """
    if document_id not in _mock_documents:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Document with ID {document_id} not found"
            ).dict()
        )

    doc = _mock_documents[document_id]
    return {
        "document_id": doc["id"],
        "filename": doc["filename"],
        "content_type": doc["content_type"],
        "size": doc["size"],
        "uploaded_at": doc["uploaded_at"],
        "status": "available"
    }


@router.delete(
    "/{document_id}",
    summary="Delete a document",
    description="Delete an uploaded document and its associated data."
)
async def delete_document(document_id: str):
    """
    Delete a document.

    Args:
        document_id: Unique document identifier

    Returns:
        Deletion confirmation
    """
    if document_id not in _mock_documents:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="DOCUMENT_NOT_FOUND",
                message=f"Document with ID {document_id} not found"
            ).dict()
        )

    # Remove from mock storage
    del _mock_documents[document_id]

    return JSONResponse(
        content={"message": "Document deleted successfully", "document_id": document_id},
        status_code=200
    )


@router.get(
    "/",
    summary="List uploaded documents",
    description="Get a list of all uploaded documents."
)
async def list_documents():
    """
    List all uploaded documents.

    Returns:
        List of document metadata
    """
    documents = []
    for doc in _mock_documents.values():
        documents.append({
            "document_id": doc["id"],
            "filename": doc["filename"],
            "content_type": doc["content_type"],
            "size": doc["size"],
            "uploaded_at": doc["uploaded_at"],
            "status": "available"
        })

    return {"documents": documents, "count": len(documents)}