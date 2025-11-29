#!/bin/bash
# Quick Start Script for UroSmart Backend

echo "🚀 Starting UroSmart Backend..."
echo ""

# Navigate to backend directory
cd "$(dirname "$0")"

# Check if venv exists
if [ ! -d "venv" ]; then
    echo "❌ Virtual environment not found!"
    echo "Creating venv..."
    python3 -m venv venv
fi

# Activate venv
echo "📦 Activating virtual environment..."
source venv/bin/activate

# Check if ML libraries are installed
echo "🔍 Checking ML dependencies..."
python -c "import ultralytics" 2>/dev/null
if [ $? -ne 0 ]; then
    echo "⚠️  ML libraries not installed. Installing now..."
    echo "This may take a few minutes..."
    pip install ultralytics pillow numpy torch torchvision
fi

# Check if model exists
if [ ! -f "models/best.pt" ]; then
    echo "❌ Model not found at models/best.pt"
    echo "Checking for trained model..."
    
    MODEL_PATH="../UroSmart/ml_training/runs/detect/urine_microscopy_resume/weights/best.pt"
    if [ -f "$MODEL_PATH" ]; then
        echo "✅ Found trained model, copying..."
        cp "$MODEL_PATH" models/best.pt
    else
        echo "⚠️  No trained model found. Detection will use fallback mode."
    fi
fi

# Install Flask dependencies if needed
echo "📦 Installing Flask dependencies..."
pip install -q -r requirements.txt

# Start the backend
echo ""
echo "✅ Starting Flask backend on http://localhost:5000"
echo "📊 ML Detection: $([ -f 'models/best.pt' ] && echo 'ENABLED ✅' || echo 'FALLBACK MODE ⚠️')"
echo ""
echo "Press Ctrl+C to stop the server"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

python app.py
