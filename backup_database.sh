#!/bin/bash
# Database Backup Script
# Creates timestamped backups of the UroSmart database

BACKUP_DIR="backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
DB_PATH="backend/instance/urosmart.db"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

echo "🗄️  UroSmart Database Backup"
echo "============================"
echo ""

# Check if database exists
if [ ! -f "$DB_PATH" ]; then
    echo "❌ Database not found at $DB_PATH"
    exit 1
fi

# Create backup filename
BACKUP_FILE="$BACKUP_DIR/urosmart_backup_$TIMESTAMP.db"

# Copy database
cp "$DB_PATH" "$BACKUP_FILE"

if [ $? -eq 0 ]; then
    # Get file size
    SIZE=$(ls -lh "$BACKUP_FILE" | awk '{print $5}')
    echo "✅ Backup created successfully!"
    echo "📁 File: $BACKUP_FILE"
    echo "📏 Size: $SIZE"
    echo ""
    
    # Compress backup (optional)
    read -p "Compress backup? (y/n): " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        gzip "$BACKUP_FILE"
        echo "✅ Backup compressed: ${BACKUP_FILE}.gz"
    fi
    
    # List recent backups
    echo ""
    echo "📋 Recent Backups:"
    ls -lht "$BACKUP_DIR" | head -6
    
else
    echo "❌ Backup failed!"
    exit 1
fi

echo ""
echo "✅ Backup complete!"
