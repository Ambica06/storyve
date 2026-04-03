from src.preprocessing.chunker import split_into_chunks
from src.preprocessing.cleaner import clean_gutenberg_text
from src.llm.prompts import scene_extraction_prompt
from src.llm.client import call_llm
from src.validation.validator import is_valid_scene
from src.utils.file_utils import append_jsonl
from config.constants import DATASET_JSONL_PATH, INTRODUCED_CHARACTERS_JSONL_PATH, CHECKPOINTS_DIR
from config.settings import MAX_RETRIES
import os
import json
from pathlib import Path

def safe_llm_call(prompt):
    for _ in range(MAX_RETRIES):
        try:
            return call_llm(prompt)
        except Exception as e:
            print("Retry due to error:", e)
    return None


def load_introduced_characters():
    if not os.path.exists(INTRODUCED_CHARACTERS_JSONL_PATH):
        return {}

    try:
        with open(INTRODUCED_CHARACTERS_JSONL_PATH, "r", encoding="utf-8") as f:
            raw = f.read()
        if not raw.strip():
            print(
                f"[introduced_characters] File is empty; starting fresh: {INTRODUCED_CHARACTERS_JSONL_PATH}",
                flush=True,
            )
            return {}
        return json.loads(raw)
    except json.JSONDecodeError:
        print(
            f"[introduced_characters] Corrupt JSON; starting fresh: {INTRODUCED_CHARACTERS_JSONL_PATH}",
            flush=True,
        )
        return {}


def save_introduced_characters(introduced_characters):
    # Atomic write to reduce risk of partially-written files on interruption.
    path = Path(INTRODUCED_CHARACTERS_JSONL_PATH)
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    with tmp_path.open("w", encoding="utf-8") as f:
        json.dump(introduced_characters, f, indent=2)
    tmp_path.replace(path)


def enrich_scene_characters(scene, introduced_characters):
    scene_characters = []

    for character in scene.get("characters", []):
        # LLM output is expected to be a list of character objects.
        # See `scene_extraction_prompt()` for the intended schema.
        name = character.get("name")
        static_traits = character.get("static_traits", {})
        dynamic_traits = character.get(
            "dynamic_traits",
            {"emotion": "", "pose": "", "action": ""},
        )

        # Track whether we've seen this character before in this run.
        first_appearance = bool(name) and name not in introduced_characters

        if first_appearance and bool(name):
            introduced_characters[name] = static_traits
        elif bool(name):
            # Reuse previously introduced static traits for consistency.
            static_traits = introduced_characters.get(name, static_traits)

        char_info = {
            "name": name,
            "static_traits": static_traits,
            "dynamic_traits": dynamic_traits,
            "first_appearance": first_appearance,
        }
        scene_characters.append(char_info)

    return scene_characters


def process_chunk(chunk, introduced_characters):
    prompt = scene_extraction_prompt(chunk)
    scene = safe_llm_call(prompt)

    if not scene or not is_valid_scene(scene):
        print("Skipped invalid scene", flush=True)
        return None, None

    scene_characters = enrich_scene_characters(scene, introduced_characters)

    return scene, scene_characters


def checkpoint_path_for_book(book_id: str) -> Path:
    """
    Compute the path to the checkpoint file for a given book.
    """
    CHECKPOINTS_DIR.mkdir(parents=True, exist_ok=True)
    safe_book_id = book_id.replace(os.sep, "_")
    return CHECKPOINTS_DIR / f"{safe_book_id}.json"


def load_checkpoint(book_id: str) -> dict:
    """
    Load checkpoint metadata for the given book.

    Returns a dict with at least:
        - last_completed_chunk_index (int, -1 if none)
    """
    path = checkpoint_path_for_book(book_id)
    if not path.exists():
        print(f"[checkpoint] No checkpoint found for book={book_id}; starting fresh.", flush=True)
        return {"last_completed_chunk_index": -1}

    try:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception:
        # If checkpoint is corrupted, start from scratch for safety.
        print(f"[checkpoint] Corrupted checkpoint for book={book_id}; starting fresh.", flush=True)
        return {"last_completed_chunk_index": -1}

    if "last_completed_chunk_index" not in data:
        data["last_completed_chunk_index"] = -1
    print(
        f"[checkpoint] Loaded book={book_id} last_completed_chunk_index={data.get('last_completed_chunk_index')}.",
        flush=True,
    )
    return data


def save_checkpoint(book_id: str, checkpoint: dict) -> None:
    """
    Persist checkpoint metadata for the given book.
    """
    path = checkpoint_path_for_book(book_id)
    tmp_path = path.with_suffix(path.suffix + ".tmp")
    with tmp_path.open("w", encoding="utf-8") as f:
        json.dump(checkpoint, f, indent=2)
    tmp_path.replace(path)
    print(
        f"[checkpoint] Saved book={book_id} last_completed_chunk_index={checkpoint.get('last_completed_chunk_index')}.",
        flush=True,
    )


def process_book(book_id, book_text):
    print(f"[book] Starting book={book_id}", flush=True)
    cleaned = clean_gutenberg_text(book_text)
    chunks = split_into_chunks(cleaned)
    print(f"[book] book={book_id} total_chunks={len(chunks)}", flush=True)

    introduced_characters = load_introduced_characters()

    # Load checkpoint and resume from the next unprocessed chunk.
    checkpoint = load_checkpoint(book_id)
    last_completed = checkpoint.get("last_completed_chunk_index", -1)

    total_chunks = len(chunks)
    checkpoint["total_chunks"] = total_chunks
    checkpoint["book_id"] = book_id

    for idx, chunk in enumerate(chunks):
        if idx <= last_completed:
            continue

        print(
            f"[process] book={book_id} chunk={idx + 1}/{total_chunks} (chunk_index={idx})",
            flush=True,
        )

        scene, scene_characters = process_chunk(chunk, introduced_characters)
        if scene is None or scene_characters is None:
            # Invalid scenes are already logged inside process_chunk
            continue

        record = {
            "book_id": book_id,
            "chunk_index": idx,
            "total_chunks": total_chunks,
            "input": chunk,
            "output": scene,
            "characters": scene_characters,
        }
        append_jsonl(DATASET_JSONL_PATH, record)

        checkpoint["last_completed_chunk_index"] = idx
        save_checkpoint(book_id, checkpoint)

        # Persist introduced characters incrementally so restarts mid-book don't lose work.
        save_introduced_characters(introduced_characters)
        print(
            f"[introduced_characters] Saved count={len(introduced_characters)} after book={book_id} chunk_index={idx}",
            flush=True,
        )

    print(f"[book] Completed book={book_id}", flush=True)