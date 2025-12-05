#!/usr/bin/env python3
"""
Database Export Utility
Exports UroSmart database to JSON format for backup and portability
"""

import sqlite3
import json
import os
import sys
from datetime import datetime
import argparse

DB_PATH = 'backend/instance/urosmart.db'
EXPORT_DIR = 'backups'

def export_table(cursor, table_name):
    """Export a single table to dictionary format"""
    # Get column names
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = [col[1] for col in cursor.fetchall()]
    
    # Get all rows
    cursor.execute(f"SELECT * FROM {table_name}")
    rows = cursor.fetchall()
    
    # Convert to list of dictionaries
    table_data = []
    for row in rows:
        row_dict = {}
        for idx, col in enumerate(columns):
            value = row[idx]
            # Convert datetime to string for JSON serialization
            if isinstance(value, (bytes, bytearray)):
                value = value.decode('utf-8')
            row_dict[col] = value
        table_data.append(row_dict)
    
    return table_data

def export_database(output_format='json', output_file=None):
    """Export entire database"""
    
    if not os.path.exists(DB_PATH):
        print(f"❌ Database not found: {DB_PATH}")
        return False
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    # Get all tables
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
    tables = [table[0] for table in cursor.fetchall()]
    
    print(f"📊 Exporting {len(tables)} tables...")
    
    # Export all tables
    export_data = {
        'export_date': datetime.now().isoformat(),
        'database': 'urosmart',
        'tables': {}
    }
    
    for table in tables:
        print(f"  - Exporting {table}...")
        export_data['tables'][table] = export_table(cursor, table)
        print(f"    ✅ {len(export_data['tables'][table])} rows exported")
    
    conn.close()
    
    # Generate output filename
    if not output_file:
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        output_file = f"{EXPORT_DIR}/urosmart_export_{timestamp}.json"
    
    # Create export directory
    os.makedirs(os.path.dirname(output_file), exist_ok=True)
    
    # Write to file
    with open(output_file, 'w') as f:
        json.dump(export_data, f, indent=2, default=str)
    
    file_size = os.path.getsize(output_file)
    print(f"\n✅ Export complete!")
    print(f"📁 File: {output_file}")
    print(f"📏 Size: {file_size:,} bytes")
    
    return True

def import_database(import_file):
    """Import database from JSON file"""
    
    if not os.path.exists(import_file):
        print(f"❌ Import file not found: {import_file}")
        return False
    
    print(f"📥 Importing from {import_file}...")
    
    with open(import_file, 'r') as f:
        import_data = json.load(f)
    
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    
    tables = import_data.get('tables', {})
    
    for table_name, rows in tables.items():
        if not rows:
            continue
            
        print(f"  - Importing {table_name} ({len(rows)} rows)...")
        
        # Get column names from first row
        columns = list(rows[0].keys())
        placeholders = ','.join(['?' for _ in columns])
        column_names = ','.join(columns)
        
        # Insert rows
        for row in rows:
            values = [row[col] for col in columns]
            try:
                cursor.execute(
                    f"INSERT OR REPLACE INTO {table_name} ({column_names}) VALUES ({placeholders})",
                    values
                )
            except sqlite3.Error as e:
                print(f"    ⚠️  Error inserting row: {e}")
    
    conn.commit()
    conn.close()
    
    print(f"\n✅ Import complete!")
    return True

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Export/Import UroSmart database')
    parser.add_argument('action', choices=['export', 'import'], help='Action to perform')
    parser.add_argument('--file', help='File path for export/import')
    parser.add_argument('--format', choices=['json'], default='json', help='Export format')
    
    args = parser.parse_args()
    
    print("🗄️  UroSmart Database Export/Import Utility")
    print("=" * 45)
    print()
    
    if args.action == 'export':
        success = export_database(output_format=args.format, output_file=args.file)
    elif args.action == 'import':
        if not args.file:
            print("❌ --file argument required for import")
            sys.exit(1)
        success = import_database(args.file)
    
    sys.exit(0 if success else 1)
