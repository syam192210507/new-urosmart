"""
Automatic Database Initialization and Migration
Handles PostgreSQL setup automatically on app startup
"""

import os
import json
from datetime import datetime

def init_database(app, db, User, MedicalReport):
    """
    Automatically initialize database:
    1. Create tables if they don't exist
    2. Migrate from SQLite if PostgreSQL is empty and SQLite has data
    """
    
    with app.app_context():
        # Check if we're using PostgreSQL
        db_url = app.config['SQLALCHEMY_DATABASE_URI']
        using_postgresql = db_url.startswith('postgresql://')
        
        print(f"🔧 Database initialization...")
        print(f"   Database: {db_url.split('://')[0]}")
        
        # Create all tables
        db.create_all()
        print("   ✅ Tables verified/created")
        
        # Check if PostgreSQL is empty and SQLite has data
        if using_postgresql:
            user_count = User.query.count()
            
            if user_count == 0:
                print("   📊 PostgreSQL database is empty")
                
                # Check if SQLite backup exists
                sqlite_path = os.path.join(os.path.dirname(__file__), 'instance', 'urosmart.db')
                if os.path.exists(sqlite_path):
                    print(f"   📁 Found SQLite database: {sqlite_path}")
                    print("   🔄 Auto-migrating data from SQLite...")
                    
                    try:
                        migrate_from_sqlite(app, db, User, MedicalReport, sqlite_path)
                        print("   ✅ Migration complete!")
                    except Exception as e:
                        print(f"   ⚠️  Migration failed: {e}")
                        print("   💡 You can manually migrate using: python import_data.py")
                else:
                    print("   ℹ️  No existing SQLite database found - starting fresh")
            else:
                print(f"   ✅ Database ready ({user_count} users)")

def migrate_from_sqlite(app, db, User, MedicalReport, sqlite_path):
    """Migrate data from SQLite to PostgreSQL"""
    import sqlite3
    
    # Connect to SQLite
    conn = sqlite3.connect(sqlite_path)
    conn.row_factory = sqlite3.Row
    cursor = conn.cursor()
    
    # Migrate users
    cursor.execute("SELECT * FROM users")
    users = cursor.fetchall()
    
    for user_row in users:
        user = User.query.filter_by(id=user_row['id']).first()
        if not user:
            user = User(
                id=user_row['id'],
                phone_number=user_row['phone_number'],
                email=user_row['email'],
                password_hash=user_row['password_hash'],
                reset_otp=user_row['reset_otp'],
                reset_otp_expires=datetime.fromisoformat(user_row['reset_otp_expires']) if user_row['reset_otp_expires'] else None,
                created_at=datetime.fromisoformat(user_row['created_at']) if user_row['created_at'] else datetime.utcnow(),
                updated_at=datetime.fromisoformat(user_row['updated_at']) if user_row['updated_at'] else datetime.utcnow()
            )
            db.session.add(user)
    
    db.session.commit()
    print(f"      ✓ Migrated {len(users)} users")
    
    # Migrate medical reports
    cursor.execute("SELECT * FROM medical_reports")
    reports = cursor.fetchall()
    
    for report_row in reports:
        report = MedicalReport.query.filter_by(id=report_row['id']).first()
        if not report:
            report = MedicalReport(
                id=report_row['id'],
                user_id=report_row['user_id'],
                case_number=report_row['case_number'],
                report_date=datetime.fromisoformat(report_row['report_date']) if report_row['report_date'] else datetime.utcnow(),
                yeast_present=bool(report_row['yeast_present']),
                yeast_count=report_row['yeast_count'],
                yeast_confidence=report_row['yeast_confidence'],
                triple_phosphate_present=bool(report_row['triple_phosphate_present']),
                triple_phosphate_count=report_row['triple_phosphate_count'],
                triple_phosphate_confidence=report_row['triple_phosphate_confidence'],
                calcium_oxalate_present=bool(report_row['calcium_oxalate_present']),
                calcium_oxalate_count=report_row['calcium_oxalate_count'],
                calcium_oxalate_confidence=report_row['calcium_oxalate_confidence'],
                squamous_cells_present=bool(report_row['squamous_cells_present']),
                squamous_cells_count=report_row['squamous_cells_count'],
                squamous_cells_confidence=report_row['squamous_cells_confidence'],
                uric_acid_present=bool(report_row['uric_acid_present']),
                uric_acid_count=report_row['uric_acid_count'],
                uric_acid_confidence=report_row['uric_acid_confidence'],
                image_paths=report_row['image_paths'],
                pdf_path=report_row['pdf_path'],
                created_at=datetime.fromisoformat(report_row['created_at']) if report_row['created_at'] else datetime.utcnow()
            )
            db.session.add(report)
    
    db.session.commit()
    print(f"      ✓ Migrated {len(reports)} reports")
    
    conn.close()
