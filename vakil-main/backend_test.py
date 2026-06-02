#!/usr/bin/env python3

import requests
import sys
import json
from datetime import datetime

class VakilSetuAPITester:
    def __init__(self, base_url="https://legal-match-10.preview.emergentagent.com"):
        self.base_url = base_url
        self.session = requests.Session()
        self.tests_run = 0
        self.tests_passed = 0
        self.test_results = []

    def log_test(self, name, success, details=""):
        """Log test result"""
        self.tests_run += 1
        if success:
            self.tests_passed += 1
            print(f"✅ {name}")
        else:
            print(f"❌ {name} - {details}")
        
        self.test_results.append({
            "test": name,
            "success": success,
            "details": details
        })

    def test_auth_registration(self):
        """Test user registration for both client and lawyer"""
        print("\n🔍 Testing User Registration...")
        
        # Test client registration
        client_data = {
            "name": "Test Client User",
            "email": f"testclient_{datetime.now().strftime('%H%M%S')}@test.com",
            "password": "testpass123",
            "role": "client"
        }
        
        try:
            response = self.session.post(f"{self.base_url}/api/auth/register", json=client_data)
            success = response.status_code == 200
            if success:
                data = response.json()
                self.client_user = data
                self.log_test("Client Registration", True)
            else:
                self.log_test("Client Registration", False, f"Status: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Client Registration", False, str(e))

        # Test lawyer registration
        lawyer_data = {
            "name": "Test Lawyer User",
            "email": f"testlawyer_{datetime.now().strftime('%H%M%S')}@test.com",
            "password": "testpass123",
            "role": "lawyer",
            "specialization": "Criminal",
            "location": "Mumbai"
        }
        
        try:
            response = self.session.post(f"{self.base_url}/api/auth/register", json=lawyer_data)
            success = response.status_code == 200
            if success:
                data = response.json()
                self.lawyer_user = data
                self.log_test("Lawyer Registration", True)
            else:
                self.log_test("Lawyer Registration", False, f"Status: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Lawyer Registration", False, str(e))

    def test_auth_login(self):
        """Test login functionality with test credentials"""
        print("\n🔍 Testing Login Functionality...")
        
        # Test client login
        client_login = {
            "email": "client@test.com",
            "password": "password123"
        }
        
        try:
            response = self.session.post(f"{self.base_url}/api/auth/login", json=client_login)
            success = response.status_code == 200
            if success:
                self.client_session = requests.Session()
                # Copy cookies from response
                for cookie in response.cookies:
                    self.client_session.cookies.set(cookie.name, cookie.value)
                self.log_test("Client Login", True)
            else:
                self.log_test("Client Login", False, f"Status: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Client Login", False, str(e))

        # Test lawyer login
        lawyer_login = {
            "email": "lawyer@test.com",
            "password": "password123"
        }
        
        try:
            response = self.session.post(f"{self.base_url}/api/auth/login", json=lawyer_login)
            success = response.status_code == 200
            if success:
                self.lawyer_session = requests.Session()
                # Copy cookies from response
                for cookie in response.cookies:
                    self.lawyer_session.cookies.set(cookie.name, cookie.value)
                self.log_test("Lawyer Login", True)
            else:
                self.log_test("Lawyer Login", False, f"Status: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Lawyer Login", False, str(e))

    def test_auth_me_endpoint(self):
        """Test /auth/me endpoint for both users"""
        print("\n🔍 Testing Auth Me Endpoint...")
        
        # Test client auth/me
        if hasattr(self, 'client_session'):
            try:
                response = self.client_session.get(f"{self.base_url}/api/auth/me")
                success = response.status_code == 200
                if success:
                    data = response.json()
                    success = data.get('role') == 'client'
                self.log_test("Client Auth Me", success, f"Status: {response.status_code}")
            except Exception as e:
                self.log_test("Client Auth Me", False, str(e))
        else:
            self.log_test("Client Auth Me", False, "No client session available")

        # Test lawyer auth/me
        if hasattr(self, 'lawyer_session'):
            try:
                response = self.lawyer_session.get(f"{self.base_url}/api/auth/me")
                success = response.status_code == 200
                if success:
                    data = response.json()
                    success = data.get('role') == 'lawyer'
                self.log_test("Lawyer Auth Me", success, f"Status: {response.status_code}")
            except Exception as e:
                self.log_test("Lawyer Auth Me", False, str(e))
        else:
            self.log_test("Lawyer Auth Me", False, "No lawyer session available")

    def test_case_creation(self):
        """Test case creation by client"""
        print("\n🔍 Testing Case Creation...")
        
        if not hasattr(self, 'client_session'):
            self.log_test("Case Creation", False, "No client session available")
            return

        case_data = {
            "case_type": "Criminal",
            "description": "Test case description for automated testing",
            "location": "Mumbai",
            "urgency": "High",
            "budget": "₹50,000 - ₹1,00,000"
        }
        
        try:
            response = self.client_session.post(f"{self.base_url}/api/cases", json=case_data)
            success = response.status_code == 200
            if success:
                data = response.json()
                self.test_case_id = data.get('id')
                self.log_test("Case Creation", True)
            else:
                self.log_test("Case Creation", False, f"Status: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Case Creation", False, str(e))

    def test_case_retrieval(self):
        """Test case retrieval by lawyer"""
        print("\n🔍 Testing Case Retrieval...")
        
        if not hasattr(self, 'lawyer_session'):
            self.log_test("Case Retrieval", False, "No lawyer session available")
            return

        try:
            response = self.lawyer_session.get(f"{self.base_url}/api/cases")
            success = response.status_code == 200
            if success:
                data = response.json()
                success = isinstance(data, list)
                self.log_test("Case Retrieval", success, f"Found {len(data)} cases")
            else:
                self.log_test("Case Retrieval", False, f"Status: {response.status_code}, Response: {response.text}")
        except Exception as e:
            self.log_test("Case Retrieval", False, str(e))

    def test_case_filtering(self):
        """Test case filtering functionality"""
        print("\n🔍 Testing Case Filtering...")
        
        if not hasattr(self, 'lawyer_session'):
            self.log_test("Case Filtering", False, "No lawyer session available")
            return

        # Test filtering by location
        try:
            response = self.lawyer_session.get(f"{self.base_url}/api/cases?location=Mumbai")
            success = response.status_code == 200
            self.log_test("Filter by Location", success, f"Status: {response.status_code}")
        except Exception as e:
            self.log_test("Filter by Location", False, str(e))

        # Test filtering by urgency
        try:
            response = self.lawyer_session.get(f"{self.base_url}/api/cases?urgency=High")
            success = response.status_code == 200
            self.log_test("Filter by Urgency", success, f"Status: {response.status_code}")
        except Exception as e:
            self.log_test("Filter by Urgency", False, str(e))

        # Test filtering by case type
        try:
            response = self.lawyer_session.get(f"{self.base_url}/api/cases?case_type=Criminal")
            success = response.status_code == 200
            self.log_test("Filter by Case Type", success, f"Status: {response.status_code}")
        except Exception as e:
            self.log_test("Filter by Case Type", False, str(e))

    def test_case_acceptance(self):
        """Test case acceptance by lawyer"""
        print("\n🔍 Testing Case Acceptance...")
        
        if not hasattr(self, 'lawyer_session'):
            self.log_test("Case Acceptance", False, "No lawyer session available")
            return

        if not hasattr(self, 'test_case_id'):
            self.log_test("Case Acceptance", False, "No test case ID available")
            return

        try:
            response = self.lawyer_session.put(f"{self.base_url}/api/cases/{self.test_case_id}/accept")
            success = response.status_code == 200
            self.log_test("Case Acceptance", success, f"Status: {response.status_code}")
        except Exception as e:
            self.log_test("Case Acceptance", False, str(e))

    def test_protected_routes(self):
        """Test protected route access control"""
        print("\n🔍 Testing Protected Routes...")
        
        # Test unauthenticated access
        try:
            response = requests.get(f"{self.base_url}/api/auth/me")
            success = response.status_code == 401
            self.log_test("Unauthenticated Access Blocked", success, f"Status: {response.status_code}")
        except Exception as e:
            self.log_test("Unauthenticated Access Blocked", False, str(e))

        # Test client trying to access lawyer-only endpoint
        if hasattr(self, 'client_session'):
            try:
                response = self.client_session.get(f"{self.base_url}/api/cases")
                success = response.status_code == 403
                self.log_test("Client Access to Lawyer Endpoint Blocked", success, f"Status: {response.status_code}")
            except Exception as e:
                self.log_test("Client Access to Lawyer Endpoint Blocked", False, str(e))

    def test_logout(self):
        """Test logout functionality"""
        print("\n🔍 Testing Logout...")
        
        if hasattr(self, 'client_session'):
            try:
                response = self.client_session.post(f"{self.base_url}/api/auth/logout")
                success = response.status_code == 200
                self.log_test("Client Logout", success, f"Status: {response.status_code}")
            except Exception as e:
                self.log_test("Client Logout", False, str(e))

    def run_all_tests(self):
        """Run all tests"""
        print("🚀 Starting VakilSetu API Tests...")
        print(f"Testing against: {self.base_url}")
        
        self.test_auth_registration()
        self.test_auth_login()
        self.test_auth_me_endpoint()
        self.test_case_creation()
        self.test_case_retrieval()
        self.test_case_filtering()
        self.test_case_acceptance()
        self.test_protected_routes()
        self.test_logout()
        
        print(f"\n📊 Test Results: {self.tests_passed}/{self.tests_run} passed")
        
        if self.tests_passed == self.tests_run:
            print("🎉 All tests passed!")
            return True
        else:
            print("❌ Some tests failed!")
            return False

def main():
    tester = VakilSetuAPITester()
    success = tester.run_all_tests()
    return 0 if success else 1

if __name__ == "__main__":
    sys.exit(main())