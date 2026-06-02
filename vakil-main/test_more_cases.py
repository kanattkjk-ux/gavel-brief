import requests
import json

# Test the extract-keywords endpoint with different cases
url = "http://127.0.0.1:8000/api/extract-keywords"

test_cases = [
    {"text": "divorce proceedings and child custody battle", "expected_category": "Family"},
    {"text": "theft and robbery at the local bank", "expected_category": "Criminal"},
    {"text": "employment termination without notice", "expected_category": "Employment"},
    {"text": "general contract dispute", "expected_category": "Civil"}
]

for i, test_case in enumerate(test_cases):
    try:
        response = requests.post(url, json={"text": test_case["text"]})
        result = response.json()
        print(f"Test {i+1}: {test_case['text']}")
        print(f"  Status: {response.status_code}")
        print(f"  Category: {result.get('suggested_category')} (Expected: {test_case['expected_category']})")
        print(f"  Keywords: {result.get('keywords')}")
        print(f"  Confidence: {result.get('confidence')}")
        print()
    except Exception as e:
        print(f"Error in test {i+1}: {e}")
