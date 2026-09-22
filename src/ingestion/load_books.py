import os
import boto3
inport uuid

s3 = boto3.client("s3")

BUCKET = "epub_bucket"

def create_upload_url():
    upload_id = str(uuid.uuid4())

    key = f"incoming/{upload_id}/book.epub"

    url = s3.generate_presigned_url(
        "put_object",
        Params={
            "Bucket": BUCKET,
            "Key": key,
            "ContentType": "application/epub+zip"
        },
        ExpiresIn=900
    )

    return {
        "upload_id": upload_id,
        "key": key,
        "url": url
    }

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
