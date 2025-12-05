# Models Directory

Place your trained YOLOv8 models here.

## Expected Files

- `best.pt` - Your trained YOLOv8 model (recommended)
- `last.pt` - Latest checkpoint (backup)

## How to Get Models Here

### Option 1: Train YOLOv8 Model

```bash
# From project root
cd /Users/sail/Desktop/UroSmart

# Convert dataset
python scripts/training/convert_createml_to_yolo.py

# Train model (takes 2-3 hours)
python scripts/training/train_yolo_backend.py

# Deploy automatically
./scripts/deploy_model.sh
```

### Option 2: Manual Copy

If you already trained a model:

```bash
# Copy from training runs
cp /Users/sail/Desktop/UroSmart/runs/urine_detection/weights/best.pt ./best.pt
```

## Model Format

- **Format:** PyTorch (.pt)
- **Framework:** YOLOv8 (Ultralytics)
- **Classes:** yeast, triple_phosphate, calcium_oxalate, squamous_cells
- **Input Size:** 640x640

## Testing

After placing model here, test it:

```bash
cd /Users/sail/Desktop/UroSmart/backend
source .venv311/bin/activate
python test_detection.py
```

## Current Status

- ❌ No model deployed yet
- ⚠️ Backend will use heuristic fallback until model is added
- ✅ Backend code is ready for model integration

## Next Steps

1. Fix dataset issues (see QUICK_FIX_18_PERCENT.md)
2. Train YOLOv8 model with fixed data
3. Deploy model to this directory
4. Test backend detection
