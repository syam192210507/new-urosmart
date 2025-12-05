# UroSmart Application Documentation

This document provides a comprehensive overview of the UroSmart application, detailing its architecture, data flow, requirements, and verification methods.

## 1. Application Overview

UroSmart is a dual-platform system consisting of an **iOS Frontend** and a **Python Backend**. It is designed to analyze medical images (specifically urine microscopy) using Machine Learning (YOLO/TFLite) to detect crystals and cells. The app supports **Offline-First** functionality, allowing users to generate reports without internet, which are then synced to the server when online.

---

## 2. Architecture & Tech Stack

### Frontend (iOS)
-   **Language**: Swift 5
-   **UI Framework**: SwiftUI
-   **Architecture**: MVVM (Model-View-ViewModel)
-   **Local Storage**: `FileManager` (JSON + PDFs), `UserDefaults` (Session state), `Keychain` (Secure tokens).
-   **ML Engine**: TensorFlow Lite (on-device inference).
-   **Networking**: `URLSession` with custom `NetworkService`.

### Backend (Server)
-   **Language**: Python 3.9+
-   **Framework**: Flask
-   **Database**: PostgreSQL (Production), SQLite (Legacy/Migration support).
-   **ML Engine**: TensorFlow Lite (Server-side verification).
-   **Deployment**: Docker, Nginx.

---

## 3. Application Flow (Start to Finish)

### A. App Launch & Authentication
1.  **Entry Point**: `UroSmartApp.swift` is the `@main` entry.
2.  **Session Check**: It checks `UserDefaults.standard.bool(forKey: "isLoggedIn")`.
    -   **If True**: Loads `DashboardView`.
    -   **If False**: Loads `AuthenticationView`.
3.  **Login/Signup**:
    -   User enters credentials in `AuthenticationView` / `SignUpView`.
    -   `AuthService.swift` sends a request to the backend (`/api/login` or `/api/signup`).
    -   **Success**: Backend returns a JWT token.
    -   **Storage**: Token is securely stored in `KeychainManager`. `isLoggedIn` is set to `true`.

### B. Dashboard & Navigation
-   **DashboardView**: The main hub displaying:
    -   **Recent Reports**: Fetched from `ReportStore`.
    -   **Quick Actions**: "New Scan", "History", "Settings".
    -   **Sync Status**: Indicates if local data is synced with the cloud.

### C. Report Generation (The Core Feature)
1.  **Image Capture**: `ScanSubmissionView` opens the camera/gallery.
2.  **Analysis (Local ML)**:
    -   `ImageAnalyzer.swift` passes the image to `TFLiteWrapper.swift`.
    -   **Model**: `best.tflite` (YOLOv5 converted model) runs on-device.
    -   **Detection**: Identifies classes like `yeast`, `calcium_oxalate`, `uric_acid`, etc.
3.  **Report Creation**:
    -   Results are compiled into a `ReportModel`.
    -   `PDFReportGenerator.swift` creates a PDF version of the report.
4.  **Storage (Local)**:
    -   `ReportStore.swift` saves the report metadata to `reports.json` in the App Documents directory.
    -   Images and PDFs are saved to `Documents/UroSmartReports/`.
5.  **Sync (Cloud)**:
    -   `ReportSyncService` detects the new report.
    -   If online, it uploads the JSON data and images to the backend (`/api/reports`).
    -   If offline, it queues the sync for later.

### D. Federated Learning (Advanced Feature)
-   **Goal**: Improve the global model without sharing raw user images.
-   **Process**:
    1.  `FederatedBackgroundService` checks for model updates.
    2.  Local model weights are updated based on user corrections (if implemented).
    3.  Weight updates (gradients) are sent to the server, not the images.

---

## 4. Data Storage & Management

### Local Storage (iOS)
The app uses a file-based storage system for portability and offline support.
-   **Location**: `Documents/UroSmartReports/`
-   **Metadata**: `reports.json` contains an array of all report objects.
-   **Files**: Images and generated PDFs are stored as individual files.
-   **Implementation**: `ReportStore.swift` handles reading/writing this JSON file.

### Backend Storage (PostgreSQL)
The server uses a relational database to store user data and synced reports.
-   **Users Table**: Stores `id`, `email`, `password_hash`, `phone_number`.
-   **MedicalReports Table**: Stores report details (`yeast_count`, `confidence`, etc.) and paths to stored images on the server.
-   **Initialization**: `db_init.py` automatically creates tables and migrates data if switching from SQLite.

---

## 5. Requirements & Implementation Details

| Requirement | Implementation | Key Files |
| :--- | :--- | :--- |
| **User Auth** | JWT-based auth. Secure storage in Keychain. | `AuthService.swift`, `KeychainManager.swift`, `app.py` |
| **Offline Mode** | Local `reports.json` acts as the source of truth. Syncs when online. | `ReportStore.swift`, `NetworkService.swift` |
| **ML Detection** | TFLite model runs on CPU/Neural Engine. | `TFLiteWrapper.swift`, `best.tflite` |
| **PDF Generation** | Native `PDFKit` to render HTML-like layouts to PDF. | `PDFReportGenerator.swift` |
| **Data Sync** | Background service checks for unsynced local reports. | `ReportSyncService.swift` |
| **Security** | Passwords hashed (Bcrypt). HTTPS (Nginx). | `app.py`, `nginx.conf` |

---

## 6. How to Check & Verify

### 1. Verify Backend Status
Run the verification script to ensure the server and database are healthy.
```bash
cd backend
python verify_server.py
```
*Expected Output*: "✅ Server is healthy", "✅ Database connection successful".

### 2. Verify ML Model (Server-Side)
Check if the TFLite model is working correctly on the server.
```bash
cd backend
python reproduce_detection.py
```
*Expected Output*: "✅ Model loaded", "✅ Detection successful".

### 3. Verify iOS Local Storage
You can inspect the simulator's file system to see saved reports.
1.  Run the App in Simulator.
2.  Create a report.
3.  Print the path in `ReportStore.swift` (it usually prints to console).
4.  Open that path in Finder to see `reports.json`.

### 4. Verify Sync
1.  Create a report while **Offline** (turn off WiFi on Mac if using Simulator, or toggle Network Link Conditioner).
2.  Verify it appears in "History" in the app.
3.  Go **Online**.
4.  Check the Backend Database:
    ```bash
    # In backend directory
    python inspect_db.py
    ```
    You should see the new report count increase.

---

## 7. Directory Structure Key

```
UroSmart/
├── frontend/UroSmart/
│   ├── AppConfig.swift       # Global settings (API URL)
│   ├── UroSmartApp.swift     # Entry point
│   ├── Views/                # UI Screens (Dashboard, Login, etc.)
│   ├── Services/             # Logic (Auth, Network, ML)
│   └── Models/               # Data structures
├── backend/
│   ├── app.py                # Main Flask Application
│   ├── models/               # Database Models
│   ├── tflite_detector.py    # ML Logic
│   └── instance/             # Database files (SQLite/Logs)
└── docs/                     # Documentation
```
