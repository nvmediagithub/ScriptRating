# Comprehensive RAG Testing Plan for ScriptRating System

## Overview

**Testing Objective**: Verify the correct operation of implemented RAG system improvements in ScriptRating.

**Target System**: RAG services including RAGOrchestrator, EmbeddingService, VectorDatabaseService, and API endpoints.

**Testing Environment**: 
- Backend: FastAPI-based RAG system
- Database: Qdrant vector database
- Cache: Redis
- External APIs: OpenAI Embeddings
- Fallback: Local Sentence Transformers, TF-IDF

---

## 1. Backend API Testing

### 1.1 RAG API Endpoints Testing

#### 1.1.1 RAG Query Endpoint (`POST /rag/query`)

**Test Case: API-TEST-001 - Basic Query Operation**
- **Description**: Test basic RAG query functionality
- **Preconditions**: RAG system initialized with sample corpus
- **Test Steps**:
  1. Send POST request to `/rag/query` with valid query
  2. Verify response structure matches RAGQueryResponse schema
  3. Check that results contain required fields: content, relevance_score, source, category
- **Expected Result**: 
  - HTTP 200 status
  - Valid JSON response with search results
  - Results ordered by relevance score
- **Pass Criteria**: Response time < 5 seconds, results contain relevant content
- **Automation**: Unit test with API mock

**Test Case: API-TEST-002 - Query with Category Filter**
- **Description**: Test RAG query with category filtering
- **Test Steps**:
  1. Send query with specific category (VIOLENCE, LANGUAGE, SEXUAL_CONTENT, etc.)
  2. Verify results are filtered by category
- **Expected Result**: All returned results match specified category
- **Pass Criteria**: 100% category filtering accuracy

**Test Case: API-TEST-003 - Query with Score Threshold**
- **Description**: Test query with minimum relevance score
- **Test Steps**:
  1. Send query with score_threshold=0.8
  2. Verify all results have score >= 0.8
- **Expected Result**: Only high-relevance results returned
- **Pass Criteria**: All results meet threshold requirement

**Test Case: API-TEST-004 - Invalid Query Handling**
- **Description**: Test error handling for invalid queries
- **Test Steps**:
  1. Send query with empty text
  2. Send query with excessive length (>10000 chars)
  3. Send malformed JSON request
- **Expected Result**: Appropriate HTTP error responses (400/422)
- **Pass Criteria**: Proper error messages and status codes

#### 1.1.2 Corpus Management Endpoints

**Test Case: API-TEST-005 - Update Corpus**
- **Description**: Test corpus document addition
- **Test Steps**:
  1. Send POST request to `/rag/corpus/update` with new document
  2. Verify document is added to corpus
  3. Check response contains update_id and content_hash
- **Expected Result**: Document successfully added with unique ID
- **Pass Criteria**: Corpus size increases by 1

**Test Case: API-TEST-006 - List Corpus Documents**
- **Description**: Test corpus listing with pagination
- **Test Steps**:
  1. Send GET request to `/rag/corpus` with limit parameter
  2. Verify pagination works correctly
  3. Test category filtering in list
- **Expected Result**: Proper pagination, filtering works
- **Pass Criteria**: Consistent with corpus data

**Test Case: API-TEST-007 - Get/Delete Corpus Document**
- **Description**: Test individual document operations
- **Test Steps**:
  1. Get document by ID via `/rag/corpus/{document_id}`
  2. Delete document via `/rag/corpus/{document_id}`
  3. Verify document is removed
- **Expected Result**: Document operations succeed
- **Pass Criteria**: CRUD operations work correctly

#### 1.1.3 Health and Metrics Endpoints

**Test Case: API-TEST-008 - Health Check**
- **Description**: Test RAG system health endpoint
- **Test Steps**:
  1. Send GET request to `/rag/health`
  2. Check status of all components
  3. Verify response structure
- **Expected Result**: Component health status reported
- **Pass Criteria**: Accurate health assessment

