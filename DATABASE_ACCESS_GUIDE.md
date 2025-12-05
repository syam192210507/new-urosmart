# Database Connection Guide - pgAdmin & Postico

## Your Database Details

**Database Type:** PostgreSQL  
**Database Name:** `urosmart_db`  
**Host:** `localhost`  
**Port:** `5432` (default PostgreSQL port)  
**Username:** `sail`  
**Password:** (no password - local trusted connection)

---

## Option 1: Connect with pgAdmin 4

### Step 1: Open pgAdmin
Launch pgAdmin 4 from your Applications

### Step 2: Create a New Server Connection
1. Right-click on **Servers** in the left panel
2. Select **Create** → **Server...**

### Step 3: Configure Connection

**General Tab:**
- **Name:** `UroSmart Local`

**Connection Tab:**
- **Host name/address:** `localhost`
- **Port:** `5432`
- **Maintenance database:** `postgres`
- **Username:** `sail`
- **Password:** (leave empty)
- **Save password:** ✅ Check this

### Step 4: Click "Save"

### Step 5: Navigate to Your Database
1. In the left panel, expand: **Servers** → **UroSmart Local** → **Databases**
2. Right-click on **Databases** and select **Refresh**
3. You should see **urosmart_db**
4. Expand it: **urosmart_db** → **Schemas** → **public** → **Tables**

---

## Option 2: Connect with Postico

### Step 1: Open Postico
Launch Postico from your Applications

### Step 2: Create New Connection
Click **New Favorite** or the **+** button

### Step 3: Enter Connection Details
- **Nickname:** `UroSmart Local`
- **Host:** `localhost`
- **Port:** `5432`
- **User:** `sail`
- **Password:** (leave empty)
- **Database:** `urosmart_db`

### Step 4: Click "Connect"

---

## Database Tables to Check

Once connected, you should see these two main tables:

### 1. **users** Table
Stores user account information:
- `id` - User ID (primary key)
- `phone_number` - 10-digit phone number
- `email` - User's email address
- `password_hash` - Encrypted password
- `reset_otp` - Password reset OTP (if active)
- `reset_otp_expires` - OTP expiration time
- `created_at` - Account creation timestamp
- `updated_at` - Last update timestamp

### 2. **medical_reports** Table
Stores medical reports:
- `id` - Report ID (primary key)
- `user_id` - Foreign key to users table
- `case_number` - Unique case identifier
- `report_date` - Report creation date
- `yeast_present`, `yeast_count`, `yeast_confidence`
- `triple_phosphate_present`, `triple_phosphate_count`, `triple_phosphate_confidence`
- `calcium_oxalate_present`, `calcium_oxalate_count`, `calcium_oxalate_confidence`
- `squamous_cells_present`, `squamous_cells_count`, `squamous_cells_confidence`
- `uric_acid_present`, `uric_acid_count`, `uric_acid_confidence`
- `image_paths` - JSON array of image file paths
- `pdf_path` - PDF report file path
- `created_at` - Report creation timestamp

---

## Verify Account Deletion Works

### Test Steps:

1. **Before Deletion - Check Users:**
   ```sql
   SELECT id, email, phone_number, created_at FROM users;
   ```
   Note the user ID you want to delete.

2. **Before Deletion - Check Reports:**
   ```sql
   SELECT id, user_id, case_number, report_date 
   FROM medical_reports 
   WHERE user_id = 1;  -- Replace 1 with actual user ID
   ```
   Note how many reports this user has.

3. **Delete Account via iOS App:**
   - Open your iOS app
   - Log in with the user
   - Go to Profile
   - Click "Delete Account"
   - Confirm deletion

4. **After Deletion - Verify User is Gone:**
   ```sql
   SELECT id, email, phone_number, created_at FROM users;
   ```
   The user should be **removed** from the list.

5. **After Deletion - Verify Reports are Gone:**
   ```sql
   SELECT id, user_id, case_number, report_date 
   FROM medical_reports 
   WHERE user_id = 1;  -- Replace with the deleted user ID
   ```
   Should return **0 rows** (cascade delete worked).

---

## Useful SQL Queries

### View All Users:
```sql
SELECT 
    id, 
    email, 
    phone_number, 
    created_at,
    (SELECT COUNT(*) FROM medical_reports WHERE user_id = users.id) as report_count
FROM users
ORDER BY created_at DESC;
```

### View All Reports with User Info:
```sql
SELECT 
    mr.id as report_id,
    mr.case_number,
    mr.report_date,
    u.email as user_email,
    mr.yeast_present,
    mr.triple_phosphate_present,
    mr.calcium_oxalate_present
FROM medical_reports mr
JOIN users u ON mr.user_id = u.id
ORDER BY mr.report_date DESC;
```

### Check Cascade Delete Relationship:
```sql
-- This shows the foreign key constraint that enables cascade delete
SELECT
    tc.table_name, 
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name,
    rc.delete_rule
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
JOIN information_schema.referential_constraints AS rc
  ON rc.constraint_name = tc.constraint_name
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_name='medical_reports';
```

Expected result: `delete_rule` should be `CASCADE`

---

## Quick Database Stats

Run this to see your database overview:

```sql
-- Database Overview
SELECT 
    'Users' as table_name, 
    COUNT(*) as row_count 
FROM users
UNION ALL
SELECT 
    'Medical Reports' as table_name, 
    COUNT(*) as row_count 
FROM medical_reports;
```

---

## Troubleshooting

### Can't Connect to PostgreSQL?

**Check if PostgreSQL is running:**
```bash
brew services list | grep postgresql
```

**Start PostgreSQL if not running:**
```bash
brew services start postgresql@14
```

**Verify database exists:**
```bash
psql -U sail -l
```

**Create database if missing:**
```bash
createdb -U sail urosmart_db
```

---

## Notes

- **Password:** Your local PostgreSQL is configured for "trust" authentication (no password needed for local connections)
- **Cascade Delete:** The relationship between `users` and `medical_reports` has `CASCADE` delete enabled, so deleting a user automatically deletes their reports
- **Backup:** Before testing deletions, you can backup:
  ```bash
  pg_dump -U sail urosmart_db > backup.sql
  ```
- **Restore:** If needed:
  ```bash
  psql -U sail urosmart_db < backup.sql
  ```

---

## What to Verify After Our Fixes

1. ✅ **Users table** - New users are created with email visible
2. ✅ **Medical reports** - Reports are linked to correct user_id
3. ✅ **Cascade delete works** - Deleting user removes all their reports
4. ✅ **No orphaned data** - No reports exist without a valid user_id
