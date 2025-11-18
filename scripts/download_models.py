#!/usr/bin/env python3
"""
Script to download and setup local models for the RAG system.

This script downloads the necessary models for RTX 3070 8GB VRAM:
- Sentence Transformers embedding model (all-MiniLM-L6-v2)
- Local LLM models (DialoGPT models for lightweight inference)

Usage:
    python scripts/download_models.py

Requirements:
    - transformers
    - sentence-transformers
    - torch
    - accelerate
"""

import os
import sys
import logging
from pathlib import Path

# Add parent directory to path to import app modules
sys.path.insert(0, str(Path(__file__).parent.parent))

logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

def download_sentence_transformer_model(model_name: str):
    """Download SentenceTransformer model for embeddings."""
    logger.info(f"Downloading SentenceTransformer model: {model_name}")

    try:
        from sentence_transformers import SentenceTransformer
        import torch

        # Set cache directory
        cache_dir = Path.home() / ".cache" / "sentence_transformers"
        cache_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"Using cache directory: {cache_dir}")

        # Download and load model
        device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Loading model on device: {device}")

        model = SentenceTransformer(model_name, device=device, cache_folder=str(cache_dir))

        # Test the model with a simple inference
        logger.info("Testing model inference...")
        test_embedding = model.encode(["This is a test sentence for model validation."])
        logger.info(f"✅ Model loaded successfully. Embedding dimension: {len(test_embedding[0])}")

        # Clean up
        del model
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

        return True

    except Exception as e:
        logger.error(f"Failed to download/load SentenceTransformer model {model_name}: {e}")
        return False

def download_transformer_model(model_name: str):
    """Download HuggingFace transformer model."""
    logger.info(f"Downloading HuggingFace transformer model: {model_name}")

    try:
        from transformers import AutoTokenizer, AutoModelForCausalLM
        import torch

        # Set cache directory
        cache_dir = Path.home() / ".cache" / "huggingface" / "transformers"
        cache_dir.mkdir(parents=True, exist_ok=True)

        logger.info(f"Using cache directory: {cache_dir}")

        # Download tokenizer and model
        device = "cuda" if torch.cuda.is_available() else "cpu"
        logger.info(f"Loading model on device: {device}")

        # Load tokenizer
        logger.info("Loading tokenizer...")
        tokenizer = AutoTokenizer.from_pretrained(
            model_name,
            cache_dir=str(cache_dir),
            trust_remote_code=True
        )

        # Set pad token if not exists
        if tokenizer.pad_token is None:
            tokenizer.pad_token = tokenizer.eos_token

        # Load model
        logger.info("Loading model...")
        model = AutoModelForCausalLM.from_pretrained(
            model_name,
            cache_dir=str(cache_dir),
            trust_remote_code=True,
            torch_dtype=torch.float16 if torch.cuda.is_available() else torch.float32,
            device_map="auto" if torch.cuda.is_available() else None,
            low_cpu_mem_usage=True
        )

        # Test inference
        logger.info("Testing model inference...")
        input_text = "Hello, how are you?"
        inputs = tokenizer(input_text, return_tensors="pt")
        if torch.cuda.is_available():
            inputs = {k: v.cuda() for k, v in inputs.items()}

        with torch.no_grad():
            outputs = model.generate(
                **inputs,
                max_length=20,
                num_return_sequences=1,
                temperature=0.7,
                do_sample=True,
                pad_token_id=tokenizer.eos_token_id
            )

        generated_text = tokenizer.decode(outputs[0], skip_special_tokens=True)
        logger.info(f"✅ Model test successful. Generated: {generated_text[:50]}...")

        # Clean up
        del model, tokenizer
        if torch.cuda.is_available():
            torch.cuda.empty_cache()

        return True

    except Exception as e:
        logger.error(f"Failed to download/load transformer model {model_name}: {e}")
        return False

def check_system_requirements():
    """Check if system has required dependencies and GPU."""
    logger.info("Checking system requirements...")

    try:
        import torch
        logger.info(f"✅ PyTorch version: {torch.__version__}")

        if torch.cuda.is_available():
            logger.info(f"✅ CUDA available. GPU: {torch.cuda.get_device_name()}")
            logger.info(f"   CUDA version: {torch.version.cuda}")
            logger.info(f"   GPU memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f} GB")
        else:
            logger.warning("⚠️  CUDA not available. Models will run on CPU (slower)")
    except ImportError:
        logger.error("❌ PyTorch not installed")
        return False

    try:
        import sentence_transformers
        logger.info(f"✅ SentenceTransformers version: {sentence_transformers.__version__}")
    except ImportError:
        logger.error("❌ SentenceTransformers not installed")
        return False

    try:
        import transformers
        logger.info(f"✅ Transformers version: {transformers.__version__}")
    except ImportError:
        logger.error("❌ Transformers not installed")
        return False

    return True

def main():
    """Main function to download all required models."""
    logger.info("🚀 Starting model download script for RTX 3070 8GB setup")
    logger.info("=" * 60)

    # Check requirements
    if not check_system_requirements():
        logger.error("❌ System requirements not met. Please install required packages.")
        sys.exit(1)

    logger.info("\n📦 Models to download:")
    logger.info("1. all-MiniLM-L6-v2 (SentenceTransformer for embeddings)")
    logger.info("2. microsoft/DialoGPT-small (Lightweight LLM)")
    logger.info("3. microsoft/DialoGPT-medium (Medium LLM)")
    logger.info("4. distilgpt2 (Fast GPT-2 distil for fallback)")

    success_count = 0
    total_count = 4

    # Download embedding model
    logger.info("\n" + "="*50)
    if download_sentence_transformer_model("all-MiniLM-L6-v2"):
        success_count += 1
        logger.info("✅ Embedding model downloaded successfully")
    else:
        logger.error("❌ Embedding model download failed")

    # Download LLM models
    models_to_download = [
        "microsoft/DialoGPT-small",
        "microsoft/DialoGPT-medium",
        "distilgpt2"
    ]

    for model_name in models_to_download:
        logger.info("\n" + "="*50)
        if download_transformer_model(model_name):
            success_count += 1
            logger.info(f"✅ {model_name} downloaded successfully")
        else:
            logger.error(f"❌ {model_name} download failed")

    # Summary
    logger.info("\n" + "="*60)
    logger.info("📊 DOWNLOAD SUMMARY")
    logger.info("="*60)
    logger.info(f"Models downloaded successfully: {success_count}/{total_count}")

    if success_count == total_count:
        logger.info("🎉 All models downloaded successfully!")
        logger.info("\n💡 Next steps:")
        logger.info("1. Update your .env file to set EMBEDDING_PRIMARY_PROVIDER=local")
        logger.info("2. Restart your application")
        logger.info("3. The RAG system will now use local models for privacy and performance")
    else:
        logger.warning(f"⚠️  {total_count - success_count} models failed to download.")
        logger.info("You can retry the script or manually download the missing models.")
        sys.exit(1)

if __name__ == "__main__":
    main()