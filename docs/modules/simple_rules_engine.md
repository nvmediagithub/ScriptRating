# Simple Rules Engine Module

## Purpose & Overview

The **Simple Rules Engine** provides a lightweight, keyword‑based, per‑scene analysis path that works alongside the main
LLM + RAG pipeline. It is designed for:

- fast prototyping and UI experiments (scene‑by‑scene feedback);
- demonstrating how FZ‑436 rules can be formalized as machine‑readable rules;
- quick sanity checks without invoking heavy LLM/RAG components.

It does **not** replace the main Rating Engine; instead, it offers a simplified, local approximation that is easy to
extend and iterate on.

## Input / Output

### Input

- `SceneCheckRequest` (API DTO):
  - `script_id: str` — script identifier,
  - `scene_id: str` — scene identifier within the script,
  - `scene_text: str` — raw text of the scene.

### Output

- `SceneCheckResponse` (API DTO):
  - `script_id: str`,
  - `scene_id: str`,
  - `normative_doc_id: str` — ruleset identifier (e.g. `FZ436_SIMPLE`),
  - `normative_doc_version: str` — ruleset version (e.g. `1.0`),
  - `final_rating: AgeRating` — calculated rating for this scene,
  - `violations: List[SceneViolation]` — triggered rules.

- `SceneViolation`:
  - `rule_id: str` — rule identifier inside the ruleset,
  - `law_ref: Optional[str]` — reference to a legal or internal guideline,
  - `rating_level: AgeRating` — rating level associated with this rule,
  - `category: Category` — content category (`violence`, `language`, `alcohol_drugs`, etc.),
  - `snippet: str` — short text fragment that triggered the rule,
  - `comment: Optional[str]` — human‑readable explanation.

## Internal Workflow

```mermaid
flowchart TD
    A[Scene Text] --> B[Normalize Text<br/>lower-case]
    B --> C[Iterate Over SimpleRule[]]
    C --> D{Keyword Found?}
    D -->|No| C
    D -->|Yes| E[Extract Snippet<br/>context around match]
    E --> F[Create SceneViolation]
    F --> C
    C --> G[All Rules Checked]
    G --> H[Compute Final Rating<br/>max(rating_level)]
    H --> I[Build SceneCheckResponse]
```

### Key Steps

1. **Normalization**: scene text is converted to lower‑case; no stemming/lemmatization is applied.
2. **Rule Matching**:
   - For each `SimpleRule`, the engine checks if any of the `keywords` substring‑match the text.
   - On the first match for a rule, a `SceneViolation` is created; subsequent matches for the same rule are ignored.
3. **Snippet Extraction**:
   - A small window around the match index is extracted as `snippet` (context for UI highlighting).
4. **Final Rating Calculation**:
   - The final rating is computed as the maximum `rating_level` across all triggered violations.

## Integration Points

- **Input from**: `analysis` API route (`/api/analysis/check_scene`), called directly from Flutter UI.
- **Output to**:
  - Flutter UI (per‑scene feedback and visual indicators),
  - Potentially future logging/audit subsystems (not yet implemented).
- **Dependencies**:
  - `SceneCheckRequest`, `SceneCheckResponse`, `SceneViolation`, `AgeRating`, `Category` — from `app.presentation.api.schemas`.

## API Route

The Simple Rules Engine is exposed via the `analysis` router:

```python
@router.post(
    "/check_scene",
    response_model=SceneCheckResponse,
    summary="Simplified per-scene rule-based analysis",
)
async def check_scene(request: SceneCheckRequest) -> SceneCheckResponse:
    ...
```

This route is intentionally isolated from the main `/analysis/analyze` pipeline and does not depend on LLM/RAG or
Rating Engine internals.

## Design Decisions

- **Simplicity over completeness**:
  - keyword‑based matching only, no NLP, no semantics;
  - per‑scene rating (no aggregation across the whole script).
- **Non‑intrusive**:
  - lives in the Infrastructure layer (`app.infrastructure.services.simple_rules_engine`);
  - does not modify or depend on the main Rating Engine logic.
- **Extensibility**:
  - `SimpleRule` and `SimpleNormativeDoc` are designed so they can later be loaded from JSON/DB instead of hard‑coding;
  - severity thresholds and categories can be aligned with the main Rating Engine once rules are validated on real data.

