#!/bin/bash

echo "🔧 Setting up ML Detection for UroSmart Backend"
echo "================================================"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Install basic dependencies first
echo "📥 Installing basic dependencies..."
pip install -q Flask Flask-CORS Flask-SQLAlchemy Flask-Bcrypt Flask-JWT-Extended python-dotenv gunicorn

# Install ML dependencies
echo "📥 Installing ML dependencies (this may take 2-3 minutes)..."
echo "   - Installing Pillow and NumPy..."
pip install -q pillow numpy

echo "   - Installing PyTorch (CPU version)..."
pip install -q torch torchvision --index-url https://download.pytorch.org/whl/cpu

echo "   - Installing Ultralytics (YOLOv8)..."
pip install -q ultralytics

echo ""
echo "✅ ML dependencies installed!"
echo ""

# Test ML libraries
echo "🧪 Testing ML libraries..."
python3 << EOF
try:
    import torch
    print("  ✅ PyTorch:", torch.__version__)
except:
    print("  ❌ PyTorch not available")

try:
    import PIL
    print("  ✅ Pillow:", PIL.__version__)
except:
    print("  ❌ Pillow not available")

try:
    import numpy
    print("  ✅ NumPy:", numpy.__version__)
except:
    print("  ❌ NumPy not available")

try:
    from ultralytics import YOLO
    print("  ✅ Ultralytics (YOLOv8): Available")
except:
    print("  ❌ Ultralytics not available")
EOF

echo ""
echo "🎉 Setup complete!"
echo ""
echo "Next steps:"
echo "  1. Start backend: ./run.sh"
echo "  2. Test detection: curl http://localhost:5000/api/detect/status"
echo "  3. Run iOS app and upload an image"
echo ""
