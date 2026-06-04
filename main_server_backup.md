
# 🔄 Micple Main Server Backup Automation Setup Guide

## 📁 1. Create Backup Script

Create a new shell script at `/bin/micple_backup.sh`:

### ➤ Script: `/bin/micple_backup.sh`
```bash
#!/bin/bash

set -euo pipefail

# =========================
# CONFIGURATION
# =========================

BACKUP_ROOT_DIR="/micple.com/backups/mongodb"

DUMP_BACKUP_DIR="${BACKUP_ROOT_DIR}/dump_files"
RAW_BACKUP_DIR="${BACKUP_ROOT_DIR}/binary_files"

CURRENT_DUMP_DIR="${DUMP_BACKUP_DIR}/dump"
CURRENT_BINARY_DIR="${RAW_BACKUP_DIR}/mongodb"

MONGODB_BINARY_SOURCE_DIR="/var/lib/k8s-mongodb"

TIMESTAMP=$(date +"%d_%B_%Y_%I-%M%p")

DB_DUMP_CURRENT_BACKUP_DIR="${DUMP_BACKUP_DIR}/db-(${TIMESTAMP})"
DB_BINARY_CURRENT_BACKUP_DIR="${RAW_BACKUP_DIR}/db-(${TIMESTAMP})"

# =========================
# CREATE REQUIRED DIRECTORIES
# =========================

mkdir -p "$CURRENT_DUMP_DIR"
mkdir -p "$CURRENT_BINARY_DIR"

# =========================
# ARCHIVE PREVIOUS DUMP BACKUP
# =========================

if [ "$(ls -A "$CURRENT_DUMP_DIR" 2>/dev/null)" ]; then
    echo "Archiving previous dump backup..."

    mkdir -p "$DB_DUMP_CURRENT_BACKUP_DIR"

    rsync -a \
        "$CURRENT_DUMP_DIR/" \
        "$DB_DUMP_CURRENT_BACKUP_DIR/"

    rm -rf "${CURRENT_DUMP_DIR:?}/"*
fi

# =========================
# ARCHIVE PREVIOUS BINARY BACKUP
# =========================

if [ "$(ls -A "$CURRENT_BINARY_DIR" 2>/dev/null)" ]; then
    echo "Archiving previous binary backup..."

    mkdir -p "$DB_BINARY_CURRENT_BACKUP_DIR"

    rsync -a \
        "$CURRENT_BINARY_DIR/" \
        "$DB_BINARY_CURRENT_BACKUP_DIR/"

    rm -rf "${CURRENT_BINARY_DIR:?}/"*
fi

# =========================
# FIND MONGODB POD
# =========================

MONGO_POD=$(
    kubectl get pods \
    -l app=mongodb \
    --no-headers \
    -o custom-columns=":metadata.name" \
    | head -n1
)

if [ -z "$MONGO_POD" ]; then
    echo "ERROR: MongoDB pod not found."
    exit 1
fi

echo "Using MongoDB pod: $MONGO_POD"

# =========================
# CREATE MONGODUMP INSIDE POD
# =========================

kubectl exec "$MONGO_POD" -- rm -rf /tmp/dump

echo "Creating MongoDB dump..."

kubectl exec "$MONGO_POD" -- mongodump --out=/tmp/dump

# =========================
# COPY DUMP TO HOST
# =========================

echo "Copying dump backup to host..."

kubectl cp \
    "$MONGO_POD:/tmp/dump/." \
    "$CURRENT_DUMP_DIR"

# Cleanup pod temp files
kubectl exec "$MONGO_POD" -- rm -rf /tmp/dump

# =========================
# COPY RAW DATABASE FILES
# =========================

if [ -d "$MONGODB_BINARY_SOURCE_DIR" ] && \
   [ "$(ls -A "$MONGODB_BINARY_SOURCE_DIR" 2>/dev/null)" ]; then

    echo "Copying raw MongoDB files..."

    rsync -a \
        "$MONGODB_BINARY_SOURCE_DIR/" \
        "$CURRENT_BINARY_DIR/"
fi

# =========================
# ROTATE OLD DUMP BACKUPS
# KEEP LAST 24
# =========================

if [ -d "$DUMP_BACKUP_DIR" ]; then
    ls -1dt "$DUMP_BACKUP_DIR"/db-* 2>/dev/null \
    | tail -n +25 \
    | while IFS= read -r dir; do
        echo "Deleting old dump backup: $dir"
        rm -rf "$dir"
    done
fi

# =========================
# ROTATE OLD BINARY BACKUPS
# KEEP LAST 24
# =========================

if [ -d "$RAW_BACKUP_DIR" ]; then
    ls -1dt "$RAW_BACKUP_DIR"/db-* 2>/dev/null \
    | tail -n +25 \
    | while IFS= read -r dir; do
        echo "Deleting old binary backup: $dir"
        rm -rf "$dir"
    done
fi

echo "MongoDB backup completed successfully."
echo "Dump backup location:   $CURRENT_DUMP_DIR"
echo "Binary backup location: $CURRENT_BINARY_DIR"

```



### 🔐 Make Script Executable
```bash
chmod +x /bin/micple_backup.sh
```


---

## ⏰ 3. Schedule with Cron

To run the backup script every hour automatically:

### ➤ Edit Cron Jobs

```bash
crontab -e
``` 
### ➤ Add This Line at the Bottom
```bash
0 * * * * /bin/micple_backup.sh >> /var/micple.com/backup/hourly-backup.log 2>&1
``` 

This command runs the backup script every hour on the hour and logs output to hourly-backup.log.


## 📦 Output Directory Structure

```markdown
/micple.com/backups/mongodb/
│
├── dump_files/                          # MongoDB dump system (main root)
│   │
│   ├── dump/                            # Latest live mongodump output
│   │   ├── admin/
│   │   ├── mydb/
│   │   └── ...
│   │
│   ├── db-(23_April_2026_10-00AM)/      # Archived dump snapshots
│   ├── db-(23_April_2026_11-00AM)/
│   ├── db-(04_June_2026_09-00AM)/
│   └── ...
│
│
├── binary_files/                        # MongoDB raw binary data system
│   │
│   ├── mongodb/                         # Latest live binary copy
│   │   ├── collection-0.wt
│   │   ├── index-1.wt
│   │   └── ...
│   │
│   ├── db-(23_April_2026_10-00AM)/      # Archived binary snapshots
│   ├── db-(23_April_2026_11-00AM)/
│   ├── db-(04_June_2026_09-00AM)/
│   └── ...
│
└── README.md (optional if you add later)
``` 




