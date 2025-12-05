#!/bin/bash
# Auto-start UroSmart backend server when launching iOS app from Xcode
# Now with automatic PostgreSQL detection and migration!
# WARNING: This script MUST exit with 0 to avoid breaking Xcode builds

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
LOG_FILE="$PROJECT_DIR/server.log"
PID_FILE="$PROJECT_DIR/server.pid"

# Export PATH to ensure tools like lsof, pgrep, brew are found in Xcode environment
export PATH=$PATH:/usr/local/bin:/opt/homebrew/bin:/usr/sbin:/sbin:/bin:/usr/bin

# Debug logging
exec 1>>"$PROJECT_DIR/xcode_debug.log" 2>&1
echo "--- Script started at $(date) ---"
echo "PATH: $PATH"
echo "PWD: $(pwd)"

# Check if server is already running
if [ -f "$PID_FILE" ]; then
    PID=$(cat "$PID_FILE")
    if ps -p "$PID" > /dev/null 2>&1; then
        echo "✅ Server already running (PID: $PID)"
        exit 0
    else
        # PID file exists but process is dead, clean it up
        rm "$PID_FILE"
    fi
fi

# Check if port 5000 is in use
if lsof -Pi :5000 -sTCP:LISTEN -t >/dev/null 2>&1; then
    echo "✅ Server already running on port 5000"
    exit 0
fi

echo "🚀 Attempting to start UroSmart backend server..."

# Verify backend directory exists
if [ ! -d "$BACKEND_DIR" ]; then
    echo "⚠️  Backend directory not found: $BACKEND_DIR"
    echo "   Xcode build will continue, but backend won't start"
    exit 0  # Don't fail the build
fi

cd "$BACKEND_DIR" || {
    echo "❌ Failed to cd to backend directory"
    exit 0  # Don't fail the build
}

# Check if virtual environment exists
if [ ! -f "venv/bin/activate" ]; then
    echo "⚠️  Virtual environment not found at $BACKEND_DIR/venv"
    echo "   Run: python3 -m venv venv && source venv/bin/activate && pip install -r requirements.txt"
    exit 0  # Don't fail the build
fi

# Activate virtual environment
source venv/bin/activate || {
    echo "❌ Failed to activate virtual environment"
    exit 0  # Don't fail the build
}

# Load environment variables from .env
if [ -f .env ]; then
    echo "📝 Loading environment variables from .env"
    set -a
    source .env
    set +a
fi

# Ensure PostgreSQL is running (auto-start if needed)
if pgrep -x "postgres" > /dev/null; then
    echo "✅ PostgreSQL is running"
else
    echo "⚠️  PostgreSQL not detected. Attempting to start..."
    
    # Try to start PostgreSQL (don't fail if it doesn't work)
    if command -v brew > /dev/null 2>&1; then
        brew services start postgresql@14 > /dev/null 2>&1 || true
        
        # Wait for PostgreSQL to be ready (max 10 seconds, reduced from 30)
        for i in {1..10}; do
            if command -v pg_isready > /dev/null 2>&1 && pg_isready -q 2>/dev/null; then
                echo "✅ PostgreSQL started successfully"
                break
            fi
            if [ $i -eq 10 ]; then
                echo "⚠️  PostgreSQL not ready after 10 seconds"
                echo "   Backend may use SQLite instead"
            fi
            sleep 1
        done
    else
        echo "⚠️  Homebrew not found, cannot auto-start PostgreSQL"
        echo "   Backend may use SQLite instead"
    fi
fi

# Check if app.py exists
if [ ! -f "app.py" ]; then
    echo "❌ app.py not found in $BACKEND_DIR"
    exit 0  # Don't fail the build
fi

# Start the server
echo "   Starting Python backend..."
nohup python app.py > "$LOG_FILE" 2>&1 &
SERVER_PID=$!

# Save PID
echo "$SERVER_PID" > "$PID_FILE"

# Wait a moment and check if it started successfully
sleep 2

if ps -p "$SERVER_PID" > /dev/null 2>&1; then
    echo "✅ Server started successfully (PID: $SERVER_PID)"
    echo "📝 Logs: $LOG_FILE"
else
    echo "❌ Server failed to start. Check logs: $LOG_FILE"
    rm "$PID_FILE" 2>/dev/null
    echo "   (Xcode build will continue anyway)"
fi

# Always exit with success to avoid breaking Xcode builds
exit 0
