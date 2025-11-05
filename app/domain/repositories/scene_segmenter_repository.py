"""
Scene Segmenter Repository interface.

This module defines the interface for scene segmentation operations.
"""
from abc import ABC, abstractmethod
from typing import Optional

from ..entities.raw_script import RawScript
from ..entities.script_structure import ScriptStructure


class SceneSegmenterRepository(ABC):
    """
    Abstract repository for scene segmentation operations.

    This interface defines the contract for segmenting raw script text
    into structured scenes, dialogues, and actions.
    """

    @abstractmethod
    async def segment_script(self, raw_script: RawScript) -> ScriptStructure:
        """
        Segment raw script into structured scenes and dialogues.

        Args:
            raw_script: RawScript entity to segment

        Returns:
            ScriptStructure: Segmented script with scenes and dialogues

        Raises:
            SceneSegmentationError: If segmentation fails
        """
        pass

    @abstractmethod
    def validate_segmentation(self, structure: ScriptStructure) -> bool:
        """
        Validate that the segmented structure meets basic requirements.

        Args:
            structure: ScriptStructure to validate

        Returns:
            bool: True if valid, False otherwise
        """
        pass

    @abstractmethod
    def get_segmentation_stats(self, structure: ScriptStructure) -> dict[str, int]:
        """
        Get statistics about the segmentation result.

        Args:
            structure: ScriptStructure to analyze

        Returns:
            dict[str, int]: Statistics (scenes_count, dialogues_count, actions_count, etc.)
        """
        pass