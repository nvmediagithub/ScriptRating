"""
RAG Service Factory.

This module provides factory functions to create and initialize RAG services
based on configuration.
"""
import logging
from typing import Optional, Tuple

from app.config.rag_config import get_rag_config, RAGConfig
from app.infrastructure.services.embedding_service import EmbeddingService
from app.infrastructure.services.vector_database_service import VectorDatabaseService
from app.infrastructure.services.knowledge_base import KnowledgeBase
from app.domain.services.rag_orchestrator import RAGOrchestrator

logger = logging.getLogger(__name__)


class RAGServiceFactory:
    """Factory for creating and managing RAG services."""
    
    _embedding_service: Optional[EmbeddingService] = None
    _vector_db_service: Optional[VectorDatabaseService] = None
    _rag_orchestrator: Optional[RAGOrchestrator] = None
    _knowledge_base: Optional[KnowledgeBase] = None
    _initialized: bool = False
    
    @classmethod
    async def create_services(
        cls,
        config: Optional[RAGConfig] = None,
    ) -> Tuple[
        Optional[EmbeddingService],
        Optional[VectorDatabaseService],
        Optional[RAGOrchestrator],
        KnowledgeBase,
    ]:
        """
        Create all RAG services based on configuration.
        
        Args:
            config: Optional RAG configuration (uses default if None)
            
        Returns:
            Tuple of (EmbeddingService, VectorDatabaseService, RAGOrchestrator, KnowledgeBase)
        """
        if config is None:
            config = get_rag_config()
        
        logger.info("Creating RAG services...")
        
        # Create embedding service if enabled
        embedding_service = None
        if config.is_rag_enabled():
            embedding_config = config.get_embedding_config()
            embedding_service = EmbeddingService(
                openrouter_api_key=embedding_config["openrouter_api_key"],
                openai_api_key=embedding_config["openai_api_key"],
                redis_url=embedding_config["redis_url"],
                cache_ttl=embedding_config["cache_ttl"],
                batch_size=embedding_config["batch_size"],
                embedding_timeout=embedding_config["embedding_timeout"],
                primary_provider=embedding_config["primary_provider"],
            )
            logger.info("✅ EmbeddingService created with OpenRouter integration")
        
        # Create vector database service if enabled
        vector_db_service = None
        if config.is_vector_db_enabled():
            vector_db_service = VectorDatabaseService(
                qdrant_url=config.qdrant_url,
                qdrant_api_key=config.qdrant_api_key,
                collection_name=config.qdrant_collection_name,
                vector_size=config.qdrant_vector_size,
                distance_metric=config.qdrant_distance_metric,
                replication_factor=config.qdrant_replication_factor,
                write_consistency_factor=config.qdrant_write_consistency_factor,
                on_disk_payload=config.qdrant_on_disk_payload,
                hnsw_config_m=config.qdrant_hnsw_config_m,
                hnsw_config_ef_construct=config.qdrant_hnsw_config_ef_construct,
                timeout=config.qdrant_timeout,
                enable_tfidf_fallback=config.enable_tfidf_fallback,
            )
            logger.info("VectorDatabaseService created with Qdrant optimization settings")
        
        # Create RAG orchestrator if both services are available
        rag_orchestrator = None
        if embedding_service and vector_db_service:
            rag_orchestrator = RAGOrchestrator(
                embedding_service=embedding_service,
                vector_db_service=vector_db_service,
                enable_hybrid_search=config.enable_hybrid_search,
                search_timeout=config.rag_search_timeout,
            )
            logger.info("RAGOrchestrator created")
        
        # Create knowledge base with optional RAG integration
        knowledge_base = KnowledgeBase(
            rag_orchestrator=rag_orchestrator,
            use_rag_when_available=config.enable_rag_system,
        )
        logger.info("KnowledgeBase created")
        
        # Store references
        cls._embedding_service = embedding_service
        cls._vector_db_service = vector_db_service
        cls._rag_orchestrator = rag_orchestrator
        cls._knowledge_base = knowledge_base
        
        return embedding_service, vector_db_service, rag_orchestrator, knowledge_base
    
    @classmethod
    async def initialize_services(
        cls,
        config: Optional[RAGConfig] = None,
    ) -> KnowledgeBase:
        """
        Create and initialize all RAG services.
        
        Args:
            config: Optional RAG configuration
            
        Returns:
            Initialized KnowledgeBase
        """
        if cls._initialized:
            logger.warning("RAG services already initialized")
            return cls._knowledge_base
        
        # Create services
        embedding_service, vector_db_service, rag_orchestrator, knowledge_base = \
            await cls.create_services(config)
        
        # Initialize services
        try:
            if embedding_service:
                await embedding_service.initialize()
                logger.info("EmbeddingService initialized")
            
            if vector_db_service:
                await vector_db_service.initialize()
                logger.info("VectorDatabaseService initialized")
            
            if rag_orchestrator:
                # Services already initialized, just mark orchestrator
                rag_orchestrator._initialized = True
                logger.info("RAGOrchestrator initialized")
            
            if knowledge_base:
                await knowledge_base.initialize()
                logger.info("KnowledgeBase initialized")
            
            cls._initialized = True
            logger.info("All RAG services initialized successfully")
            
        except Exception as e:
            logger.error(f"Error initializing RAG services: {e}")
            # Continue with partial initialization (graceful degradation)
            cls._initialized = True
        
        return knowledge_base
    
    @classmethod
    async def shutdown_services(cls) -> None:
        """Shutdown all RAG services."""
        logger.info("Shutting down RAG services...")
        
        if cls._rag_orchestrator:
            await cls._rag_orchestrator.close()
            cls._rag_orchestrator = None
        
        if cls._embedding_service:
            await cls._embedding_service.close()
            cls._embedding_service = None
        
        if cls._vector_db_service:
            await cls._vector_db_service.close()
            cls._vector_db_service = None
        
        cls._knowledge_base = None
        cls._initialized = False
        
        logger.info("All RAG services shut down")
    
    @classmethod
    def get_embedding_service(cls) -> Optional[EmbeddingService]:
        """Get the embedding service instance."""
        return cls._embedding_service
    
    @classmethod
    def get_vector_db_service(cls) -> Optional[VectorDatabaseService]:
        """Get the vector database service instance."""
        return cls._vector_db_service
    
    @classmethod
    def get_rag_orchestrator(cls) -> Optional[RAGOrchestrator]:
        """Get the RAG orchestrator instance."""
        return cls._rag_orchestrator
    
    @classmethod
    def get_knowledge_base(cls) -> Optional[KnowledgeBase]:
        """Get the knowledge base instance."""
        return cls._knowledge_base
    
    @classmethod
    def is_initialized(cls) -> bool:
        """Check if services are initialized."""
        return cls._initialized