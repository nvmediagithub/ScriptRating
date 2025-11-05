"""
LLM Classifier Repository interface.

This module defines the interface for LLM-based content classification operations.
"""
from abc import ABC, abstractmethod
from typing import List, Optional, Dict, Any

from ..entities.flagged_scene import FlaggedScene
from ..entities.script_structure import Scene
from ..entities.scene_assessment import SceneAssessment


class LLMClassifierRepository(ABC):
    """
    Abstract repository for LLM-based content classification operations.

    This interface defines the contract for classifying scenes using
    large language models with optional RAG context.
    """

    @abstractmethod
    async def classify_scenes(
        self,
        scenes: List[Scene],
        flagged_scenes: Optional[List[FlaggedScene]] = None,
        use_rag_context: bool = True
    ) -> List[SceneAssessment]:
        """
        Classify multiple scenes using LLM.

        Args:
            scenes: List of Scene entities to classify
            flagged_scenes: Optional pre-flagged scenes for context
            use_rag_context: Whether to include RAG context in prompts

        Returns:
            List[SceneAssessment]: Classification results for each scene

        Raises:
            LLMClassificationError: If classification fails
        """
        pass

    @abstractmethod
    async def classify_single_scene(
        self,
        scene: Scene,
        flagged_scene: Optional[FlaggedScene] = None,
        use_rag_context: bool = True
    ) -> SceneAssessment:
        """
        Classify a single scene using LLM.

        Args:
            scene: Scene entity to classify
            flagged_scene: Optional pre-flagged scene for context
            use_rag_context: Whether to include RAG context in prompts

        Returns:
            SceneAssessment: Classification result

        Raises:
            LLMClassificationError: If classification fails
        """
        pass

    @abstractmethod
    def get_supported_models(self) -> List[str]:
        """
        Get list of supported LLM models.

        Returns:
            List[str]: Available model names
        """
        pass

    @abstractmethod
    def get_current_model(self) -> str:
        """
        Get the currently active model name.

        Returns:
            str: Current model identifier
        """
        pass

    @abstractmethod
    def switch_model(self, model_name: str) -> None:
        """
        Switch to a different LLM model.

        Args:
            model_name: Name of the model to switch to

        Raises:
            ModelNotAvailableError: If model is not available
        """
        pass

    @abstractmethod
    def get_classification_stats(self, assessments: List[SceneAssessment]) -> Dict[str, Any]:
        """
        Get statistics about classification results.

        Args:
            assessments: Results from classification

        Returns:
            Dict[str, Any]: Statistics (avg_confidence, severity_distribution, etc.)
        """
        pass

    @abstractmethod
    def is_model_available(self, model_name: str) -> bool:
        """
        Check if a specific model is available and loaded.

        Args:
            model_name: Model name to check

        Returns:
            bool: True if model is available
        """
        pass