# 🗄️ Database Management Quick Reference

## Current Database Status

```
Database: urosmart_db
Type: PostgreSQL
Location: localhost:5432
Username: sail
Tables: users, medical_reports
```

---

## Quick Commands

### Check Database Status
```bash
cd /Users/sail/Desktop/UroSmart
python3 inspect_database.py
```

### Connect to Database (Command Line)
```bash
psql -U sail -d urosmart_db
```

### View All Users (psql)
```sql
SELECT id, email, phone_number, created_at FROM users;
```

### View All Reports (psql)
```sql
SELECT id, user_id, case_number, report_date FROM medical_reports;
```

---

## GUI Tools Connection

### **pgAdmin 4**
1. Create new server: "UroSmart Local"
2. Host: `localhost`, Port: `5432`
3. Username: `sail`, Password: (empty)
4. Database: `urosmart_db`

### **Postico**
1. New Favorite: "UroSmart Local"
2. Host: `localhost`, Port: `5432`
3. User: `sail`, Password: (empty)
4. Database: `urosmart_db`

---

## Testing Account Deletion

### Step 1: Create Test User in App
1. Open iOS app
2. Sign up with: `test@gmail.com` / `1234567890` / password
3. Create a medical report

### Step 2: Check Database Before Deletion
```bash
python3 inspect_database.py
```
You should see:
- ✅ 1 user (test@gmail.com)
- ✅ 1 report linked to that user

### Step 3: Delete Account in App
1. Go to Profile
2. Click "Delete Account"
3. Confirm deletion

### Step 4: Verify Deletion
```bash
python3 inspect_database.py
```
You should see:
- ✅ 0 users
- ✅ 0 reports (cascade deleted)
- ✅ No orphaned data

---

## What Account Deletion Should Remove

### From Database (✅ Verified by test):
- ✅ User record from `users` table
- ✅ All user's reports from `medical_reports` (cascade)
- ✅ All foreign key references cleaned up

### From iOS App:
- ✅ Cached user data
- ✅ Login credentials (keychain)
- ✅ Local reports
- ✅ Access tokens
- ✅ User session

---

## Database Relationship

```
users (parent)
  └─ id (PRIMARY KEY)
      ↓
      └─ CASCADE DELETE
          ↓
medical_reports (child)
  └─ user_id (FOREIGN KEY → users.id)
```

**Cascade Delete:** When you delete a user, all their reports are automatically deleted.

---

## Common Queries

### Find User by Email
```sql
SELECT * FROM users WHERE email = 'test@gmail.com';
```

### Count Reports per User
```sql
SELECT 
    u.email,
    COUNT(mr.id) as report_count
FROM users u
LEFT JOIN medical_reports mr ON u.id = mr.user_id
GROUP BY u.id, u.email;
```

### Delete User Manually (with cascade)
```sql
DELETE FROM users WHERE email = 'test@gmail.com';
-- This automatically deletes all reports for this user
```

### Check for Orphaned Reports
```sql
SELECT * FROM medical_reports 
WHERE user_id NOT IN (SELECT id FROM users);
-- Should always return 0 rows if cascade is working
```

---

## Backup & Restore

### Create Backup
```bash
pg_dump -U sail urosmart_db > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Restore Backup
```bash
psql -U sail urosmart_db < backup_20250205_090000.sql
```

### Export Users to CSV
```bash
psql -U sail -d urosmart_db -c "COPY users TO STDOUT WITH CSV HEADER" > users.csv
```

---

## Troubleshooting

### PostgreSQL Not Running?
```bash
brew services start postgresql@14
```

### Can't Connect?
```bash
# Check if PostgreSQL is listening
lsof -ti:5432

# Check database exists
psql -U sail -l | grep urosmart
```

### Reset Database (⚠️ DELETES ALL DATA)
```bash
dropdb -U sail urosmart_db
createdb -U sail urosmart_db
# Restart backend to recreate tables
```

---

## Files Created

All documentation and tools:
- 📄 `DATABASE_ACCESS_GUIDE.md` - Full connection guide
- 🐍 `inspect_database.py` - Quick database inspector
- 🧪 `test_account_deletion.py` - Backend deletion test
- 📋 This file - Quick reference

---

## Next Steps

1. ✅ **Connect** using pgAdmin or Postico
2. ✅ **Create** a test user in the iOS app
3. ✅ **Verify** user appears in database
4. ✅ **Delete** account via app
5. ✅ **Confirm** user and reports are removed
6. ✅ Email is now visible in profile
7. ✅ Port 5000 is correct (rebuild app if needed)
