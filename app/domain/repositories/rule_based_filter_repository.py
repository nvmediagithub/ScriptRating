"""
Rule-Based Filter Repository interface.

This module defines the interface for rule-based content filtering operations.
"""
from abc import ABC, abstractmethod
from typing import List, Dict

from ..entities.script_structure import ScriptStructure
from ..entities.flagged_scene import FlaggedScene


class RuleBasedFilterRepository(ABC):
    """
    Abstract repository for rule-based content filtering operations.

    This interface defines the contract for scanning script scenes
    using predefined dictionaries and patterns to flag inappropriate content.
    """

    @abstractmethod
    async def scan_scenes(self, script_structure: ScriptStructure) -> List[FlaggedScene]:
        """
        Scan all scenes in a script structure for flagged content.

        Args:
            script_structure: ScriptStructure to scan

        Returns:
            List[FlaggedScene]: List of scenes with any flags found

        Raises:
            RuleFilterError: If scanning fails
        """
        pass

    @abstractmethod
    def get_filter_dictionaries(self) -> Dict[str, List[str]]:
        """
        Get the current filter dictionaries for each category.

        Returns:
            Dict[str, List[str]]: Dictionary mapping categories to word lists
        """
        pass

    @abstractmethod
    def update_filter_dictionary(self, category: str, words: List[str]) -> None:
        """
        Update the filter dictionary for a specific category.

        Args:
            category: Content category to update
            words: New list of words/patterns for this category
        """
        pass

    @abstractmethod
    def get_supported_categories(self) -> List[str]:
        """
        Get list of supported content categories.

        Returns:
            List[str]: List of category names
        """
        pass

    @abstractmethod
    def get_filter_stats(self, flagged_scenes: List[FlaggedScene]) -> Dict[str, int]:
        """
        Get statistics about filtering results.

        Args:
            flagged_scenes: Results from scanning

        Returns:
            Dict[str, int]: Statistics (total_scenes, flagged_scenes, flags_by_category, etc.)
        """
        pass