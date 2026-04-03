from src.ingestion.load_books import load_books
from src.pipeline.generate_dataset import process_book


def main():
    books = load_books("/Users/ambica/storyve/data/raw_books")

    for i, book in enumerate(books):
        print(f"Processing book {i+1}")
        process_book(book)


if __name__ == "__main__":
    main()
