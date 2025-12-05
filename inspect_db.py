import sqlite3
import os

# Path to the database
db_path = 'backend/instance/urosmart.db'

if not os.path.exists(db_path):
    print(f"Database not found at {db_path}")
    exit(1)

print(f"📂 Database found at: {os.path.abspath(db_path)}\n")

conn = sqlite3.connect(db_path)
cursor = conn.cursor()

# Get all tables
cursor.execute("SELECT name FROM sqlite_master WHERE type='table';")
tables = cursor.fetchall()

print("📊 Tables found:")
for table in tables:
    table_name = table[0]
    print(f"- {table_name}")
    
    # Get columns
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = cursor.fetchall()
    print("  Columns:")
    for col in columns:
        print(f"    - {col[1]} ({col[2]})")
    
    # Get row count
    cursor.execute(f"SELECT COUNT(*) FROM {table_name}")
    count = cursor.fetchone()[0]
    print(f"  Rows: {count}")
    
    # Show sample data (first 2 rows)
    if count > 0:
        print("  Sample Data:")
        cursor.execute(f"SELECT * FROM {table_name} LIMIT 2")
        rows = cursor.fetchall()
        for row in rows:
            print(f"    {row}")
    print("-" * 30)

conn.close()
