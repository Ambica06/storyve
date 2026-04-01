import os


def load_books(folder_path):
    books = []
    for file in os.listdir(folder_path):
        if file.endswith(".txt"):
            with open(os.path.join(folder_path, file), "r", encoding="utf-8") as f:
                books.append(f.read())
    return books
