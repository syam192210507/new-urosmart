# How Data is Stored in UroSmart

## 🎯 Answer: Python Files (Not SQL Files)

Your project uses **Python code** to store data, using a library called **SQLAlchemy**. SQLAlchemy automatically converts your Python code into SQL commands.

---

## 📝 Step 1: Define Database Structure (Python Classes)

**File**: `/Users/sail/Desktop/UroSmart/backend/app.py`

### Example: User Table Definition (Lines 106-134)
```python
class User(db.Model):
    __tablename__ = 'users'
    
    id = db.Column(db.Integer, primary_key=True)
    phone_number = db.Column(db.String(20), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(255), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
```

This Python class automatically creates this SQL table:
```sql
CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    email VARCHAR(120) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    created_at TIMESTAMP
);
```

**You write Python ↔ SQLAlchemy generates SQL automatically!**

---

## 💾 Step 2: Store Data (Python Code)

**File**: `/Users/sail/Desktop/UroSmart/backend/app.py`

### Example: Saving a New User (Lines 293-300)
```python
# Create new user (Python object)
user = User(
    phone_number=data['phone_number'],
    email=data['email']
)
user.set_password(data['password'])

# Save to database (this runs SQL behind the scenes)
db.session.add(user)
db.session.commit()
```

Behind the scenes, SQLAlchemy runs this SQL:
```sql
INSERT INTO users (phone_number, email, password_hash, created_at) 
VALUES ('1234567890', 'user@gmail.com', 'hashed_password', '2025-12-03 09:10:27');
```

---

## 🔍 Step 3: Read Data (Python Code)

### Example: Finding a User
```python
# Python code
user = User.query.filter_by(email=data['email']).first()
```

Behind the scenes, SQLAlchemy runs:
```sql
SELECT * FROM users WHERE email = 'user@gmail.com' LIMIT 1;
```

---

## 📊 Key Files That Store Data

| File | Purpose |
|------|---------|
| `backend/app.py` | **Main file** - Contains User and MedicalReport models (lines 106-231) |
| `backend/db_init.py` | Auto-creates tables when backend starts |
| `backend/.env` | Database connection string (which database to use) |

---

## 🔄 How It All Works Together

```
1. iOS App sends data → HTTP Request
         ↓
2. backend/app.py receives request (Python Flask API)
         ↓
3. Python code creates objects (User or MedicalReport)
         ↓
4. db.session.add() + db.session.commit()
         ↓
5. SQLAlchemy converts to SQL commands
         ↓
6. SQL executed on PostgreSQL database
         ↓
7. Data saved! ✅
```

---

## ✅ Summary

**Question**: Do you use SQL files or Python files to store data?

**Answer**: **Python files** exclusively!
- No `.sql` files needed
- All database operations in Python (using SQLAlchemy)
- SQLAlchemy automatically generates SQL
- Main file: `backend/app.py`

---

## 📍 Where to Find the Code

### User Data Storage:
- **Model**: `backend/app.py` lines 106-134
- **Create User**: `backend/app.py` lines 293-300 (signup endpoint)
- **Login User**: `backend/app.py` lines 316-343

### Medical Report Storage:
- **Model**: `backend/app.py` lines 161-231
- **Create Report**: `backend/app.py` lines 439-493
- **Get Reports**: `backend/app.py` lines 495-529
