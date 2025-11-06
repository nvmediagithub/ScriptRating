"""
File system backed document parser implementation.

This module provides a concrete implementation of the DocumentParserRepository
that can parse PDF, DOCX, and TXT files into RawScript entities with basic
page/paragraph metadata suitable for downstream processing.
"""
from __future__ import annotations

import asyncio
from pathlib import Path
from typing import List

from pypdf import PdfReader
from docx import Document as DocxDocument

from app.domain.entities.raw_script import RawScript
from app.domain.repositories.document_parser_repository import DocumentParserRepository


class UnsupportedDocumentFormatError(Exception):
    """Raised when the parser is asked to process an unsupported file format."""


class FileSystemDocumentParser(DocumentParserRepository):
    """Parse documents stored on the filesystem into RawScript entities."""

    _SUPPORTED_FORMATS = {".pdf", ".docx", ".txt"}

    async def parse_document(self, file_path: Path) -> RawScript:
        """
        Parse the provided document file asynchronously.

        Args:
            file_path: Path to the document file.

        Returns:
            RawScript: Parsed script content with metadata.
        """
        return await asyncio.to_thread(self._parse_sync, file_path)

    def supports_format(self, file_path: Path) -> bool:
        """Return True when the file extension is supported."""
        return file_path.suffix.lower() in self._SUPPORTED_FORMATS

    def get_supported_formats(self) -> List[str]:
        """Return the list of supported file extensions."""
        return sorted(self._SUPPORTED_FORMATS)

    # --------------------------------------------------------------------- #
    # Internal helpers
    # --------------------------------------------------------------------- #
    def _parse_sync(self, file_path: Path) -> RawScript:
        suffix = file_path.suffix.lower()
        if suffix == ".pdf":
            return self._parse_pdf(file_path)
        if suffix == ".docx":
            return self._parse_docx(file_path)
        if suffix == ".txt":
            return self._parse_txt(file_path)
        raise UnsupportedDocumentFormatError(f"Unsupported file format: {suffix}")

    def _parse_pdf(self, file_path: Path) -> RawScript:
        reader = PdfReader(str(file_path))
        pages: List[str] = []
        paragraphs: List[str] = []
        paragraph_details = []

        for page_index, page in enumerate(reader.pages):
            text = page.extract_text() or ""
            pages.append(text)
            raw_paragraphs = [
                block.strip()
                for block in text.replace("\r", "\n").split("\n\n")
                if block.strip()
            ]
            for paragraph_index, paragraph in enumerate(raw_paragraphs, start=1):
                paragraphs.append(paragraph)
                paragraph_details.append(
                    {
                        "page": page_index + 1,
                        "paragraph_index": paragraph_index,
                        "text": paragraph,
                    }
                )

        combined_text = "\n\n".join(paragraphs)
        metadata = {
            "source_path": str(file_path),
            "paragraph_details": paragraph_details,
            "page_count": len(pages),
            "file_type": "pdf",
        }

        return RawScript(
            id=file_path.stem,
            filename=file_path.name,
            text=combined_text,
            pages=pages,
            paragraphs=paragraphs,
            metadata=metadata,
        )

    def _parse_docx(self, file_path: Path) -> RawScript:
        document = DocxDocument(str(file_path))
        paragraphs: List[str] = []
        paragraph_details = []

        for paragraph_index, paragraph in enumerate(document.paragraphs, start=1):
            text = paragraph.text.strip()
            if not text:
                continue
            paragraphs.append(text)
            paragraph_details.append(
                {
                    "page": 1,  # DOCX does not expose pagination without layout engine
                    "paragraph_index": paragraph_index,
                    "text": text,
                }
            )

        combined_text = "\n\n".join(paragraphs)
        metadata = {
            "source_path": str(file_path),
            "paragraph_details": paragraph_details,
            "page_count": 1,
            "file_type": "docx",
        }

        return RawScript(
            id=file_path.stem,
            filename=file_path.name,
            text=combined_text,
            pages=[combined_text],
            paragraphs=paragraphs,
            metadata=metadata,
        )

    def _parse_txt(self, file_path: Path) -> RawScript:
        text = file_path.read_text(encoding="utf-8")
        paragraphs = [line.strip() for line in text.splitlines() if line.strip()]
        paragraph_details = [
            {
                "page": 1,
                "paragraph_index": index,
                "text": paragraph,
            }
            for index, paragraph in enumerate(paragraphs, start=1)
        ]

        metadata = {
            "source_path": str(file_path),
            "paragraph_details": paragraph_details,
            "page_count": 1,
            "file_type": "txt",
        }

        return RawScript(
            id=file_path.stem,
            filename=file_path.name,
            text=text,
            pages=[text],
            paragraphs=paragraphs,
            metadata=metadata,
        )