**Test Case: API-TEST-009 - Metrics Collection**
- **Description**: Test metrics endpoint functionality
- **Test Steps**:
  1. Send GET request to `/rag/metrics`
  2. Verify metrics data is present
  3. Check metrics accuracy
- **Expected Result**: Comprehensive metrics data
- **Pass Criteria**: Metrics reflect actual system state

### 1.2 EmbeddingService API Testing

**Test Case: API-TEST-010 - Embedding Generation**
- **Description**: Test single text embedding
- **Preconditions**: OpenAI API key configured
- **Test Steps**:
  1. Call EmbeddingService.embed_text() with sample text
  2. Verify embedding vector dimensions (1536 for text-embedding-3-large)
  3. Check model field is correctly set
- **Expected Result**: Valid embedding vector returned
- **Pass Criteria**: Correct dimensions and semantic similarity

**Test Case: API-TEST-011 - Batch Embedding**
- **Description**: Test batch embedding processing
- **Test Steps**:
  1. Call EmbeddingService.embed_batch() with multiple texts
  2. Verify batch processing efficiency
  3. Check cache utilization
- **Expected Result**: All texts embedded successfully
- **Pass Criteria**: Batch processing works, cache hits recorded

**Test Case: API-TEST-012 - Fallback Mechanism**
- **Description**: Test fallback to local model
- **Test Steps**:
  1. Disable OpenAI API temporarily
  2. Attempt embedding generation
  3. Verify fallback to sentence-transformers
- **Expected Result**: Fallback model generates embeddings
- **Pass Criteria**: Fallback activates without errors

---

## 2. Service Integration Testing

### 2.1 External Service Connections

**Test Case: INT-TEST-001 - OpenAI Integration**
- **Description**: Test connection to OpenAI Embeddings API
- **Preconditions**: Valid OpenAI API key in environment
- **Test Steps**:
  1. Initialize EmbeddingService with API key
  2. Test connection via health_check()
  3. Generate test embedding
- **Expected Result**: Successful API communication
- **Pass Criteria**: Response time < 10 seconds, valid embeddings

**Test Case: INT-TEST-002 - Redis Connection**
- **Description**: Test Redis cache connection
- **Preconditions**: Redis server running
- **Test Steps**:
  1. Initialize EmbeddingService with Redis URL
  2. Store and retrieve cached embedding
  3. Test TTL functionality
- **Expected Result**: Cache operations succeed
- **Pass Criteria**: Cache hit rate increases, TTL respected

**Test Case: INT-TEST-003 - Qdrant Database**
- **Description**: Test Qdrant vector database connection
- **Preconditions**: Qdrant server running
- **Test Steps**:
  1. Initialize VectorDatabaseService
  2. Create collection if needed
  3. Upsert test documents
  4. Perform search
- **Expected Result**: Vector operations work
- **Pass Criteria**: Documents indexed, search returns results

### 2.2 Configuration Loading

**Test Case: INT-TEST-004 - RAG Configuration**
- **Description**: Test RAG configuration loading
- **Test Steps**:
  1. Load RAGConfig from environment variables
  2. Verify all configuration values
  3. Test configuration validation
- **Expected Result**: Configuration loaded correctly
- **Pass Criteria**: All settings match environment values

**Test Case: INT-TEST-005 - Service Factory**
- **Description**: Test RAG service factory initialization
- **Test Steps**:
  1. Initialize services via factory
  2. Verify dependency injection
  3. Test service health
- **Expected Result**: All services initialized
- **Pass Criteria**: Factory pattern works correctly

### 2.3 Error Handling and Fallbacks

**Test Case: INT-TEST-006 - OpenAI API Failure**
- **Description**: Test graceful handling of OpenAI API failure
- **Test Steps**:
  1. Disable OpenAI API (simulate failure)
  2. Attempt embedding generation
  3. Verify fallback activation
- **Expected Result**: System continues with fallback
- **Pass Criteria**: No crashes, graceful degradation

