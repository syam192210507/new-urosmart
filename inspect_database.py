#!/usr/bin/env python3
"""
Quick database inspector for UroSmart
Shows current state of users and reports
"""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend'))

from app import app, db, User, MedicalReport

def inspect_database():
    with app.app_context():
        print("=" * 70)
        print("📊 UroSmart Database Status")
        print("=" * 70)
        
        # Users
        users = User.query.all()
        print(f"\n👥 Users: {len(users)} total")
        print("-" * 70)
        if users:
            for user in users:
                report_count = len(user.reports)
                print(f"  ID: {user.id:3d} | {user.email:30s} | {user.phone_number} | Reports: {report_count}")
        else:
            print("  No users found")
        
        # Reports
        reports = MedicalReport.query.all()
        print(f"\n📄 Medical Reports: {len(reports)} total")
        print("-" * 70)
        if reports:
            for report in reports:
                print(f"  ID: {report.id:3d} | User: {report.user_id:3d} | Case: {report.case_number:15s} | Date: {report.report_date}")
        else:
            print("  No reports found")
        
        # Orphaned reports check
        orphaned = MedicalReport.query.filter(
            MedicalReport.user_id.notin_([u.id for u in users])
        ).all()
        
        print(f"\n🔍 Data Integrity Check")
        print("-" * 70)
        if orphaned:
            print(f"  ⚠️  WARNING: {len(orphaned)} orphaned reports found (no matching user)")
            for r in orphaned:
                print(f"     - Report ID {r.id} references non-existent user_id {r.user_id}")
        else:
            print(f"  ✅ All reports have valid user references")
        
        # User-Report mapping
        print(f"\n📊 User-Report Distribution")
        print("-" * 70)
        if users:
            for user in users:
                print(f"  {user.email:30s}: {len(user.reports)} report(s)")
        else:
            print("  No users to display")
        
        print("\n" + "=" * 70)

if __name__ == "__main__":
    try:
        inspect_database()
    except Exception as e:
        print(f"❌ Error inspecting database: {e}")
        import traceback
        traceback.print_exc()
