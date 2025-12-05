# Database Locations in UroSmart Project

## 📍 Active Database (PostgreSQL)

### Location
```
/opt/homebrew/var/postgresql@14/
```

This is your **production database** where all current data is stored:
- **Database Name**: `urosmart_db`
- **Connection**: localhost:5432
- **User**: sail
- **Password**: (none)

### Access Methods
1. **Postico** (GUI):
   - Host: localhost
   - Port: 5432
   - User: sail
   - Database: urosmart_db

2. **Command Line**:
   ```bash
   psql urosmart_db
   ```

3. **Python Code**:
   - In `backend/.env`: `DATABASE_URL=postgresql://sail@localhost/urosmart_db`

---

## 📂 Database Schema/Models

### Location in Project
```
/Users/sail/Desktop/UroSmart/backend/app.py
```

**Lines 106-159**: `User` model (database table)
- Stores user accounts (phone, email, password)
- Lines include: id, phone_number, email, password_hash, reset_otp, etc.

**Lines 161-231**: `MedicalReport` model (database table)
- Stores medical scan reports
- Lines include: case_number, yeast_count, calcium_oxalate_count, image_paths, etc.

---

## 🔧 Database Initialization Code

### Location in Project
```
/Users/sail/Desktop/UroSmart/backend/db_init.py
```

This file handles:
- ✅ Auto-creating tables when backend starts
- ✅ Migrating data from SQLite to PostgreSQL (if needed)
- ✅ Database health checks

---

## 📁 Old SQLite Database (Not Active)

### Location
```
/Users/sail/Desktop/UroSmart/backend/instance/urosmart.db
```

- **Size**: 32 KB
- **Status**: ⚠️ No longer used (kept as backup)
- This was used before switching to PostgreSQL

---

## 🗺️ Other Database-Related Files

### Configuration
- `backend/.env` - Database connection string
- `backend/config.py` - Database configuration settings

### Utilities
- `create_tables.py` - Manual table creation script
- `export_database.py` - Export database to JSON
- `import_data.py` - Import data from JSON
- `inspect_db.py` - View database contents
- `verify_data_storage.sh` - Verify database is working

### Backups
- `backup_database.sh` - Create PostgreSQL backup
- `restore_database.sh` - Restore from backup
- `backups/` directory - Stored backup files

---

## 📊 Current Database Stats

You can check your current data with:

```bash
# Connect to database
psql urosmart_db

# View tables
\dt

# Count users
SELECT COUNT(*) FROM users;

# Count reports
SELECT COUNT(*) FROM medical_reports;

# Exit
\q
```

Or use Postico for a visual interface!
