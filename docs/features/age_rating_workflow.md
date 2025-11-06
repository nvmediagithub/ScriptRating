# Age Rating Workflow Refactor

This document summarises the end-to-end flow that was introduced for document ingestion, RAG indexing and block-level script assessment.

## 1. Document ingestion
- API endpoint `POST /api/v1/documents/upload` now accepts a `document_type` (`script` or `criteria`) along with the uploaded file.
- Criteria (legal) documents are parsed with the new file-system parser and split into paragraphs that are indexed inside the in-memory knowledge base (TF-IDF vector store).
- Script documents are parsed into `RawScript` entities and stored inside the new `ScriptStore` so that subsequent analysis requests have access to the extracted text and paragraph metadata.

## 2. Knowledge base
- `KnowledgeBase` maintains paragraph-level entries with page and paragraph numbers. It rebuilds the TF-IDF index every time a document is (re)ingested.
- Queries performed during analysis return top-ranked normative excerpts that are embedded into the analysis response as references.

## 3. Analysis orchestration
- `AnalysisManager` coordinates segmentation, category detection, heuristic age rating and recommendation building.
- Scripts are split into semantic blocks (~160 words) while preserving the original page range.
- Each block is evaluated against keyword heuristics to determine category severities and the corresponding per-block age rating.
- RAG lookups are performed after every block to attach normative references (page, paragraph, excerpt) for the GUI and final report.
- The manager exposes incremental progress through `GET /api/v1/analysis/status/{analysis_id}` so the front-end can update a progress bar and append new blocks in real time.

## 4. Front-end experience
- The Flutter upload screen distinguishes between normative documents and scripts, showing upload progress and chunk count for indexed criteria files.
- The analysis screen polls the backend status endpoint, renders processed blocks on the fly, and navigates to the results screen when processing completes.
- Scene widgets now display block age rating, heuristic commentary and the list of normative references returned by the backend.
- Each scene block additionally includes the verbatim text plus highlight fragments returned by the backend; the GUI renders those spans with severity-based colors so editors can immediately see which phrases triggered the assigned rating.

## 5. Testing
- `tests/test_analysis_workflow.py` covers the happy path: it uploads a synthetic legal document and script, starts the analysis, polls the status endpoint, and asserts that references and ratings are produced.
- `tests/test_openrouter_endpoints.py` stubs the OpenRouter client to validate the real HTTP integration without hitting the public API.

## 6. Configuration
- Backend reads OpenRouter credentials from environment variables (`OPENROUTER_API_KEY`, `OPENROUTER_BASE_URL`, `OPENROUTER_REFERER`, `OPENROUTER_APP_NAME`, `OPENROUTER_TIMEOUT`).
- Without an API key, OpenRouter endpoints stay available but report `connected = false`, allowing the UI to inform the user without breaking other LLM features.

These changes ensure that every analysed block is backed by explicit references to the legal criteria used during the decision, satisfying the traceability requirement for age-rating justification.
