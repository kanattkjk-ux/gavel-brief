import requests
import json

# Test the extract-keywords endpoint
url = "http://127.0.0.1:8000/api/extract-keywords"
data = {"text": "dispute on land in chennai"}

try:
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.json()}")
except Exception as e:
    print(f"Error: {e}")