**Test Case: INT-TEST-007 - Database Unavailability**
- **Description**: Test system behavior when Qdrant unavailable
- **Test Steps**:
  1. Stop Qdrant service
  2. Attempt vector operations
  3. Verify error handling
- **Expected Result**: Appropriate error responses
- **Pass Criteria**: Clean error handling, no system crashes

---

## 3. RAG Storage Testing

### 3.1 Vector Storage Operations

**Test Case: STORAGE-TEST-001 - Document Indexing**
- **Description**: Test document indexing in vector database
- **Test Steps**:
  1. Create RAGDocument objects
  2. Index via RAGOrchestrator.index_document()
  3. Verify documents appear in search results
- **Expected Result**: Documents successfully indexed
- **Pass Criteria**: Index count increases, searchable

**Test Case: STORAGE-TEST-002 - Batch Indexing**
- **Description**: Test batch document processing
- **Test Steps**:
  1. Prepare batch of 100 documents
  2. Index via index_documents_batch()
  3. Verify all documents indexed
- **Expected Result**: Batch processing completes
- **Pass Criteria**: All documents indexed successfully

**Test Case: STORAGE-TEST-003 - Metadata Handling**
- **Description**: Test metadata storage and retrieval
- **Test Steps**:
  1. Index documents with rich metadata
  2. Search with metadata filters
  3. Verify metadata preserved
- **Expected Result**: Metadata properly stored and filtered
- **Pass Criteria**: Metadata accuracy 100%

### 3.2 Embedding Quality Testing

**Test Case: STORAGE-TEST-004 - Embedding Dimensions**
- **Description**: Verify embedding vector dimensions
- **Test Steps**:
  1. Generate embeddings for various texts
  2. Check vector dimensions
  3. Verify consistency across texts
- **Expected Result**: All embeddings have correct dimensions
- **Pass Criteria**: 1536 dimensions for OpenAI model

**Test Case: STORAGE-TEST-005 - Semantic Similarity**
- **Description**: Test embedding semantic quality
- **Test Steps**:
  1. Create semantically similar text pairs
  2. Generate embeddings
  3. Calculate cosine similarity
- **Expected Result**: Similar texts have high similarity scores
- **Pass Criteria**: Similarity scores > 0.8 for related texts

### 3.3 Hybrid Search Testing

**Test Case: STORAGE-TEST-006 - Vector Search**
- **Description**: Test vector similarity search
- **Test Steps**:
  1. Index diverse documents
  2. Perform vector search queries
  3. Verify result relevance
- **Expected Result**: Relevant results returned
- **Pass Criteria**: Semantic relevance scoring works

**Test Case: STORAGE-TEST-007 - TF-IDF Fallback**
- **Description**: Test TF-IDF fallback search
- **Test Steps**:
  1. Index documents in system
  2. Simulate vector search failure
  3. Verify TF-IDF fallback activates
- **Expected Result**: TF-IDF search provides results
- **Pass Criteria**: Fallback search returns results

**Test Case: STORAGE-TEST-008 - Hybrid Scoring**
- **Description**: Test hybrid search scoring combination
- **Test Steps**:
  1. Configure hybrid search weights
  2. Perform hybrid searches
  3. Verify combined scoring
- **Expected Result**: Weighted scoring applied
- **PassCriteria**: Combined scores reflect configured weights

---

## 4. End-to-End Testing

### 4.1 Complete RAG Workflow

**Test Case: E2E-TEST-001 - Full Document Analysis Workflow**
- **Description**: Test complete document ingestion and analysis
- **Preconditions**: All services running, test documents prepared
- **Test Steps**:
  1. Upload document to system
  2. Trigger RAG indexing
  3. Perform RAG queries for analysis
  4. Verify analysis results include RAG citations
- **Expected Result**: Complete workflow functions end-to-end
- **Pass Criteria**: Analysis includes relevant RAG references

**Test Case: E2E-TEST-002 - Multi-document Corpus Building**
- **Description**: Test building comprehensive RAG corpus
- **Test Steps**:
  1. Add documents from multiple categories
  2. Build diverse corpus
  3. Test queries across categories
  4. Verify cross-category search works
