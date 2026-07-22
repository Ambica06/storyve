# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Working conventions

This app is early-stage, so documented architectural decisions below (dependencies, patterns, folder structure) are guidance, not fixed law. They may be revisited as the app grows. However: **do not deviate from an architectural decision documented in this file without the user's explicit approval first** — surface the options and tradeoffs, let the user decide, then update this file to reflect the outcome (see "Architecture decisions log" under the iOS app section for the format).

## Repository overview

This repo contains two largely independent parts that share only a name and a product vision:

1. **`/` (root) — Python dataset-generation pipeline.** Offline tooling that runs public-domain books through a local LLM to extract "scenes" (characters, setting, action) for later use as training/prototyping data for the AI image-generation feature described in the product vision.
2. **`/ui` — `storyveApp`, the iOS app.** A SwiftUI/SwiftData app (Xcode project) that is the actual product: an EPUB reader. This is the primary place feature work happens.

The two sides do not currently call each other — there is no backend/API server in this repo. The Python pipeline is a data-generation experiment; the app has no networking layer yet. See `ui/storyveApp/storyve_app_prd.md` for the full product spec, including the planned (not-yet-built) backend API contract for scene analysis and image visualization.

## Python pipeline (root)

### Running

```bash
pip install -r requirements.txt   # only dependency: requests
python main.py
```

`main.py` loads every `.txt` file in `data/raw_books/`, cleans it, chunks it, and runs each chunk through a local LLM.

### Requires a local Ollama server

The pipeline calls `OLLAMA_URL = "http://localhost:11434/api/generate"` (see `config/constants.py`) using model `qwen2.5:7b` (see `config/settings.py`). Ollama must be running locally with that model pulled before `python main.py` will succeed.

### Pipeline flow (`src/pipeline/generate_dataset.py`)

For each book in `data/raw_books/`:
1. `clean_gutenberg_text` (`src/preprocessing/cleaner.py`) strips Project Gutenberg boilerplate outside the `*** START OF` / `*** END OF` markers and normalizes whitespace.
2. `split_into_chunks` (`src/preprocessing/chunker.py`) splits into ~300-word chunks.
3. Each chunk is sent through `scene_extraction_prompt` (`src/llm/prompts.py`) to `call_llm` (`src/llm/client.py`), which posts to Ollama and parses the JSON response (falling back to extracting the first `{...}` block if the model wraps it in prose).
4. `is_valid_scene` (`src/validation/validator.py`) requires non-empty `action`, `characters`, and `setting`.
5. `enrich_scene_characters` tracks characters across chunks in `data/dataset/introduced_characters.jsonl` so a character's `static_traits` (age, body type, hair, etc.) are captured once on first appearance and reused on subsequent appearances — this is what gives generated scenes consistent character descriptions. `dynamic_traits` (emotion/pose/action) are re-extracted every time.
6. Valid records are appended to `data/dataset/dataset.jsonl`.

### Checkpointing and resumability

Progress is checkpointed per book to `data/checkpoints/<book_id>.json` (`last_completed_chunk_index`) and saved after every chunk, so `python main.py` can be interrupted and re-run without reprocessing completed chunks or losing `introduced_characters` state. Both checkpoint and character-tracking writes use a write-to-`.tmp`-then-`rename` pattern to avoid corruption on interruption. When editing this pipeline, preserve that atomicity and the per-chunk checkpoint cadence — books can be long and runs are expected to be interrupted/resumed.

There is no test suite for this pipeline.

## iOS app (`ui/storyveApp`)

### Building / running

Open `ui/storyveApp.xcodeproj` in Xcode and run the `storyveApp` scheme (iOS 26.4+ deployment target per current project settings, Swift 5). There is no CLI build script or test target in this repo yet — use Xcode directly, or `xcodebuild` against the `storyveApp` scheme if working headlessly.

The app depends on the **Readium Swift Toolkit** (`https://github.com/readium/swift-toolkit`, resolved via Swift Package Manager) for all EPUB parsing/rendering — specifically `ReadiumShared`, `ReadiumStreamer`, and `ReadiumNavigator`. Don't reimplement EPUB parsing/pagination; extend it through Readium's APIs.

