#!/bin/bash
# Database Restore Script
# Restores UroSmart database from a backup file

echo "🔄 UroSmart Database Restore"
echo "============================"
echo ""

DB_PATH="backend/instance/urosmart.db"
BACKUP_DIR="backups"

# List available backups
echo "📋 Available Backups:"
ls -lt "$BACKUP_DIR"/*.db "$BACKUP_DIR"/*.db.gz 2>/dev/null | head -10

if [ $? -ne 0 ]; then
    echo "❌ No backups found in $BACKUP_DIR/"
    exit 1
fi

echo ""
read -p "Enter backup filename (or path): " BACKUP_FILE

# Check if file exists
if [ ! -f "$BACKUP_FILE" ]; then
    # Try in backup directory
    BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE"
    if [ ! -f "$BACKUP_FILE" ]; then
        echo "❌ Backup file not found"
        exit 1
    fi
fi

echo ""
echo "⚠️  WARNING: This will replace the current database!"
echo "Current database: $DB_PATH"
echo "Backup file: $BACKUP_FILE"
echo ""
read -p "Continue? (yes/no): " CONFIRM

if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

# Create safety backup of current database
SAFETY_BACKUP="backend/instance/urosmart_before_restore_$(date +%Y%m%d_%H%M%S).db"
if [ -f "$DB_PATH" ]; then
    echo "Creating safety backup: $SAFETY_BACKUP"
    cp "$DB_PATH" "$SAFETY_BACKUP"
fi

# Check if backup is compressed
if [[ "$BACKUP_FILE" == *.gz ]]; then
    echo "Decompressing backup..."
    gunzip -c "$BACKUP_FILE" > "$DB_PATH"
else
    echo "Restoring database..."
    cp "$BACKUP_FILE" "$DB_PATH"
fi

if [ $? -eq 0 ]; then
    echo "✅ Database restored successfully!"
    echo "📁 From: $BACKUP_FILE"
    echo "📁 To: $DB_PATH"
    
    # Verify restoration
    echo ""
    echo "🔍 Verifying restored database..."
    python inspect_db.py | head -20
    
else
    echo "❌ Restore failed!"
    if [ -f "$SAFETY_BACKUP" ]; then
        echo "Restoring from safety backup..."
        mv "$SAFETY_BACKUP" "$DB_PATH"
    fi
    exit 1
fi

echo ""
echo "✅ Restore complete!"
