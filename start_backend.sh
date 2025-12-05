#!/bin/bash
# UroSmart Backend Startup Script
# Automatically handles PostgreSQL and starts the server

echo "🚀 Starting UroSmart Backend..."

# Navigate to backend directory
cd "$(dirname "$0")/backend"

# Activate virtual environment
source venv/bin/activate

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
    echo "⚠️  PostgreSQL not detected. Starting PostgreSQL..."
    brew services start postgresql@14 > /dev/null 2>&1
    
    # Wait for PostgreSQL to be ready (max 30 seconds)
    for i in {1..30}; do
        if pg_isready -q 2>/dev/null; then
            echo "✅ PostgreSQL started successfully"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "❌ PostgreSQL failed to start in time"
            exit 1
        fi
        sleep 1
    done
fi

# Start the Flask app (auto-migration happens inside)
python app.py
