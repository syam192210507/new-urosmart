# ML Object Detection Guide

Backend-based object detection for urine microscopy images.

---

## 🎯 Overview

Your backend now supports **ML-based object detection** that can:
- Detect 4 object types: yeast, triple phosphate, calcium oxalate, squamous cells
- Use YOLOv8 or TensorFlow models
- Fall back to heuristic detection if no model available
- Return detection counts and confidence scores

---

## 🚀 Quick Setup

### Step 1: Install ML Dependencies

```bash
cd /Users/sail/Desktop/UroSmart/backend
source venv/bin/activate
pip install ultralytics pillow numpy
```

**Note:** This will download PyTorch (~2GB). For faster setup without GPU:
```bash
pip install ultralytics pillow numpy --extra-index-url https://download.pytorch.org/whl/cpu
```

### Step 2: Add Your Trained Model (Optional)

If you have a trained YOLOv8 model:

```bash
mkdir -p backend/models
cp your_trained_model.pt backend/models/urine_detector.pt
```

The detector will automatically find models in these locations:
- `models/urine_detector.pt`
- `models/best.pt`
- `models/urine_detector.h5` (TensorFlow)

### Step 3: Start Backend

```bash
cd backend
./run.sh
```

You'll see:
```
🔍 ML Library Status:
  YOLOv8 (ultralytics): ✅ Available
  TensorFlow: ❌ Not installed
  PyTorch: ✅ Available
```

### Step 4: Test Detection

```bash
# Check if detection is available
curl http://localhost:5000/api/detect/status

# Test with an image (after logging in)
curl -X POST http://localhost:5000/api/detect \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@path/to/microscopy_image.jpg" \
  -F "confidence=0.25"
```

---

## 📱 iOS Integration

### Use Backend Detection in Your App

```swift
import UIKit

// Convert UIImage to Data
guard let imageData = image.jpegData(compressionQuality: 0.8) else {
    return
}

// Call backend detection
Task {
    do {
        let results = try await NetworkService.shared.detectObjects(
            in: imageData,
            confidence: 0.25
        )
        
        // Use results
        print("Total objects detected: \(results.total_objects)")
        print("Yeast: \(results.results.yeast.count) (confidence: \(results.results.yeast.confidence))")
        print("Triple Phosphate: \(results.results.triple_phosphate.count)")
        print("Calcium Oxalate: \(results.results.calcium_oxalate.count)")
        print("Squamous Cells: \(results.results.squamous_cells.count)")
        
        if let warning = results.warning {
            print("⚠️ \(warning)")
        }
        
    } catch {
        print("Detection failed: \(error)")
    }
}
```

### Hybrid Approach: On-Device + Backend Fallback

```swift
func analyzeImage(_ image: UIImage) async -> AnalysisResult {
    // Try on-device first
    let localAnalyzer = ImageAnalyzer()
    let localResult = localAnalyzer.analyze(image)
    
    // If on-device model is available, use it
    if localResult.confidence > 0.5 {
        return localResult
    }
    
    // Otherwise, try backend detection
    do {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            return localResult
        }
        
        let backendResults = try await NetworkService.shared.detectObjects(
            in: imageData,
            confidence: 0.25
        )
        
        // Convert backend results to AnalysisResult
        return convertToAnalysisResult(backendResults)
        
    } catch {
        print("Backend detection failed, using local: \(error)")
        return localResult
    }
}

func convertToAnalysisResult(_ detection: DetectionResults) -> AnalysisResult {
    return AnalysisResult(
        yeast: ObjectDetection(
            name: "Yeast",
            present: detection.results.yeast.present,
            count: detection.results.yeast.count,
            confidence: detection.results.yeast.confidence
        ),
        triplePhosphate: ObjectDetection(
            name: "Triple Phosphate",
            present: detection.results.triple_phosphate.present,
            count: detection.results.triple_phosphate.count,
            confidence: detection.results.triple_phosphate.confidence
        ),
        calciumOxalate: ObjectDetection(
            name: "Calcium Oxalate",
            present: detection.results.calcium_oxalate.present,
            count: detection.results.calcium_oxalate.count,
            confidence: detection.results.calcium_oxalate.confidence
        ),
        squamousCells: ObjectDetection(
            name: "Squamous Cells",
            present: detection.results.squamous_cells.present,
            count: detection.results.squamous_cells.count,
            confidence: detection.results.squamous_cells.confidence
        )
    )
}
```

---

## 🔧 Training Your Own Model

### Option 1: Use Existing Create ML Model

Convert your Core ML model to ONNX, then to PyTorch:

```bash
# Install coremltools
pip install coremltools onnx

# Convert (Python script)
python3 << EOF
import coremltools as ct
import onnx

# Load Core ML model
model = ct.models.MLModel('UrineMicroscopyDetector.mlmodel')

# Convert to ONNX
model.export('model.onnx')

# Then use ultralytics to convert ONNX to PyTorch
from ultralytics import YOLO
model = YOLO('model.onnx')
model.export(format='torchscript')
EOF
```

