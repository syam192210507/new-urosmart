import requests
import json
import sys
import time

BASE_URL = "http://localhost:5000/api"

def test_reset_flow():
    print("🚀 Starting OTP Password Reset Flow Test")
    
    # 1. Create a test user
    email = "otp_test@example.com"
    password = "password123"
    phone = "+1234567890"
    
    print(f"\n1. Creating user {phone}...")
    try:
        resp = requests.post(f"{BASE_URL}/auth/signup", json={
            "email": email,
            "password": password,
            "phone_number": phone
        })
        if resp.status_code == 201:
            print("✅ User created")
        elif resp.status_code == 409:
            print("ℹ️ User already exists (continuing)")
        else:
            print(f"❌ Failed to create user: {resp.text}")
            return
    except Exception as e:
        print(f"❌ Connection error: {e}")
        return

    # 2. Request OTP
    print(f"\n2. Requesting OTP for {phone}...")
    resp = requests.post(f"{BASE_URL}/auth/forgot-password", json={"phone_number": phone})
    if resp.status_code != 200:
        print(f"❌ Failed to request OTP: {resp.text}")
        return
    
    data = resp.json()
    otp = data.get('dev_otp')
    if not otp:
        print("❌ No dev_otp returned (check backend logs or enable debug mode)")
        # In production, we can't get OTP from response, so we'd stop here or check logs manually
        # For this test, we rely on dev_otp
        return
        
    print(f"✅ OTP received: {otp}")

    # 3. Reset Password
    new_password = "newpassword456"
    print(f"\n3. Resetting password with OTP...")
    resp = requests.post(f"{BASE_URL}/auth/reset-password", json={
        "phone_number": phone,
        "otp": otp,
        "new_password": new_password
    })
    
    if resp.status_code == 200:
        print("✅ Password reset successful")
    else:
        print(f"❌ Failed to reset password: {resp.text}")
        return

    # 4. Verify Login with New Password
    print("\n4. Verifying login with new password...")
    resp = requests.post(f"{BASE_URL}/auth/login", json={
        "email": email,
        "password": new_password
    })
    
    if resp.status_code == 200:
        print("✅ Login successful with new password!")
    else:
        print(f"❌ Login failed with new password: {resp.text}")
        return

    print("\n🎉 OTP Test Completed Successfully")

if __name__ == "__main__":
    test_reset_flow()