- **Expected Result**: Rich, searchable corpus built
- **Pass Criteria**: Diverse content searchable

### 4.2 User Workflow Integration

**Test Case: E2E-TEST-003 - Script Analysis with RAG**
- **Description**: Test script analysis enhanced with RAG
- **Test Steps**:
  1. Upload script for analysis
  2. Run analysis with RAG enabled
  3. Verify results include RAG citations
  4. Check reference accuracy
- **Expected Result**: Analysis enriched with legal references
- **Pass Criteria**: RAG citations accurate and relevant

**Test Case: E2E-TEST-004 - Real-time RAG Updates**
- **Description**: Test dynamic corpus updates during operation
- **Test Steps**:
  1. Start analysis process
  2. Add new documents to corpus
  3. Verify new documents searchable immediately
- **Expected Result**: Dynamic updates work seamlessly
- **Pass Criteria**: New content immediately searchable

---

## 5. Performance Testing

### 5.1 Response Time Testing

**Test Case: PERF-TEST-001 - Query Response Time**
- **Description**: Test RAG query response times
- **Test Steps**:
  1. Measure response time for various queries
  2. Test under different corpus sizes
  3. Monitor timeout handling
- **Expected Result**: Response times meet SLA requirements
- **Pass Criteria**: Average response < 2 seconds, 95th percentile < 5 seconds

**Test Case: PERF-TEST-002 - Indexing Performance**
- **Description**: Test document indexing speed
- **Test Steps**:
  1. Time document indexing operations
  2. Test batch indexing efficiency
  3. Measure memory usage during indexing
- **Expected Result**: Indexing completes efficiently
- **Pass Criteria**: 100 documents indexed in < 30 seconds

### 5.2 Load Testing

**Test Case: PERF-TEST-003 - Concurrent Query Handling**
- **Description**: Test system under concurrent query load
- **Test Steps**:
  1. Generate 100 concurrent queries
  2. Monitor system performance
  3. Verify no degradation
- **Expected Result**: System handles load gracefully
- **Pass Criteria**: No error rate increase, acceptable response times

**Test Case: PERF-TEST-004 - Memory Usage**
- **Description**: Test memory consumption under load
- **Test Steps**:
  1. Monitor memory usage during operation
  2. Test with large document corpus
  3. Verify memory cleanup
- **Expected Result**: Memory usage stays within limits
- **Pass Criteria**: Memory usage < 80% of available, no leaks

### 5.3 Caching Performance

**Test Case: PERF-TEST-005 - Cache Effectiveness**
- **Description**: Test embedding cache performance
- **Test Steps**:
  1. Measure cache hit rates
  2. Test cache size limits
  3. Verify TTL expiration
- **Expected Result**: Caching improves performance significantly
- **Pass Criteria**: Cache hit rate > 70% after warm-up, 50% reduction in response time

**Test Case: PERF-TEST-006 - Database Performance**
- **Description**: Test Qdrant search performance
- **Test Steps**:
  1. Index large document corpus
  2. Measure search performance
  3. Test different top_k values
- **Expected Result**: Search performance scales well
- **Pass Criteria**: Search time < 100ms for 10k documents

---

## 6. GUI Integration Testing

### 6.1 Frontend RAG Features

**Test Case: GUI-TEST-001 - RAG Search UI**
- **Description**: Test RAG search interface in frontend
- **Preconditions**: Frontend application running
- **Test Steps**:
  1. Access RAG search interface
  2. Enter test queries
  3. Verify results display correctly
  4. Test pagination and filtering
- **Expected Result**: Search interface works smoothly
- **Pass Criteria**: UI responsive, results display correctly

**Test Case: GUI-TEST-002 - Corpus Management UI**
- **Description**: Test corpus management interface
- **Test Steps**:
  1. Access corpus management page
  2. Add new documents
  3. View document list
  4. Edit/delete documents
- **Expected Result**: Corpus management works via UI
- **Pass Criteria**: CRUD operations work through interface

