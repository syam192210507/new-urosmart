#!/bin/bash

echo "🚀 Quick ML Setup (with timeout fixes)"
echo "======================================"
echo ""

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "📦 Creating virtual environment..."
    python3 -m venv venv
fi

# Activate virtual environment
echo "🔧 Activating virtual environment..."
source venv/bin/activate

# Increase timeout and use multiple retries
export PIP_DEFAULT_TIMEOUT=100

echo "📥 Installing dependencies (this may take a few minutes)..."
echo ""

# Install in smaller batches to avoid timeouts
echo "  Installing Flask..."
pip install --timeout=100 Flask

echo "  Installing Flask extensions..."
pip install --timeout=100 Flask-CORS Flask-SQLAlchemy Flask-Bcrypt Flask-JWT-Extended

echo "  Installing utilities..."
pip install --timeout=100 python-dotenv gunicorn

echo "  Installing Pillow and NumPy..."
pip install --timeout=100 pillow numpy

echo "  Installing PyTorch (CPU version - this is the big one)..."
pip install --timeout=100 torch torchvision --index-url https://download.pytorch.org/whl/cpu

echo "  Installing Ultralytics..."
pip install --timeout=100 ultralytics

echo ""
echo "✅ Installation complete!"
echo ""

# Test
echo "🧪 Testing installation..."
python3 << EOF
try:
    import torch
    print("  ✅ PyTorch:", torch.__version__)
except:
    print("  ❌ PyTorch failed")

try:
    import PIL
    print("  ✅ Pillow:", PIL.__version__)
except:
    print("  ❌ Pillow failed")

try:
    import numpy
    print("  ✅ NumPy:", numpy.__version__)
except:
    print("  ❌ NumPy failed")

try:
    from ultralytics import YOLO
    print("  ✅ Ultralytics: Available")
except:
    print("  ❌ Ultralytics failed")
EOF

echo ""
echo "🎉 Ready to use!"
echo ""
echo "Start backend: ./run.sh"
echo ""
