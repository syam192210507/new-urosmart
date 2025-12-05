# Port Configuration Fix

## Issue
The iOS app was getting "Connection refused" errors when trying to connect to the backend:
```
nw_socket_handle_socket_event [C2:2] Socket SO_ERROR [61: Connection refused]
Task finished with error [-1004] Error Domain=NSURLErrorDomain Code=-1004 "Could not connect to the server."
```

## Root Cause
**Port mismatch** between the iOS app and backend server:
- **iOS app** was configured to connect to: `http://172.25.81.32:5001/api`
- **Backend server** is actually running on: `http://172.25.81.32:5000/api`

This is why all API calls were failing with error code 61 (Connection refused).

## Fix Applied
Updated `/frontend/UroSmart/AppConfig.swift`:

**Before:**
```swift
static let apiBaseURL = "http://172.25.81.32:5001/api"
```

**After:**
```swift
static let apiBaseURL = "http://172.25.81.32:5000/api"
```

## Verification

### Backend Server Status:
```bash
$ lsof -ti:5000
5198  # Server is running

$ curl http://localhost:5000/api/health
{
    "status": "healthy",
    "timestamp": "2025-12-05T03:24:33.088715"
}
```

### Network Configuration:
```bash
$ ifconfig | grep "inet " | grep -v 127.0.0.1
172.25.81.32  # Mac's IP address matches
```

## What to Do Next

1. **Rebuild the app** in Xcode (⌘R)
2. **Log in** - Should now connect to backend successfully
3. **Test profile features**:
   - Email should be visible
   - Delete account should work and connect to backend
   - All API calls should succeed

## Expected Behavior After Fix

### Before (Port 5001):
- ❌ All API calls failed with "Connection refused"
- ❌ Had to use offline mode only
- ❌ Delete account showed "Please login to continue"
- ❌ User sync failed

### After (Port 5000):
- ✅ API calls connect successfully
- ✅ Online/offline mode works correctly
- ✅ Delete account works and removes data from backend
- ✅ User sync works
- ✅ Login/signup connects to backend
- ✅ Report upload/download works

## Configuration Options

The `AppConfig.swift` file has documentation for different environments:

```swift
/// Local testing (same machine):
/// "http://localhost:5000/api"

/// iPhone/Simulator testing (different machine):
/// "http://172.25.81.32:5000/api" (Your Mac's IP)

/// Production:
/// "https://your-production-server.com/api"
```

**Current configuration:** Using Mac's IP for simulator testing

## Notes

- The backend **always** runs on **port 5000** (Flask default)
- This is configured in `backend/app.py` (cannot be changed easily)
- The iOS app must match this port in `AppConfig.swift`
- After changing the port, you MUST rebuild the app for changes to take effect
