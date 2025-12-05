#!/usr/bin/env python3
"""
Migrate database schema from SQLite to PostgreSQL
"""

import sys
import os

# Add backend directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

from app import app, db

print("🔄 Creating tables in PostgreSQL...")

with app.app_context():
    # Create all tables
    db.create_all()
    print("✅ Tables created successfully!")
    print("")
    print("Tables:")
    print("  - users")
    print("  - medical_reports")
    print("")
    print("Next: Import data from backup file")
