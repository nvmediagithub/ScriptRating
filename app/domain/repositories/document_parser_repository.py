"""
Document Parser Repository interface.

This module defines the interface for document parsing operations.
"""
from abc import ABC, abstractmethod
from typing import Optional
from pathlib import Path

from ..entities.raw_script import RawScript


class DocumentParserRepository(ABC):
    """
    Abstract repository for document parsing operations.

    This interface defines the contract for extracting text content
    from various document formats (PDF, DOCX, etc.).
    """

    @abstractmethod
    async def parse_document(self, file_path: Path) -> RawScript:
        """
        Parse a document file and extract raw script content.

        Args:
            file_path: Path to the document file to parse

        Returns:
            RawScript: Extracted script content with metadata

        Raises:
            DocumentParseError: If parsing fails or file is unsupported
        """
        pass

    @abstractmethod
    def supports_format(self, file_path: Path) -> bool:
        """
        Check if the given file format is supported.

        Args:
            file_path: Path to the file to check

        Returns:
            bool: True if format is supported, False otherwise
        """
        pass

    @abstractmethod
    def get_supported_formats(self) -> list[str]:
        """
        Get list of supported file extensions.

        Returns:
            list[str]: List of supported file extensions (e.g., ['.pdf', '.docx'])
        """
        pass