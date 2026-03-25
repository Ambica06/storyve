import boto3
import tempfile
import ebooklib
from ebooklib import epub
from bs4 import BeautifulSoup

s3 = boto3.client('s3')

def get_presigned_url(bucket: str, key: str, expiration: int = 3600):
    return s3.generate_presigned_url(
        'get_object',
        Params={'Bucket': bucket, 'Key': key},
        ExpiresIn=expiration
    )

def read_epub(bucket: str, key: str) -> list:
    with tempfile.NamedTemporaryFile(suffix='.epub') as tmp:
        s3.download_fileobj(bucket, key, tmp)
        tmp.seek(0)
        book = epub.read_epub(tmp.name)

    chapters = []
    for item in book.get_items_of_type(ebooklib.ITEM_DOCUMENT):
        soup = BeautifulSoup(item.get_content(), 'html.parser')
        chapters.append(soup.get_text())
    return chapters

def read_txt(bucket: str, key: str) -> str:
    response = s3.get_object(Bucket=bucket, Key=key)
    return response['Body'].read().decode('utf-8')

def read_book(bucket: str, key: str) -> dict:
    ext = key.rsplit('.', 1)[-1].lower()

    if ext == 'pdf':
        return {'type':'pdf', 'url': get_presigned_url(bucket, key)}
    elif ext == 'epub':
        return {'type':'epub', 'chapters': read_epub(bucket, key)}
    elif ext == 'txt':
        return {'type':'txt', 'content': read_txt(bucket, key)}
    else:
        raise ValueError(f"Unsupported format: {ext}")