### 6.2 Error Handling in GUI

**Test Case: GUI-TEST-003 - RAG Error Display**
- **Description**: Test error handling in RAG UI components
- **Test Steps**:
  1. Simulate RAG service errors
  2. Verify appropriate error messages
  3. Test fallback UI behavior
- **Expected Result**: Errors handled gracefully in UI
- **Pass Criteria**: User-friendly error messages, no crashes

**Test Case: GUI-TEST-004 - Loading States**
- **Description**: Test loading indicators for RAG operations
- **Test Steps**:
  1. Perform long-running RAG operations
  2. Verify loading states display
  3. Test timeout handling
- **Expected Result**: Loading states work correctly
- **Pass Criteria**: Clear feedback during operations

---

## Testing Methods and Tools

### 6.1 Automated Testing

**Unit Tests**:
- `pytest` for service unit tests
- FastAPI test client for API testing
- Mock external services for isolated testing

**Integration Tests**:
- Docker compose for full system testing
- Test containers for database services
- Network simulation for failure testing

**Performance Tests**:
- `locust` for load testing
- Custom benchmarking scripts
- Memory profiling with `memory_profiler`

### 6.2 Manual Testing

**Exploratory Testing**:
- UI/UX testing with real browsers
- Edge case identification
- User workflow validation

**Acceptance Testing**:
- Business requirement validation
- Performance criterion verification
- Cross-browser compatibility

### 6.3 Testing Tools

**API Testing**:
- `curl` for manual API testing
- `httpie` for formatted API requests
- Postman collections for regression testing

**Monitoring**:
- Prometheus metrics collection
- Grafana dashboards for visualization
- Log aggregation with structured logging

**Data Validation**:
- Embedding similarity testing with `numpy`
- Corpus consistency validation scripts
- Search result accuracy measurement

---

## Success Criteria

### 7.1 Functional Criteria

**Core Functionality**:
- ✅ RAG queries return relevant results (>80% relevance score)
- ✅ Document indexing works correctly (100% success rate)
- ✅ Corpus management operations function properly
- ✅ Health checks report accurate system status

**Integration Quality**:
- ✅ External service integrations stable
- ✅ Configuration loading works correctly
- ✅ Error handling graceful across all components
- ✅ Fallback mechanisms activate properly

### 7.2 Performance Criteria

**Response Times**:
- ✅ RAG query response < 2 seconds (average)
- ✅ Document indexing < 0.3 seconds per document
- ✅ Health check response < 500ms
- ✅ API response times within SLA

**Scalability**:
- ✅ System handles 100 concurrent queries
- ✅ Memory usage < 80% under normal load
- ✅ Cache hit rate > 70% after warm-up
- ✅ Database search performance < 100ms for 10k documents

### 7.3 Quality Criteria

**Code Quality**:
- ✅ Unit test coverage > 90%
- ✅ Integration test coverage > 80%
- ✅ No critical security vulnerabilities
- ✅ Proper error logging and monitoring

**User Experience**:
- ✅ GUI responsive and intuitive
- ✅ Error messages clear and actionable
- ✅ Loading states provide appropriate feedback
- ✅ System behavior predictable under all conditions

---

## Issue Resolution Plan

### 8.1 Issue Classification

**Critical Issues** (P0):
- Data loss or corruption
- Security vulnerabilities
- System crashes or instability
- Complete feature failure

**High Priority Issues** (P1):
- Performance below SLA
- Integration failures
- Core functionality problems
- User experience degradation

**Medium Priority Issues** (P2):
- Minor performance issues
- UI/UX improvements
- Documentation gaps
- Enhancement requests

**Low Priority Issues** (P3):
- Cosmetic issues
- Feature suggestions
- Optimization opportunities
- Documentation improvements

### 8.2 Resolution Workflow

**Phase 1: Issue Identification**
1. Automated test failures trigger alerts
2. Manual testing reveals issues
3. User feedback indicates problems
4. Monitoring detects anomalies

