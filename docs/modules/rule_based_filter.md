# Rule-Based Filter Module

## Detailed Description
The Rule-Based Filter serves as a fast pre-screening layer to identify potential content violations before invoking the more expensive LLM classifier. It performs dictionary-based and pattern-matching checks against configurable rule sets to flag scenes that may contain problematic content.

### Input
- Individual scene or dialogue text from ScriptStructure

### Output
- `FlaggedScene` object containing:
  - Categories with boolean flags for potential violations
  - Matched terms or patterns for each category
  - Confidence scores for rule-based detections

## Internal Workflow Diagram
```mermaid
flowchart TD
    A[Receive Scene Text] --> B[Load Rule Dictionaries]
    B --> C[Check Profanity Dictionary]
    C --> D[Check Violence Patterns]
    D --> E[Check Substance References]
    E --> F[Check Sexual Content Patterns]
    F --> G[Check Scary Content Regex]
    G --> H[Aggregate Flags by Category]
    H --> I[Output FlaggedScene with Scores]
```

## Integration Points
- **Input from**: Scene Segmenter (individual scenes for scanning)
- **Output to**: LLM Classifier (flagged scenes for detailed analysis)
- **Dependencies**: Configuration files containing dictionaries and regex patterns

## Key Design Decisions
- Implement configurable dictionaries for profanity, substances, and sensitive terms
- Use regex patterns for detecting violence and sexual content scenarios
- Support morphological analysis with Natasha/SpaCy for Russian language variations
- Provide confidence scoring to prioritize scenes for LLM review
- Enable easy updates to rule sets without code changes
- Include fallback patterns for common content variations