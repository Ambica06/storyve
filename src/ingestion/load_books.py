import os


def load_books(folder_path):
    """
    Return a list of (book_id, book_text) tuples.

    book_id is currently the filename (e.g. 'alice_in_wonderland.txt'),
    which is stable across runs and used for checkpointing.
    """
    books = []
    for file in os.listdir(folder_path):
        if file.endswith(".txt"):
            full_path = os.path.join(folder_path, file)
            with open(full_path, "r", encoding="utf-8") as f:
                text = f.read()
            books.append((file, text))
    return books
