#!/bin/bash

# UroSmart Backend Startup Script

echo "🚀 Starting UroSmart Backend..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install dependencies
echo "📥 Installing dependencies..."
pip install -q -r requirements.txt

# Create .env if it doesn't exist
if [ ! -f ".env" ]; then
    echo "⚙️  Creating .env file..."
    cp .env.example .env
fi

# Create uploads directory
mkdir -p uploads/images
mkdir -p uploads/reports

# Run the application
echo "✅ Starting Flask server..."
python app.py
