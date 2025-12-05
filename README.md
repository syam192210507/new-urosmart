# UroSmart Project

UroSmart is an advanced iOS application for automated urine microscopy analysis using machine learning.

## Project Structure

The project is organized into the following directories:

### 📱 `ios/`
Contains the iOS application source code, Xcode project, and workspace.
- **UroSmart/**: Swift source code
- **UroSmart.xcworkspace**: Open this file in Xcode to work on the app
- **Pods/**: CocoaPods dependencies

### 🖥️ `server/`
Contains the Python backend API for user authentication and online analysis.
- **app.py**: Flask application entry point
- **tflite_detector.py**: ML inference logic
- **models/**: Contains `best.tflite` model

### 🤖 `ml/`
Contains machine learning training scripts, datasets, and models.
- **training/**: Scripts to train YOLO models
- **datasets/**: Training data (images and labels)
- **models/**: Base models (e.g., `yolov8n.pt`)

### 📚 `docs/`
Contains project documentation.
- **ESSENTIAL_FILES.md**: Guide to critical files
- **README.md**: Original project documentation

## Getting Started

### iOS App
1. Navigate to `ios/`
2. Run `pod install` (if needed)
3. Open `UroSmart.xcworkspace`
4. Build and run

### Backend Server
1. Navigate to `server/`
2. Install dependencies: `pip install -r requirements.txt`
3. Run server: `python app.py`

### ML Training
1. Navigate to `ml/training/`
2. Run training scripts as needed