### Option 2: Train YOLOv8 from Scratch

```bash
# Install ultralytics
pip install ultralytics

# Prepare dataset in YOLO format
# dataset/
#   images/
#     train/
#     val/
#   labels/
#     train/
#     val/
#   data.yaml

# Train
yolo detect train data=dataset/data.yaml model=yolov8n.pt epochs=100 imgsz=640
```

Your `data.yaml`:
```yaml
path: /path/to/dataset
train: images/train
val: images/val

nc: 4  # number of classes
names: ['yeast', 'triple_phosphate', 'calcium_oxalate', 'squamous_cells']
```

### Option 3: Use Roboflow

1. Upload images to [roboflow.com](https://roboflow.com)
2. Annotate objects
3. Export as YOLOv8 format
4. Download and train:

```bash
# Download from Roboflow
curl -L "YOUR_ROBOFLOW_DOWNLOAD_LINK" > dataset.zip
unzip dataset.zip

# Train
yolo detect train data=data.yaml model=yolov8n.pt epochs=100
```

---

## 📊 API Reference

### POST /api/detect

Detect objects in microscopy image.

**Headers:**
```
Authorization: Bearer <token>
Content-Type: multipart/form-data
```

**Body:**
```
file: <image_file>
confidence: 0.25 (optional, default 0.25)
```

**Response:**
```json
{
  "message": "Detection completed",
  "detection_results": {
    "success": true,
    "total_objects": 18,
    "method": "yolo",
    "results": {
      "yeast": {
        "present": true,
        "count": 5,
        "confidence": 0.892
      },
      "triple_phosphate": {
        "present": true,
        "count": 3,
        "confidence": 0.765
      },
      "calcium_oxalate": {
        "present": true,
        "count": 8,
        "confidence": 0.834
      },
      "squamous_cells": {
        "present": true,
        "count": 2,
        "confidence": 0.701
      }
    }
  }
}
```

### GET /api/detect/status

Check if ML detection is available.

**Response:**
```json
{
  "available": true,
  "libraries": {
    "yolo": true,
    "tensorflow": false,
    "torch": true
  },
  "message": "ML detection is available"
}
```

---

## 🎯 Detection Modes

### 1. YOLOv8 (Recommended)
- **Pros:** Fast, accurate, easy to train
- **Cons:** Requires PyTorch (~2GB)
- **Setup:** `pip install ultralytics`

### 2. TensorFlow
- **Pros:** Widely supported
- **Cons:** Slower than YOLOv8
- **Setup:** `pip install tensorflow`

### 3. Heuristic Fallback
- **Pros:** No dependencies, always works
- **Cons:** Not accurate, just estimates
- **When:** Automatically used if no model available

---

## 🔍 Troubleshooting

### ML libraries not installing

**Error:** `torch` installation fails

**Solution:**
```bash
# Install CPU-only version (smaller, faster)
pip install torch torchvision --index-url https://download.pytorch.org/whl/cpu
pip install ultralytics
```

### Model not loading

**Error:** Model file not found

**Solution:**
```bash
# Check model path
ls -la backend/models/

# Create models directory
mkdir -p backend/models

# Copy your model
cp your_model.pt backend/models/urine_detector.pt
```

### Detection returns heuristic results

**Cause:** No trained model available

**Solution:**
- Train a model (see Training section)
- Or use on-device Core ML detection
- Heuristic mode still works for testing

### Out of memory errors

**Solution:**
```bash
# Use smaller YOLOv8 model
yolo detect train model=yolov8n.pt  # nano (smallest)
# vs
yolo detect train model=yolov8s.pt  # small
yolo detect train model=yolov8m.pt  # medium
```

---

## 📈 Performance

### Detection Speed
- **YOLOv8n (nano):** ~50-100ms per image
- **YOLOv8s (small):** ~100-200ms per image
- **Heuristic:** ~10-20ms per image

### Accuracy (with trained model)
- **YOLOv8:** 85-95% mAP with good dataset
- **Heuristic:** Not accurate, just estimates

### Resource Usage
- **Memory:** 500MB - 2GB (depending on model)
- **Disk:** 6MB (nano) - 50MB (large)
- **CPU:** 1-2 cores during inference

---

## ✅ Summary

You now have:
- ✅ Backend ML detection endpoint
- ✅ YOLOv8 integration
- ✅ Heuristic fallback
- ✅ iOS NetworkService methods
- ✅ Hybrid detection approach

**Next steps:**
1. Install ML dependencies: `pip install ultralytics pillow numpy`
2. Test detection: `curl http://localhost:5000/api/detect/status`
3. Use in iOS app with `NetworkService.shared.detectObjects()`
4. Train your own model for better accuracy

---

**Questions?** Check the main backend README or test with the provided examples!
