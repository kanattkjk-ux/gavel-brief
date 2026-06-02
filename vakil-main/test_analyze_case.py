import requests
import json

# Test the analyze-case endpoint
url = "http://127.0.0.1:8000/api/analyze-case"
data = {
    "case_type": "Property",
    "description": "dispute on land in chennai",
    "location": "chennai",
    "urgency": "Medium"
}

try:
    response = requests.post(url, json=data)
    print(f"Status Code: {response.status_code}")
    if response.status_code == 200:
        result = response.json()
        print(f"Analysis generated successfully!")
        print(f"Relevant laws found: {len(result.get('relevant_laws', []))}")
        print(f"Similar cases found: {len(result.get('similar_cases', []))}")
        print(f"Analysis preview: {result.get('analysis', '')[:200]}...")
    else:
        print(f"Error: {response.text}")
except Exception as e:
    print(f"Error: {e}")
