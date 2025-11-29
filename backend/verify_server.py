import requests
import time
import sys

BASE_URL = "http://localhost:5000/api"

def print_status(message, status):
    if status:
        print(f"✅ {message}")
    else:
        print(f"❌ {message}")

def verify_server():
    print("🚀 Starting Server Verification...")
    
    # 1. Health Check
    try:
        response = requests.get(f"{BASE_URL}/health")
        if response.status_code == 200:
            print_status("Health Check Passed", True)
        else:
            print_status(f"Health Check Failed: {response.status_code}", False)
            return
    except requests.exceptions.ConnectionError:
        print_status("Server is not running. Please start the server first.", False)
        return

    # 2. ML Detection Status
    try:
        response = requests.get(f"{BASE_URL}/detect/status")
        if response.status_code == 200:
            data = response.json()
            if data.get('available'):
                print_status("ML Detection Available", True)
            else:
                print_status(f"ML Detection Unavailable: {data.get('message')}", False)
        else:
            print_status(f"ML Status Check Failed: {response.status_code}", False)
    except Exception as e:
        print_status(f"ML Status Check Error: {str(e)}", False)

    # 3. Auth - Signup (Create a random user)
    import uuid
    random_id = str(uuid.uuid4())[:8]
    email = f"test_{random_id}@example.com"
    password = "password123"
    phone = f"123456{random_id}" # Ensure unique phone

    user_token = None
    
    try:
        payload = {
            "email": email,
            "password": password,
            "phone_number": phone
        }
        response = requests.post(f"{BASE_URL}/auth/signup", json=payload)
        if response.status_code == 201:
            print_status("User Signup Passed", True)
            user_token = response.json().get('access_token')
        else:
            print_status(f"User Signup Failed: {response.text}", False)
    except Exception as e:
        print_status(f"User Signup Error: {str(e)}", False)

    if not user_token:
        print("⚠️ Skipping authenticated tests due to signup failure")
        return

    headers = {"Authorization": f"Bearer {user_token}"}

    # 4. Create Report (Online Mode Simulation)
    try:
        report_payload = {
            "case_number": f"CASE-{random_id}",
            "yeast_present": True,
            "yeast_count": 5,
            "yeast_confidence": 0.95
        }
        response = requests.post(f"{BASE_URL}/reports", json=report_payload, headers=headers)
        if response.status_code == 201:
            print_status("Create Report (Online) Passed", True)
        else:
            print_status(f"Create Report Failed: {response.text}", False)
    except Exception as e:
        print_status(f"Create Report Error: {str(e)}", False)

    # 5. Sync Simulation (Offline -> Online)
    # In reality, the iOS app sends individual requests for each queued item.
    # We will simulate sending another report that was "queued".
    try:
        queued_report_payload = {
            "case_number": f"CASE-{random_id}-OFFLINE",
            "calcium_oxalate_present": True,
            "calcium_oxalate_count": 2,
            "calcium_oxalate_confidence": 0.88
        }
        response = requests.post(f"{BASE_URL}/reports", json=queued_report_payload, headers=headers)
        if response.status_code == 201:
            print_status("Sync Report (Offline Recovery) Passed", True)
        else:
            print_status(f"Sync Report Failed: {response.text}", False)
    except Exception as e:
        print_status(f"Sync Report Error: {str(e)}", False)

    # 6. Verify Reports Exist
    try:
        response = requests.get(f"{BASE_URL}/reports", headers=headers)
        if response.status_code == 200:
            reports = response.json().get('reports', [])
            if len(reports) >= 2:
                print_status(f"Verify Reports Passed (Found {len(reports)} reports)", True)
            else:
                print_status(f"Verify Reports Warning: Expected at least 2 reports, found {len(reports)}", False)
        else:
            print_status(f"Get Reports Failed: {response.text}", False)
    except Exception as e:
        print_status(f"Get Reports Error: {str(e)}", False)

if __name__ == "__main__":
    verify_server()
