# UroSmart - Urine Microscopy Analysis App

Complete iOS app with backend for automated urine microscopy object detection using YOLOv8.

## 📁 Project Structure

```
UroSmart/
├── UroSmart/                    # iOS app source code
│   ├── ml_training/
│   │   └── best.mlpackage      # Core ML model (offline detection)
│   └── [Swift files]
├── UroSmart.xcodeproj/          # Xcode project
├── backend/                     # Python Flask backend
│   ├── app.py                   # Main API server
│   ├── ml_detector.py           # YOLO detection engine
│   ├── models/
│   │   └── best.pt              # YOLO model (5.9 MB)
│   ├── requirements.txt         # Python dependencies
│   └── venv/                    # Virtual environment (created on setup)
├── dataset_yolo/                # Training dataset (optional)
└── scripts/                     # Utility scripts
```

## 🚀 Quick Start

### On a New Mac:

1. **Copy this entire folder** to the new Mac

2. **Run setup script:**
   ```bash
   cd /path/to/UroSmart
   chmod +x SETUP_NEW_MAC.sh
   ./SETUP_NEW_MAC.sh
   ```

3. **Start backend server:**
   ```bash
   cd backend
   source venv/bin/activate
   python3 app.py
   ```
   You should see: `🚀 UroSmart Backend running on http://localhost:5000`

4. **Open iOS app in Xcode:**
   ```bash
   open UroSmart.xcodeproj
   ```
   - Press `Cmd + R` to build and run
   - App will connect to backend automatically

## 📱 Features

- **Object Detection**: Detects 5 types of urine microscopy objects
  - Yeast
  - Triple Phosphate
  - Calcium Oxalate
  - Squamous Cells
  - Uric Acid

- **Dual Model Support**:
  - Backend YOLO model (more accurate, requires server)
  - On-device Core ML model (offline fallback)

- **Report Generation**: Creates PDF reports with detection results

- **Offline/Online**: Works offline with Core ML, syncs with backend when online

## 🔧 Requirements

### Backend:
- Python 3.8+
- pip
- Virtual environment (created automatically)

### iOS:
- Xcode 15.0+
- macOS Sonoma or later
- iOS 16.0+ device or simulator

## 📚 Documentation

- **BACKEND_EXPLAINED.md** - Complete backend architecture guide
- **MODEL_CONNECTION_GUIDE.md** - How to connect and use models

## 🔗 API Endpoints

- `GET /api/health` - Health check
- `POST /api/detect` - Object detection (main endpoint)
- `GET /api/detect/status` - Check detection availability
- `POST /api/auth/signup` - User registration
- `POST /api/auth/login` - User login
- `POST /api/reports` - Create report
- `GET /api/reports` - Get all reports

## 🧠 Models

### YOLO Model (Backend)
- **Location**: `backend/models/best.pt`
- **Size**: 5.9 MB
- **Format**: PyTorch (Ultralytics YOLOv8)
- **Used by**: Backend API for detection

### Core ML Model (iOS)
- **Location**: `UroSmart/ml_training/best.mlpackage`
- **Used by**: iOS app for offline detection
- **Note**: Must be included in Xcode target membership

## 🐛 Troubleshooting

### Backend won't start
```bash
cd backend
source venv/bin/activate
pip install -r requirements.txt
pip install ultralytics torch pillow numpy
python3 app.py
```

### iOS app can't connect
- Make sure backend is running on port 5000
- Check `AppConfig.swift` - should use `http://localhost:5000` for simulator
- For real device, use your Mac's IP address

### No detections
- Verify backend is running: `curl http://localhost:5000/api/detect/status`
- Check backend console for errors
- Verify model file exists: `ls -lh backend/models/best.pt`

## 📝 License

[Your License Here]

## 👤 Author

[Your Name]
