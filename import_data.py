#!/usr/bin/env python3
"""
Import data from SQLite backup to PostgreSQL
"""

import sys
import os
import json

# Add backend directory to Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

from app import app, db, User, MedicalReport
from datetime import datetime

print("📥 Importing data to PostgreSQL...")

# Load backup
with open('backups/pre_migration_backup.json', 'r') as f:
    backup_data = json.load(f)

with app.app_context():
    # Import users
    users_data = backup_data['tables'].get('users', [])
    print(f"  Importing {len(users_data)} users...")
    
    for user_data in users_data:
        # Check if user already exists
        existing = User.query.filter_by(id=user_data['id']).first()
        if existing:
            print(f"    User {user_data['email']} already exists, skipping")
            continue
            
        user = User(
            id=user_data['id'],
            phone_number=user_data['phone_number'],
            email=user_data['email'],
            password_hash=user_data['password_hash'],
            reset_otp=user_data.get('reset_otp'),
            reset_otp_expires=datetime.fromisoformat(user_data['reset_otp_expires']) if user_data.get('reset_otp_expires') else None,
            created_at=datetime.fromisoformat(user_data['created_at']) if user_data.get('created_at') else datetime.utcnow(),
            updated_at=datetime.fromisoformat(user_data['updated_at']) if user_data.get('updated_at') else datetime.utcnow()
        )
        db.session.add(user)
    
    db.session.commit()
    print(f"    ✅ {len(users_data)} users imported")
    
    # Import medical reports
    reports_data = backup_data['tables'].get('medical_reports', [])
    print(f"  Importing {len(reports_data)} medical reports...")
    
    for report_data in reports_data:
        # Check if report already exists
        existing = MedicalReport.query.filter_by(id=report_data['id']).first()
        if existing:
            print(f"    Report {report_data['case_number']} already exists, skipping")
            continue
            
        report = MedicalReport(
            id=report_data['id'],
            user_id=report_data['user_id'],
            case_number=report_data['case_number'],
            report_date=datetime.fromisoformat(report_data['report_date']) if report_data.get('report_date') else datetime.utcnow(),
            yeast_present=bool(report_data.get('yeast_present', 0)),
            yeast_count=report_data.get('yeast_count', 0),
            yeast_confidence=report_data.get('yeast_confidence', 0.0),
            triple_phosphate_present=bool(report_data.get('triple_phosphate_present', 0)),
            triple_phosphate_count=report_data.get('triple_phosphate_count', 0),
            triple_phosphate_confidence=report_data.get('triple_phosphate_confidence', 0.0),
            calcium_oxalate_present=bool(report_data.get('calcium_oxalate_present', 0)),
            calcium_oxalate_count=report_data.get('calcium_oxalate_count', 0),
            calcium_oxalate_confidence=report_data.get('calcium_oxalate_confidence', 0.0),
            squamous_cells_present=bool(report_data.get('squamous_cells_present', 0)),
            squamous_cells_count=report_data.get('squamous_cells_count', 0),
            squamous_cells_confidence=report_data.get('squamous_cells_confidence', 0.0),
            uric_acid_present=bool(report_data.get('uric_acid_present', 0)),
            uric_acid_count=report_data.get('uric_acid_count', 0),
            uric_acid_confidence=report_data.get('uric_acid_confidence', 0.0),
            image_paths=report_data.get('image_paths', '[]'),
            pdf_path=report_data.get('pdf_path'),
            created_at=datetime.fromisoformat(report_data['created_at']) if report_data.get('created_at') else datetime.utcnow()
        )
        db.session.add(report)
    
    db.session.commit()
    print(f"    ✅ {len(reports_data)} reports imported")

print("")
print("✅ Data import complete!")
print("")
print("Summary:")
print(f"  Users: {len(users_data)}")
print(f"  Reports: {len(reports_data)}")
