from pathlib import Path

# Keep project-relative paths so the code works on any machine.
DATA_DIR = Path("data")

RAW_BOOKS_DIR = DATA_DIR / "raw_books"
DATASET_DIR = DATA_DIR / "dataset"
CHECKPOINTS_DIR = DATA_DIR / "checkpoints"

DATASET_JSONL_PATH = DATASET_DIR / "dataset.jsonl"
INTRODUCED_CHARACTERS_JSONL_PATH = DATASET_DIR / "introduced_characters.jsonl"

# LLM endpoint
OLLAMA_URL = "http://localhost:11434/api/generate"