**Phase 2: Issue Analysis**
1. Reproduce issue in test environment
2. Analyze logs and metrics
3. Identify root cause
4. Assess impact and priority

**Phase 3: Fix Implementation**
1. Develop fix for root cause
2. Add regression tests
3. Test fix in isolation
4. Deploy to staging environment

**Phase 4: Validation**
1. Run full test suite
2. Perform manual validation
3. Monitor production metrics
4. Close issue with documentation

### 8.3 Rollback Procedures

**Immediate Rollback Triggers**:
- Critical performance degradation (>50% slowdown)
- Data corruption or loss
- Security incidents
- System instability

**Rollback Process**:
1. Activate previous stable version
2. Verify system functionality
3. Monitor for stability
4. Plan fix for next release

**Recovery Procedures**:
1. Analyze rollback impact
2. Restore any lost data
3. Update user communications
4. Schedule fix deployment

---

## Test Environment Setup

### 9.1 Infrastructure Requirements

**Development Environment**:
- Local Docker compose setup
- Mock external services
- Sample data corpus
- Automated test execution

**Testing Environment**:
- Dedicated test servers
- Isolated database instances
- Test API keys and credentials
- Monitoring and logging

**Staging Environment**:
- Production-like setup
- Full service integration
- Performance testing capability
- User acceptance testing

### 9.2 Test Data Management

**Sample Corpus**:
- 100+ legal documents in Russian
- Mixed content categories (VIOLENCE, LANGUAGE, SEXUAL_CONTENT)
- Various document types and formats
- Metadata for filtering and testing

**Query Test Cases**:
- 50+ representative queries
- Edge cases and error conditions
- Performance benchmark queries
- Multilingual content tests

### 9.3 Environment Configuration

**Required Variables**:
```bash
# OpenAI Configuration
OPENAI_EMBEDDING_API_KEY=sk-...
OPENAI_EMBEDDING_MODEL=text-embedding-3-large

# Redis Configuration
REDIS_URL=redis://localhost:6379
REDIS_MAX_CONNECTIONS=10

# Qdrant Configuration
QDRANT_URL=http://localhost:6333
QDRANT_API_KEY=optional_api_key
QDRANT_COLLECTION_NAME=scriptrating_documents_test

# RAG System Configuration
ENABLE_RAG_SYSTEM=true
ENABLE_EMBEDDING_CACHE=true
ENABLE_TFIDF_FALLBACK=true
ENABLE_HYBRID_SEARCH=true
RAG_SEARCH_TIMEOUT=5.0
```

---

## Reporting and Documentation

### 10.1 Test Reports

**Daily Test Reports**:
- Test execution summary
- Failed test cases with details
- Performance metrics comparison
- System health status

**Weekly Test Reports**:
- Trend analysis and improvements
- Coverage metrics update
- Issue resolution status
- Upcoming test focus areas

**Release Test Reports**:
- Complete test suite results
- Performance benchmarks
- Quality metrics summary
- Go/no-go recommendation

### 10.2 Documentation Updates

**Test Documentation**:
- Update test cases based on findings
- Maintain test data sets
- Document new test procedures
- Keep troubleshooting guides current

**System Documentation**:
- Update API documentation
- Maintain configuration guides
- Document known issues and workarounds
- Update deployment procedures

---

## Conclusion

This comprehensive testing plan ensures thorough validation of the RAG system improvements in ScriptRating. The plan covers all critical aspects of the system through systematic testing approaches, clear success criteria, and structured issue resolution procedures.

The testing strategy balances automated efficiency with manual validation, ensuring both technical correctness and user experience quality. Regular reporting and documentation updates will maintain transparency and support continuous improvement of the RAG system.

**Key Success Factors**:
- Complete test coverage across all system components
- Automated testing for rapid feedback and regression prevention
- Performance validation to ensure production readiness
- User-focused testing to validate practical value
- Structured issue resolution for rapid problem resolution

This plan provides a robust framework for validating the RAG system improvements while maintaining high quality standards and supporting the overall reliability of the ScriptRating platform.