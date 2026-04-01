from src.preprocessing.chunker import split_into_chunks
from src.preprocessing.cleaner import clean_gutenberg_text
from src.llm.prompts import scene_extraction_prompt
from src.llm.client import call_llm
from src.validation.validator import is_valid_scene
from src.utils.file_utils import append_jsonl
from config.settings import OUTPUT_FILE, MAX_RETRIES


def safe_llm_call(prompt):
    for _ in range(MAX_RETRIES):
        try:
            return call_llm(prompt)
        except Exception as e:
            print("Retry due to error:", e)
    return None


def process_book(book_text):
    cleaned = clean_gutenberg_text(book_text)
    chunks = split_into_chunks(cleaned)

    for chunk in chunks:
        prompt = scene_extraction_prompt(chunk)
        scene = safe_llm_call(prompt)

        if scene and is_valid_scene(scene):
            record = {
                "input": chunk,
                "output": scene
            }
            append_jsonl(OUTPUT_FILE, record)
        else:
            print("Skipped invalid scene")