### Architecture decisions log

- **2026-07-21 — Stay on the Readium Swift Toolkit for EPUB rendering.** While testing the reader, we hit a bug where EPUB content renders but swipe/scroll gestures don't move pages (in-page hyperlinks still navigate). We considered dropping Readium for a custom `WKWebView`-based renderer or a commercial SDK (PSPDFKit/Nutrient), but decided to keep Readium and fix the underlying bug instead. Reasoning: Readium is the only actively-maintained option (used in production by Thorium Reader, Palace, etc.) and already provides a `Decorator` API for highlighting text ranges with tap callbacks — exactly what the PRD's planned Phase 3 "tap-to-visualize scene" feature needs. A custom renderer would mean re-implementing EPUB parsing/pagination/TOC/locators from scratch with no community support, for a bug that's very likely narrow and fixable (isolated to the WKWebView JS pagination bootstrap, not a fundamental flaw). Revisit this only if a specific, well-understood Readium limitation blocks a real feature — not because of one bug.

### Architecture

- **Persistence**: SwiftData. `Book` (`Persistence/Book.swift`) is the only model — title, author, `epubPath`/`coverPath`, reading `progress`, `createdAt`. `epubPath`/`coverPath` are stored **relative to the Books directory** (e.g. `<uuid>/file.epub`), not as absolute paths — the app container's UUID changes across reinstalls/updates, so an absolute path breaks. Resolve a stored path to an absolute file URL with `EPUBService.shared.resolveBooksPath(_:)` before use; never read `book.epubPath`/`book.coverPath` directly as a filesystem path. The container is configured once in `App/StoryveApp.swift`.
- **Import flow**: `LibraryView` presents a `.fileImporter` for `.epub` (see `Shared/Extensions/UTType+Extensions.swift`). Import is handled by `Services/EPUB/EPUBService.swift`, which copies the picked file into a per-book UUID folder under Application Support, opens it via Readium (`AssetRetriever` → `PublicationOpener`), extracts title/author/cover from `publication.metadata`, and returns an `EPUBMetadata` struct (with relative `epubPath`/`coverPath`) that `LibraryView` turns into a persisted `Book`.
- **Reading flow**: `ReaderView` (SwiftUI) wraps `EPUBReaderContainer`, a `UIViewControllerRepresentable` around `EPUBViewController` (UIKit). `EPUBViewController` resolves `book.epubPath` via `EPUBService.resolveBooksPath(_:)` and re-opens it through the same Readium `AssetRetriever`/`PublicationOpener` pipeline used at import time (`EPUBService.openPublication(at:)`, shared by both), then embeds Readium's `EPUBNavigatorViewController` as a child view controller with its view pinned to `EPUBViewController.view` via Auto Layout (not a one-time frame assignment — the container's bounds aren't final yet at `viewDidLoad` when hosted from SwiftUI).
- **Feature folders**: `Features/<FeatureName>/{Views,Components}` (e.g. `Features/Library`, `Features/Reader`); cross-feature UI lives in `Shared/Components`; cross-cutting extensions in `Shared/Extensions`.
- **Dark-only UI**: current views hardcode `Color.black` backgrounds and white/gray foreground colors rather than using semantic/system colors or adapting to light mode.

### Current state vs. product spec

`ui/storyveApp/storyve_app_prd.md` is the authoritative product spec and describes a much larger feature set (Phase 2–4: whole-book scene analysis against a backend, in-reader scene highlighting, tap-to-visualize AI image generation, image caching/overlay UI) than what currently exists in code. What's implemented today is Phase 1 only: EPUB import, library grid, and basic EPUB rendering/navigation — no networking layer, no scene highlighting, no image generation, no reading-position persistence, and no font/theme settings yet. When picking up reader/library work, check this PRD for the intended behavior and API contract before designing a new approach.

There is no test target in the Xcode project yet.
