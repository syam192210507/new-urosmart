# UroSmart Project Guide

Complete guide to understanding and working with the UroSmart medical imaging application.

---

## 📱 What is UroSmart?

UroSmart is an iOS medical imaging application that uses AI to detect and analyze microscopy images for urinary tract analysis. It works both **online** and **offline**, with automatic data synchronization.

### Key Features
- 🔬 **AI-powered detection** using TensorFlow Lite
- 📴 **Offline-first architecture** - works without internet
- 🔄 **Automatic sync** when online
- 🔐 **Secure authentication** with offline fallback
- 🗄️ **PostgreSQL database** for persistent storage
- 📊 **Medical report generation** with PDF export

---

## 🏗️ Project Architecture

```
UroSmart/
├── frontend/UroSmart/          # iOS Swift app
│   ├── *.swift                 # App code
│   └── best.tflite             # AI model
├── backend/                    # Python Flask API
│   ├── app.py                  # Main API server
│   ├── tflite_detector.py      # ML detection
│   └── models/best.tflite      # AI model
└── Documentation (this file)
```

### How It Works

1. **iOS App** captures/selects microscopy image
2. **Local AI Model** runs detection on-device (offline capable)
3. **Report Generated** with detection results
4. **Backend Sync** uploads to server when online
5. **PostgreSQL Database** stores all data permanently

---

## 🔧 How the Backend Works

### Technology Stack
- **Framework**: Flask (Python web framework)
- **Database**: PostgreSQL (with SQLite fallback)
- **ORM**: SQLAlchemy (Python ↔ SQL conversion)
- **Authentication**: JWT tokens + Bcrypt password hashing
- **ML**: TensorFlow Lite for detection

### Key Components

#### 1. Database Models (Defined in Python)
Location: `backend/app.py` lines 106-231
- **User** model: Stores user accounts
- **MedicalReport** model: Stores scan reports

#### 2. API Endpoints
Location: `backend/app.py` lines 265-715
- `/api/auth/signup` - User registration
- `/api/auth/login` - User login
- `/api/reports` - Create/get medical reports
- `/api/detect` - ML detection endpoint

#### 3. Auto-Start PostgreSQL
Location: `start_backend.sh`
- Checks if PostgreSQL is running
- Starts it automatically if not
- Waits for database to be ready
- Launches Flask server

---

## 💾 How Data is Stored

**Complete details**: See [`HOW_DATA_IS_STORED.md`](file:///Users/sail/Desktop/UroSmart/HOW_DATA_IS_STORED.md)

### Quick Summary

**No SQL files needed!** Everything uses Python code:

```python
# Define structure (app.py)
class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email = db.Column(db.String(120))

# Save data
user = User(email='test@gmail.com')
db.session.add(user)
db.session.commit()  # ← Saved to PostgreSQL!
```

SQLAlchemy automatically converts Python → SQL → PostgreSQL

### Database Locations
**Complete details**: See [`DATABASE_LOCATIONS.md`](file:///Users/sail/Desktop/UroSmart/DATABASE_LOCATIONS.md)

- **Active DB**: `/opt/homebrew/var/postgresql@14/` (PostgreSQL)
- **Old SQLite**: `backend/instance/urosmart.db` (backup, not used)
- **Access**: `psql urosmart_db` or Postico at `localhost:5432`

---

## 🚀 Development Workflow

### Starting the Backend

**Option 1: Manual Start**
```bash
cd /Users/sail/Desktop/UroSmart
./start_backend.sh
```

**Option 2: Auto-Start from Xcode**
See [`XCODE_AUTOSTART_SETUP.md`](file:///Users/sail/Desktop/UroSmart/XCODE_AUTOSTART_SETUP.md)
- Backend starts automatically when you run the iOS app
- No need to manually start server

### Development Tools

#### Database Management
```bash
# View database
psql urosmart_db

# Backup database
./backup_database.sh

# Restore database
./restore_database.sh
```

#### Viewing Data
```bash
# Check database contents
python inspect_db.py

# Export to JSON
python export_database.py

# Import from JSON
python import_data.py
```

---

## 🧪 Testing

### Backend API Testing
```bash
# Health check
curl http://localhost:5000/api/health

# Test signup
curl -X POST http://localhost:5000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{"phone_number":"1234567890","email":"test@gmail.com","password":"test123"}'

# Test detection
curl -X POST http://localhost:5000/api/detect \
  -F "file=@image.jpg"
```

### iOS App Testing
1. Run from Xcode (⌘R)
2. Backend auto-starts
3. Test offline: Turn off WiFi, app still works
4. Test online: Turn on WiFi, data syncs automatically

---

## 📦 Deployment

**Complete guide**: See [`COLLEGE_DEPLOYMENT_GUIDE.md`](file:///Users/sail/Desktop/UroSmart/COLLEGE_DEPLOYMENT_GUIDE.md)

### Quick Deployment Package
```bash
# Use pre-built package
cd /Users/sail/Desktop/UroSmart
zip -r deployment.zip deployment_package/
# Send deployment.zip to server
```

### Server Requirements
- Python 3.11+
- PostgreSQL 14+ (or SQLite for testing)
- 512 MB RAM minimum
- 500 MB storage

---

## 🔑 Important Files Reference

### Essential Scripts
- **`start_backend.sh`** - Main backend startup (auto-starts PostgreSQL)
- **`start_server_if_needed.sh`** - Auto-start script for Xcode
- **`backup_database.sh`** - Database backup utility
- **`restore_database.sh`** - Database restore utility

### Essential Documentation
- **`README.md`** - Project overview
- **`HOW_DATA_IS_STORED.md`** - Data storage explanation
- **`DATABASE_LOCATIONS.md`** - Where databases are located
- **`XCODE_AUTOSTART_SETUP.md`** - Auto-start configuration
- **`COLLEGE_DEPLOYMENT_GUIDE.md`** - Deployment instructions
- **`backend/README.md`** - Backend API documentation

### Key Code Files
- **`backend/app.py`** - Main Flask application and API
- **`backend/db_init.py`** - Database initialization
- **`backend/tflite_detector.py`** - ML detection logic
- **`backend/config.py`** - Configuration settings
- **`frontend/UroSmart/NetworkService.swift`** - API client
- **`frontend/UroSmart/AuthService.swift`** - Authentication logic
- **`frontend/UroSmart/ReportStore.swift`** - Local data storage

---

## 🆘 Common Issues

### Backend won't start
```bash
# Check if PostgreSQL is running
psql postgres -c "SELECT version();"

# If not, start it
brew services start postgresql@14

# Then start backend
./start_backend.sh
```

### Database connection error
```bash
# PostgreSQL should auto-start now
# If it doesn't, check:
tail -f /opt/homebrew/var/log/postgresql@14.log
```

### Port 5000 already in use
```bash
# Kill existing server
pkill -f "python app.py"

# Or use different port
# In backend/.env: PORT=5001
```

---

## 📞 Quick Reference

| What | Where |
|------|-------|
| Backend API | http://localhost:5000 |
| PostgreSQL | localhost:5432 |
| Database Name | urosmart_db |
| Backend Code | `backend/app.py` |
| iOS App Code | `frontend/UroSmart/*.swift` |
| AI Model | `backend/models/best.tflite` |
| Database Location | `/opt/homebrew/var/postgresql@14/` |

---

**Last Updated**: December 3, 2025
