# Xcode Build Phase Setup for Auto-Start Backend

## Overview
Configure Xcode to automatically start the UroSmart backend server when you run the iOS app.

---

## Setup Instructions

### 1. Open Your Xcode Project
```
Open: UroSmart.xcodeproj
```

### 2. Add Build Phase Script

1. **Select your target** (UroSmart app)
2. **Go to "Build Phases" tab**
3. **Click "+" button** → "New Run Script Phase"
4. **Drag the new script** to the **TOP** (before "Compile Sources")
5. **Name it**: "Start Backend Server"

### 3. Add This Script

```bash
cd "$PROJECT_DIR/.."
./start_server_if_needed.sh
```

### 4. Configure Script Settings

- ✅ **Shell**: `/bin/bash`
- ✅ **Show environment variables in build log**: OFF (optional)
- ✅ **Run script**: For install builds only: OFF
- ✅ **Based on dependency analysis**: OFF

---

## What Happens Now

### When You Launch iOS App from Xcode:

```
1. Xcode starts build
   ↓
2. Runs "Start Backend Server" script
   ↓
3. Script checks if server is running
   │
   ├─ Already running? → Skip, continue build ✅
   │
   └─ Not running? → Start server automatically
      │
      ├─ Detect PostgreSQL or SQLite
      ├─ Auto-migrate data if needed
      ├─ Start Flask server
      └─ Continue with iOS app build
   ↓
4. iOS app launches
   ↓
5. Backend is ready! 🎉
```

### Server Startup Messages

Check Xcode build output for:
```
🚀 Starting UroSmart backend server...
   (PostgreSQL auto-migration enabled)
✅ Server started successfully (PID: 12345)
📝 Logs: /Users/sail/Desktop/UroSmart/server.log
```

---

## Features

✅ **Auto-Start**: Server starts automatically with Xcode  
✅ **Smart Detection**: Doesn't restart if already running  
✅ **PostgreSQL Ready**: Uses new auto-migration system  
✅ **Background Process**: Runs in background, doesn't block build  
✅ **Logging**: All server output saved to `server.log`  

---

## Verification

### Check if Script is Running

After adding the build phase:

1. **Clean build**: Product → Clean Build Folder (⇧⌘K)
2. **Run app**: Product → Run (⌘R)
3. **Check Xcode output** for startup messages
4. **Verify server**:
   ```bash
   curl http://localhost:5000/api/health
   ```

---

## Troubleshooting

### Server Not Starting

**Check build output** in Xcode for error messages

**Check server logs**:
```bash
tail -f /Users/sail/Desktop/UroSmart/server.log
```

### Multiple Instances Running

**Kill all servers**:
```bash
pkill -f "python app.py"
```

**Then run app again** - script will start fresh instance

---

## Manual Control

### Start Server Manually
```bash
cd /Users/sail/Desktop/UroSmart
./start_server_if_needed.sh
```

### Stop Server
```bash
# Find and stop
pkill -f "python app.py"

# Or if you have the PID file
kill $(cat server.pid)
rm server.pid
```

### View Logs
```bash
tail -f /Users/sail/Desktop/UroSmart/server.log
```

---

## Advanced: PostgreSQL vs SQLite

The auto-start script now works with both databases seamlessly:

**Using PostgreSQL**:
- First run: Auto-migrates from SQLite
- Subsequent runs: Uses existing PostgreSQL data

**Using SQLite**:
- Falls back automatically if PostgreSQL unavailable
- No configuration needed

**Switch databases**: Just update `backend/.env`:
```bash
# PostgreSQL
DATABASE_URL=postgresql://sail@localhost/urosmart_db

# SQLite (comment out DATABASE_URL)
# DATABASE_URL=...
```

---

**Setup complete!** Your backend will now start automatically when you launch the iOS app from Xcode. 🚀
