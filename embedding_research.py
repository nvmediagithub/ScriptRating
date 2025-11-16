#!/usr/bin/env python3
"""
Скрипт для исследования бесплатных альтернатив OpenAI для embeddings.
"""
import asyncio
import json
import logging
from typing import List, Dict, Any, Optional
import httpx

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class EmbeddingResearcher:
    """Исследователь бесплатных альтернатив для embeddings."""
    
    def __init__(self):
        self.free_models = []
        self.openrouter_embedding_models = []
        self.huggingface_models = [
            "sentence-transformers/all-MiniLM-L6-v2",
            "sentence-transformers/all-MiniLM-L12-v2", 
            "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
            "sentence-transformers/paraphrase-multilingual-MiniLM-L12-v2",
            "jina-embeddings-v2-base-code",
            "intfloat/multilingual-e5-large",
            "intfloat/e5-large",
            "sentence-transformers/msmarco-distilbert-base-tas-b",
            "sentence-transformers/distiluse-base-multilingual-cased"
        ]
        
    async def get_openrouter_models(self) -> List[Dict[str, Any]]:
        """Получить список моделей OpenRouter."""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.get(
                    "https://openrouter.ai/api/v1/models",
                    headers={"Authorization": "Bearer demo"}
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return data.get("data", [])
                else:
                    logger.error(f"Ошибка получения моделей: {response.status_code}")
                    return []
        except Exception as e:
            logger.error(f"Ошибка при получении моделей OpenRouter: {e}")
            return []
    
    def identify_embedding_models(self, models: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Определить embedding модели среди общего списка."""
        embedding_keywords = [
            'embedding', 'embed', 'vector', 'sentence', 'similarity',
            'text-embedding', 'cohere', 'voyage', 'mistral', 'bge', 'e5'
        ]
        
        embedding_models = []
        
        for model in models:
            model_id = model.get("id", "").lower()
            name = model.get("name", "").lower()
            description = model.get("description", "").lower()
            
            # Проверяем на ключевые слова embedding
            if any(keyword in model_id or keyword in name or keyword in description 
                   for keyword in embedding_keywords):
                embedding_models.append(model)
        
        return embedding_models
    
    def analyze_free_models(self, models: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """Анализ бесплатных моделей."""
        free_models = []
        
        for model in models:
            pricing = model.get("pricing", {})
            prompt_price = pricing.get("prompt", "0")
            completion_price = pricing.get("completion", "0")
            
            # Считаем модель бесплатной, если цена 0
            if prompt_price == "0" and completion_price == "0":
                free_models.append({
                    "id": model.get("id"),
                    "name": model.get("name"),
                    "description": model.get("description"),
                    "context_length": model.get("context_length"),
                    "pricing": pricing,
                    "architecture": model.get("architecture", {}),
                    "top_provider": model.get("top_provider", {})
                })
        
        return free_models
    
    async def test_huggingface_api(self, model_name: str) -> Dict[str, Any]:
        """Тестирование модели HuggingFace."""
        result = {
            "model": model_name,
            "available": False,
            "error": None,
            "embedding_dim": None
        }
        
        try:
            # Проверяем доступность модели
            api_url = f"https://api-inference.huggingface.co/pipeline/feature-extraction/{model_name}"
            
            async with httpx.AsyncClient(timeout=30.0) as client:
                # Тестовый запрос
                response = await client.post(
                    api_url,
                    json={"inputs": "test sentence"},
                    headers={"Authorization": f"Bearer {os.getenv('HUGGINGFACE_API_TOKEN', '')}"}
                )
                
                if response.status_code == 200:
                    result["available"] = True
                    result["embedding_dim"] = len(response.json()[0]) if response.json() else None
                else:
                    result["error"] = f"HTTP {response.status_code}: {response.text}"
                    
        except Exception as e:
            result["error"] = str(e)
            
        return result
    
    async def research_cohere_embeddings(self) -> Dict[str, Any]:
        """Исследование Cohere embeddings."""
        try:
            async with httpx.AsyncClient(timeout=30.0) as client:
                response = await client.post(
                    "https://api.cohere.ai/v1/embed",
                    headers={
                        "Authorization": f"Bearer {os.getenv('COHERE_API_KEY', '')}",
                        "Content-Type": "application/json"
                    },
                    json={
                        "texts": ["Hello world"],
                        "model": "embed-multilingual-v3.0"
                    }
                )
                
                if response.status_code == 200:
                    data = response.json()
                    return {
                        "available": True,
                        "model": "embed-multilingual-v3.0",
                        "embedding_dim": len(data.get("embeddings", [{}])[0].get("embedding", [])),
                        "free_tier": True
                    }
                else:
                    return {
                        "available": False,
                        "error": f"HTTP {response.status_code}: {response.text}",
                        "model": "embed-multilingual-v3.0"
                    }
                    
        except Exception as e:
            return {
                "available": False,
                "error": str(e),
                "model": "embed-multilingual-v3.0"
            }
    
    async def test_local_models(self) -> Dict[str, Any]:
        """Тестирование локальных моделей sentence-transformers."""
        results = {}
        
        for model_name in self.huggingface_models:
            result = {
                "model": model_name,
                "loadable": False,
                "error": None,
                "embedding_dim": None,
                "memory_usage": None
            }
            
            try:
                # Пытаемся импортировать и загрузить модель
                import torch
                from sentence_transformers import SentenceTransformer
                
                # Загружаем модель
                model = SentenceTransformer(model_name)
                
                # Тестируем генерацию embedding
                test_embedding = model.encode(["test sentence"])
                
                result["loadable"] = True
                result["embedding_dim"] = test_embedding.shape[1]
                result["device"] = str(next(model.parameters()).device)
                
                # Оценка использования памяти (примерная)
                total_params = sum(p.numel() for p in model.parameters())
                result["memory_usage_mb"] = total_params * 4 / (1024 * 1024)  # Примерная оценка
                
            except Exception as e:
                result["error"] = str(e)
            
            results[model_name] = result
            
        return results
    
    def generate_report(self, openrouter_models: List[Dict[str, Any]], 
                       free_models: List[Dict[str, Any]], 
                       embedding_models: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Генерация отчета об исследовании."""
        return {
            "total_openrouter_models": len(openrouter_models),
            "free_openrouter_models": len(free_models),
            "embedding_models_found": len(embedding_models),
            "free_embedding_models": [m for m in free_models if m in embedding_models],
            "recommendations": {
                "best_free_option": "sentence-transformers/all-MiniLM-L6-v2",
                "best_multilingual": "sentence-transformers/paraphrase-multilingual-mpnet-base-v2",
                "best_code_model": "jina-embeddings-v2-base-code",
                "best_api_option": "OpenRouter с бесплатными моделями",
                "fallback_strategy": "Local sentence-transformers -> OpenRouter -> Mock"
            },
            "implementation_plan": {
                "1_add_openrouter_embeddings": "Добавить поддержку OpenRouter embeddings API",
                "2_fix_sentence_transformers": "Исправить реальную загрузку локальных моделей",
                "3_add_huggingface_fallback": "Добавить HuggingFace Inference API",
                "4_implement_fallback_chain": "Создать цепочку fallback'ов",
                "5_test_all_solutions": "Протестировать все решения"
            }
        }


async def main():
    """Главная функция исследования."""
    researcher = EmbeddingResearcher()
    
    print("🔍 Начинаю исследование бесплатных альтернатив для embeddings...\n")
    
    # 1. Исследуем OpenRouter
    print("1️⃣ Анализ OpenRouter моделей...")
    openrouter_models = await researcher.get_openrouter_models()
    embedding_models = researcher.identify_embedding_models(openrouter_models)
    free_models = researcher.analyze_free_models(openrouter_models)
    
    print(f"   📊 Найдено {len(openrouter_models)} моделей в OpenRouter")
    print(f"   🎯 Найдено {len(embedding_models)} возможных embedding моделей")
    print(f"   🆓 Найдено {len(free_models)} бесплатных моделей\n")
    
    # 2. Тестируем локальные модели
    print("2️⃣ Тестирование локальных моделей sentence-transformers...")
    local_results = await researcher.test_local_models()
    
    working_local = [model for model, result in local_results.items() if result["loadable"]]
    print(f"   ✅ Работают локально: {len(working_local)} моделей")
    for model in working_local:
        result = local_results[model]
        print(f"      - {model}: {result['embedding_dim']}D, ~{result.get('memory_usage_mb', 'N/A')}MB\n")
    
    # 3. Исследуем Cohere
    print("3️⃣ Исследование Cohere embeddings...")
    cohere_result = await researcher.research_cohere_embeddings()
    
    if cohere_result["available"]:
        print(f"   ✅ Cohere embed-multilingual-v3.0 доступна: {cohere_result['embedding_dim']}D")
    else:
        print(f"   ❌ Cohree недоступна: {cohere_result.get('error', 'Unknown error')}")
    print()
    
    # 4. Генерируем отчет
    print("4️⃣ Генерация финального отчета...")
    report = researcher.generate_report(openrouter_models, free_models, embedding_models)
    
    # Сохраняем отчет
    with open("embedding_research_report.json", "w", encoding="utf-8") as f:
        json.dump(report, f, ensure_ascii=False, indent=2)
    
    print("📋 Отчет сохранен в embedding_research_report.json")
    print("\n🎯 Ключевые рекомендации:")
    print(f"   - Лучшая локальная модель: {report['recommendations']['best_free_option']}")
    print(f"   - Лучшая мультиязычная: {report['recommendations']['best_multilingual']}")
    print(f"   - Лучшая для кода: {report['recommendations']['best_code_model']}")
    print(f"   - Стратегия fallback: {report['recommendations']['fallback_strategy']}")
    
    return report


if __name__ == "__main__":
    import os
    asyncio.run(main())