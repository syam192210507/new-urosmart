# UroSmart - iOS Urine Microscopy Analysis App

**iOS app for analyzing urine microscopy images offline using on-device Core ML.**

## 🚀 Quick Start

```bash
# Open in Xcode
open /Users/sail/Desktop/UroSmart/UroSmart.xcodeproj
# Press Cmd+R to run
```

## Features

### 🔬 Object Detection
Detects and reports presence/absence of:
- **Yeast**
- **Triple Phosphate**
- **Calcium Oxalate**
- **Squamous Cells**

### 📱 Offline Operation
- All processing happens on-device
- No internet connection required
- Privacy-focused: images never leave the device

### 📄 PDF Reports
- Generates professional medical reports
- Shows per-object detection results (Present/Absent)
- Includes microscopy images
- Stores locally for offline access

### 💾 Local Storage
- Reports saved in `Documents/UroSmartReports/`
- Persistent metadata in JSON format
- Easy access via iOS Files app

### 📤 Export & Share
- Download reports as PDF
- Share via Mail, AirDrop, Files
- Compatible with all iOS sharing options

---

## App Structure

### Views
- **`AuthenticationView.swift`**: Login/signup flow
- **`DashboardView.swift`**: Main navigation hub
- **`ScanSubmissionView.swift`**: Image upload and analysis
- **`MedicalReportsView.swift`**: Report listing and download

### Core Components
- **`ImageAnalyzer.swift`**: Core ML object detection engine
- **`PDFReportGenerator.swift`**: PDF creation with detailed results
- **`ReportStore.swift`**: Local persistence layer
- **`ReportModel.swift`**: Data structures for reports
- **`NetworkService.swift`**: Offline authentication

---

## How It Works

### 1. Submit Scan
1. User uploads 1-2 microscopy images
2. Enters case number for identification
3. Taps "Submit Scan"

### 2. Analysis
1. Image processed by `ImageAnalyzer`
2. Uses Core ML trained detector
3. Returns per-object detection results (Present/Absent)

### 3. Report Generation
1. Creates PDF with:
   - Case number and date
   - Per-object presence/absence
   - Detection counts and confidence
   - Original microscopy images
2. Saves to local storage

### 4. View & Download
1. Reports listed by date
2. Filter by case number
3. Tap "Download Report" to share PDF

---

## Core ML Model

### Model Requirements
- **Name**: `UrineMicroscopyDetector.mlmodel`
- **Input**: RGB image (416x416 or 640x640)
- **Output**: Object detections with bounding boxes
- **Classes**: yeast, triple_phosphate, calcium_oxalate, squamous_cells

The model file should be added to the Xcode project.

---

## Technical Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **ML**: Core ML + Vision framework
- **PDF**: UIKit PDFRenderer
- **Storage**: FileManager + JSON
- **Minimum iOS**: 16.0+

---

## Project Setup

### Requirements
- Xcode 15.0+
- macOS Sonoma or later
- iOS 16.0+ device or simulator

### Build & Run
1. Open project in Xcode
2. Select target device/simulator
3. Press `Cmd + R` to build and run
4. No additional dependencies required

---

## File Structure

```
UroSmart/
├── AuthenticationView.swift      # Main app flow
├── ContentView.swift              # Login view
├── DashboardView.swift            # Main menu
├── ScanSubmissionView.swift      # Image upload & analysis
├── MedicalReportsView.swift      # Report listing
├── SignUpView.swift               # User registration
├── ReportPreviewView.swift        # Report preview
├── ImageAnalyzer.swift            # Core ML detection engine
├── PDFReportGenerator.swift      # PDF creation
├── ReportStore.swift              # Local persistence
├── ReportModel.swift              # Data models
├── NetworkService.swift           # Offline auth
├── ShareSheet.swift               # iOS share integration
└── README.md                      # This file
```

---

## Usage Guide

### For Medical Professionals
1. **Login**: Use existing credentials or create account
2. **New Scan**: 
   - Tap "Upload medical scans for analysis"
   - Select microscopy image(s)
   - Enter case number
   - Submit for analysis
3. **View Results**: 
   - Tap "View and download patient reports"
   - Select date to filter
   - Review detection results
4. **Export**: 
   - Tap "Download Report"
   - Share via email, AirDrop, or save to Files

### For Developers
1. **Add model**: Place `UrineMicroscopyDetector.mlmodel` in Xcode project
2. **Customize**: Modify detection logic in `ImageAnalyzer.swift`
3. **Extend**: Add more object types or analysis features

---

## Data Privacy

- ✅ All processing on-device
- ✅ No cloud uploads
- ✅ No analytics tracking
- ✅ Local storage only
- ✅ User controls all data

---


---

## Troubleshooting

### App Issues
**Problem**: Analysis takes too long  
**Solution**: Reduce image size before upload or use smaller ML model

**Problem**: Reports not showing  
**Solution**: Check `Documents/UroSmartReports/` exists and has read permissions

**Problem**: PDF won't open  
**Solution**: Ensure iOS version 16.0+, try different PDF viewer

### Model Issues
**Problem**: Model not loading  
**Solution**: Verify filename is `UrineMicroscopyDetector.mlmodel` and in bundle

**Problem**: Poor detection accuracy  
**Solution**: Check model training data quality

**Problem**: Wrong objects detected  
**Solution**: Check label mapping in `ImageAnalyzer.swift`

---

## Contributing

### Code Style
- Follow Swift naming conventions
- Use SwiftUI best practices
- Comment complex logic
- Keep functions focused and small

### Testing
- Test on real iOS devices
- Validate with actual microscopy images
- Check PDF generation on different iOS versions
- Verify offline functionality (airplane mode)

---

## License

This project is for educational and research purposes. Consult with medical professionals before clinical use.

---

## Acknowledgments

- Core ML and Vision framework by Apple
- SwiftUI for modern iOS development
- Medical professionals for domain expertise

---

---

**Version**: 2.0.0  
**Last Updated**: 2025-11-04  
**Platform**: iOS 16.0+
