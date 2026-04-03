from src.preprocessing.chunker import split_into_chunks
from src.preprocessing.cleaner import clean_gutenberg_text
from src.llm.prompts import scene_extraction_prompt
from src.llm.client import call_llm
from src.validation.validator import is_valid_scene
from src.utils.file_utils import append_jsonl
from config.settings import OUTPUT_FILE, MAX_RETRIES, INTRODUCED_CHARACTERS_FILE
import os
import json

def safe_llm_call(prompt):
    for _ in range(MAX_RETRIES):
        try:
            return call_llm(prompt)
        except Exception as e:
            print("Retry due to error:", e)
    return None


def load_introduced_characters():
    if os.path.exists(INTRODUCED_CHARACTERS_FILE):
        with open(INTRODUCED_CHARACTERS_FILE, "r") as f:
            return json.load(f)
    return {}


def save_introduced_characters(introduced_characters):
    with open(INTRODUCED_CHARACTERS_FILE, "w") as f:
        json.dump(introduced_characters, f, indent=2)


def enrich_scene_characters(scene, introduced_characters):
    scene_characters = []

    for name in scene.get("characters", []):
        first_appearance = name not in introduced_characters

        if first_appearance:
            static_traits = scene.get("characters", {}).get("static_traits", {}).get(name, {})
            introduced_characters[name] = static_traits
        else:
            static_traits = introduced_characters.get(name, {})

        dynamic_traits = scene.get("characters", {}).get("dynamic_traits", {}).get(name, {
            "emotion": "",
            "pose": "",
            "action": ""
        })

        char_info = {
            "name": name,
            "static_traits": static_traits,
            "dynamic_traits": dynamic_traits,
            "first_appearance": first_appearance
        }
        scene_characters.append(char_info)

    return scene_characters


def process_chunk(chunk, introduced_characters):
    prompt = scene_extraction_prompt(chunk)
    scene = safe_llm_call(prompt)

    if not scene or not is_valid_scene(scene):
        print("Skipped invalid scene")
        return

    scene_characters = enrich_scene_characters(scene, introduced_characters)

    record = {
        "input": chunk,
        "output": scene,
        "characters": scene_characters
    }
    append_jsonl(OUTPUT_FILE, record)


def process_book(book_text):
    cleaned = clean_gutenberg_text(book_text)
    chunks = split_into_chunks(cleaned)

    introduced_characters = load_introduced_characters()

    for chunk in chunks:
        process_chunk(chunk, introduced_characters)

    save_introduced_characters(introduced_characters)