"""
ScriptStructure domain entity.

This module defines the ScriptStructure entity representing segmented script content.
"""
from dataclasses import dataclass
from typing import List, Optional
from datetime import datetime


@dataclass
class Dialogue:
    """
    Represents a dialogue line in a scene.

    Attributes:
        character: Character name (in uppercase)
        text: Dialogue text
        line_number: Line number in original script
    """
    character: str
    text: str
    line_number: int


@dataclass
class Action:
    """
    Represents an action description in a scene.

    Attributes:
        text: Action description text
        line_number: Line number in original script
    """
    text: str
    line_number: int


@dataclass
class Scene:
    """
    Represents a scene in the script.

    Attributes:
        heading: Scene heading (INT./EXT., location, time)
        number: Scene number
        range: Tuple of (start_line, end_line)
        actions: List of action descriptions
        dialogues: List of dialogue lines
    """
    heading: str
    number: int
    range: tuple[int, int]
    actions: List[Action]
    dialogues: List[Dialogue]


@dataclass
class ScriptStructure:
    """
    Domain entity representing the structured script after segmentation.

    Attributes:
        id: Unique identifier
        raw_script_id: Reference to the original raw script
        scenes: List of parsed scenes
        total_scenes: Total number of scenes
        segmented_at: Segmentation timestamp
    """
    id: str
    raw_script_id: str
    scenes: List[Scene]
    total_scenes: int
    segmented_at: datetime = None

    def __post_init__(self):
        """Set default segmentation timestamp."""
        if self.segmented_at is None:
            self.segmented_at = datetime.utcnow()