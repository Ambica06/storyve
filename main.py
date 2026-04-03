from src.ingestion.load_books import load_books
from src.pipeline.generate_dataset import process_book
from config.constants import RAW_BOOKS_DIR


def main():
    books = load_books(RAW_BOOKS_DIR)

    for i, (book_id, book_text) in enumerate(books):
        print(f"Processing book {i+1}: {book_id}")
        process_book(book_id, book_text)


if __name__ == "__main__":
    main()
