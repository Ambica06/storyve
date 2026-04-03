import requests
import json
from config.constants import OLLAMA_URL
from config.settings import MODEL_NAME, TEMPERATURE


def extract_json(text):
    try:
        return json.loads(text)
    except:
        start = text.find("{")
        end = text.rfind("}") + 1

        if start != -1 and end != -1:
            return json.loads(text[start:end])

        raise Exception("Invalid JSON")


def call_llm(prompt):
    response = requests.post(
        OLLAMA_URL,
        json={
            "model": MODEL_NAME,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": TEMPERATURE
            }
        },
        timeout=60
    )

    if response.status_code != 200:
        raise Exception(response.text)

    output = response.json()["response"]

    return extract_json(output)
