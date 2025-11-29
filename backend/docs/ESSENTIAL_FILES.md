# Essential Files for Transfer

## ✅ MUST KEEP (Essential)

### iOS App
- `UroSmart/` - All Swift source files
- `UroSmart.xcodeproj/` - Xcode project (except xcuserdata)
- `UroSmart/ml_training/best.mlpackage/` - Core ML model

### Backend
- `backend/app.py` - Main Flask server
- `backend/ml_detector.py` - YOLO detection engine
- `backend/federated_server.py` - Federated learning server
- `backend/federated_learning.py` - Federated learning manager
- `backend/models/best.pt` - YOLO model (5.9 MB) ⭐
- `backend/requirements.txt` - Python dependencies
- `backend/config.py` - Configuration

### Setup Scripts
- `SETUP_NEW_MAC.sh` - Setup script for new Mac
- `CLEANUP_AND_PACKAGE.sh` - Cleanup script
- `START_BACKEND_NOW.sh` - Quick backend starter

### Documentation
- `README.md` - Main documentation
- `BACKEND_EXPLAINED.md` - Backend guide
- `MODEL_CONNECTION_GUIDE.md` - Model connection guide

### Dataset (Optional - for retraining)
- `dataset_yolo/` - Training dataset

---

## ❌ CAN REMOVE (Not Essential)

### Virtual Environments
- `venv/` - Will be recreated
- `backend/venv/` - Will be recreated

### Training Artifacts
- `runs/` - Old training runs
- `training_output.log` - Training logs
- `training_pid.txt` - Process IDs
- `TRAINING_STATUS_NOW.txt` - Status files

### Python Cache
- `__pycache__/` - Python cache
- `*.pyc` - Compiled Python files

### Old Documentation (100+ files)
- All `.md` files except the 4 essential ones listed above

### Temporary Scripts
- `check_training_status.py`
- `quick_train.py`
- `resume_training.py`
- `train_new_model.py`
- All training-related `.sh` scripts

### Old Models
- `yolov8n.pt` - Base YOLO model (not needed)
- `Models/` - Old model directory

### Xcode User Data
- `UroSmart.xcodeproj/xcuserdata/` - User-specific settings

### Database
- `backend/instance/urosmart.db` - Will be recreated

### Uploads
- `backend/uploads/images/*` - User uploads
- `backend/uploads/reports/*` - Generated reports

### macOS System Files
- `.DS_Store`
- `._*` files

---

## 📦 Final Package Size

After cleanup, the project should be approximately:
- **iOS App**: ~50 MB (with Core ML model)
- **Backend Code**: ~5 MB
- **YOLO Model**: ~6 MB
- **Dataset** (optional): ~200 MB
- **Total**: ~60-260 MB (depending on dataset)

---

## 🚀 Transfer Instructions

1. **Run cleanup:**
   ```bash
   cd /Users/sail/Desktop/UroSmart
   ./CLEANUP_AND_PACKAGE.sh
   ```

2. **Copy entire folder** to new Mac (via USB, AirDrop, or cloud)

3. **On new Mac, run setup:**
   ```bash
   cd /path/to/UroSmart
   ./SETUP_NEW_MAC.sh
   ```

4. **Start backend:**
   ```bash
   cd backend
   source venv/bin/activate
   python3 app.py
   ```

5. **Open in Xcode:**
   ```bash
   open UroSmart.xcodeproj
   ```

Done! 🎉

