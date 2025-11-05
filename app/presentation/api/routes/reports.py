"""
Report generation API routes.

This module provides endpoints for generating and downloading reports.
"""
import uuid
from datetime import datetime
from fastapi import APIRouter, HTTPException
from fastapi.responses import StreamingResponse, JSONResponse

from app.presentation.api.schemas import (
    ReportGenerationRequest,
    ReportGenerationResponse,
    ReportFormat,
    ErrorResponse,
    ErrorDetail
)

router = APIRouter()


# Mock storage for reports
_mock_reports = {}


def _generate_mock_report_content(format_type: ReportFormat) -> bytes:
    """Generate mock report content based on format."""
    if format_type == ReportFormat.PDF:
        # Mock PDF content (just some bytes)
        return b"%PDF-1.4\n1 0 obj\n<<\n/Type /Catalog\n/Pages 2 0 R\n>>\nendobj\n2 0 obj\n<<\n/Type /Pages\n/Kids [3 0 R]\n/Count 1\n>>\nendobj\n3 0 obj\n<<\n/Type /Page\n/Parent 2 0 R\n/MediaBox [0 0 612 792]\n/Contents 4 0 R\n>>\nendobj\n4 0 obj\n<<\n/Length 44\n>>\nstream\nBT\n72 720 Td\n/F0 12 Tf\n(Mock Report Content) Tj\nET\nendstream\nendobj\nxref\n0 5\n0000000000 65535 f\n0000000009 00000 n\n0000000058 00000 n\n0000000115 00000 n\n0000000202 00000 n\ntrailer\n<<\n/Size 5\n/Root 1 0 R\n>>\nstartxref\n297\n%%EOF"
    elif format_type == ReportFormat.DOCX:
        # Mock DOCX content (simplified)
        return b"PK\x03\x04\x14\x00\x00\x00\x00\x00\x8d\x8f\x8bN\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1a\x00\x00\x00[Content_Types].xmlPK\x01\x02\x14\x00\x14\x00\x00\x00\x00\x00\x8d\x8f\x8bN\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x1a\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00\x80\x01\x00\x00\x00\x00[Content_Types].xmlPK\x05\x06\x00\x00\x00\x00\x01\x00\x01\x00?\x00\x00\x00\x1a\x00\x00\x00\x00\x00"
    else:
        # JSON format
        import json
        return json.dumps({
            "report": {
                "title": "Script Rating Analysis Report",
                "generated_at": datetime.utcnow().isoformat(),
                "content": "Mock report content for demonstration purposes"
            }
        }).encode('utf-8')


@router.post(
    "/generate",
    response_model=ReportGenerationResponse,
    summary="Generate report",
    description="Generate a report for a completed analysis in the specified format."
)
async def generate_report(request: ReportGenerationRequest) -> ReportGenerationResponse:
    """
    Generate a report for an analysis.

    Args:
        request: Report generation request with analysis ID and format

    Returns:
        Report generation response with download URL
    """
    # Validate analysis exists (mock check - in real app would check database)
    if request.analysis_id not in ["mock-analysis-1", "mock-analysis-2", "mock-analysis-3"]:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="ANALYSIS_NOT_FOUND",
                message=f"Analysis with ID {request.analysis_id} not found"
            ).dict()
        )

    # Generate report ID and create mock report
    report_id = str(uuid.uuid4())

    _mock_reports[report_id] = {
        "report_id": report_id,
        "analysis_id": request.analysis_id,
        "format": request.format,
        "include_citations": request.include_citations,
        "include_timeline": request.include_timeline,
        "generated_at": datetime.utcnow(),
        "content": _generate_mock_report_content(request.format),
        "filename": f"script_rating_report_{request.analysis_id[:8]}.{request.format.value}"
    }

    # Create download URL (in real app this would be a signed URL or similar)
    download_url = f"/api/v1/reports/download/{report_id}"

    return ReportGenerationResponse(
        report_id=report_id,
        analysis_id=request.analysis_id,
        format=request.format,
        download_url=download_url,
        generated_at=_mock_reports[report_id]["generated_at"]
    )


@router.get(
    "/download/{report_id}",
    summary="Download report",
    description="Download a generated report file."
)
async def download_report(report_id: str):
    """
    Download a report file.

    Args:
        report_id: Unique report identifier

    Returns:
        StreamingResponse with the report file
    """
    if report_id not in _mock_reports:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="REPORT_NOT_FOUND",
                message=f"Report with ID {report_id} not found"
            ).dict()
        )

    report = _mock_reports[report_id]

    # Determine content type based on format
    content_types = {
        ReportFormat.PDF: "application/pdf",
        ReportFormat.DOCX: "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
        ReportFormat.JSON: "application/json"
    }

    return StreamingResponse(
        iter([report["content"]]),
        media_type=content_types[report["format"]],
        headers={
            "Content-Disposition": f'attachment; filename="{report["filename"]}"',
            "Content-Length": str(len(report["content"]))
        }
    )


@router.get(
    "/{report_id}",
    summary="Get report metadata",
    description="Retrieve metadata for a generated report."
)
async def get_report_metadata(report_id: str):
    """
    Get report metadata.

    Args:
        report_id: Unique report identifier

    Returns:
        Report metadata
    """
    if report_id not in _mock_reports:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="REPORT_NOT_FOUND",
                message=f"Report with ID {report_id} not found"
            ).dict()
        )

    report = _mock_reports[report_id]
    return {
        "report_id": report["report_id"],
        "analysis_id": report["analysis_id"],
        "format": report["format"].value,
        "filename": report["filename"],
        "generated_at": report["generated_at"],
        "size_bytes": len(report["content"]),
        "include_citations": report["include_citations"],
        "include_timeline": report["include_timeline"]
    }


@router.delete(
    "/{report_id}",
    summary="Delete report",
    description="Delete a generated report."
)
async def delete_report(report_id: str):
    """
    Delete a report.

    Args:
        report_id: Unique report identifier

    Returns:
        Deletion confirmation
    """
    if report_id not in _mock_reports:
        raise HTTPException(
            status_code=404,
            detail=ErrorDetail(
                code="REPORT_NOT_FOUND",
                message=f"Report with ID {report_id} not found"
            ).dict()
        )

    # Remove from mock storage
    del _mock_reports[report_id]

    return JSONResponse(
        content={"message": "Report deleted successfully", "report_id": report_id},
        status_code=200
    )


@router.get(
    "/",
    summary="List reports",
    description="Get a list of all generated reports."
)
async def list_reports():
    """
    List all generated reports.

    Returns:
        List of report metadata
    """
    reports = []
    for report in _mock_reports.values():
        reports.append({
            "report_id": report["report_id"],
            "analysis_id": report["analysis_id"],
            "format": report["format"].value,
            "filename": report["filename"],
            "generated_at": report["generated_at"],
            "size_bytes": len(report["content"])
        })

    return {"reports": reports, "count": len(reports)}