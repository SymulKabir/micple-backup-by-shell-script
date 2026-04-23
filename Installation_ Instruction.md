# 🔄 Micple Backup Automation Setup Guide

This guide helps you automate file and MongoDB backups from a remote server using `rsync` and a cron job.

---
## 🚀 1. Initial Setup (SSH Access)

### 🔐 Step 1: Login to Backup Server
Run this from your local machine or admin machine:
```bash
ssh root@<BACKUP_SERVER_IP>
```
### 🔑 Step 2: Enable Passwordless SSH
From the backup server, run:
```bash
ssh-copy-id root@micple.com
```
Then:
- Press `Enter`
- Enter remote server password when prompted
✔ This allows automated backups without manual password input.


## 📁 2. Create Backup Script

Create a new shell script at `/bin/micple_backup.sh`:

### ➤ Script: `/bin/micple_backup.sh`

```bash
 #!/bin/bash

REMOTE_USER="root@micple.com"
DEST_ROOT_FOLDER="/var/micple.com/backup"

MEDIA_SOURCE_DIR="${REMOTE_USER}:/var/micple.com/default.imp/storage.imp"
MEDIA_DEST_DIR="${DEST_ROOT_FOLDER}/media"

DB_BINARY_SOURCE_DIR="${REMOTE_USER}:/var/lib/k8s-mongodb"
DB_BINARY_DEST_DIR="${DEST_ROOT_FOLDER}/db-binary"
DB_BINARY_PREVIOUS_BACKUP_DIR="${DEST_ROOT_FOLDER}/previous-backup-db-binary"

DB_DUMP_SOURCE_DIR="${REMOTE_USER}:/micple.com/backups/mongodb/dump/dump"
DB_DUMP_DEST_DIR="${DEST_ROOT_FOLDER}/db-dump"
DB_DUMP_PREVIOUS_BACKUP_DIR="${DEST_ROOT_FOLDER}/previous-backup-db-dump"


mkdir -p "$MEDIA_DEST_DIR"
mkdir -p "$DB_BINARY_DEST_DIR"
mkdir -p "$DB_BINARY_PREVIOUS_BACKUP_DIR"
mkdir -p "$DB_DUMP_DEST_DIR"
mkdir -p "$DB_DUMP_PREVIOUS_BACKUP_DIR"

TIMESTAMP=$(date +"%d_%B_%Y,_%I:%M%p")
DB_BINARY_CURRENT_BACKUP_DIR="${DB_BINARY_PREVIOUS_BACKUP_DIR}/db-(${TIMESTAMP})"
DB_DUMP_CURRENT_BACKUP_DIR="${DB_DUMP_PREVIOUS_BACKUP_DIR}/db-(${TIMESTAMP})"

if [ "$(ls -A "$DB_BINARY_DEST_DIR" 2>/dev/null)" ]; then
  mkdir -p "$DB_BINARY_CURRENT_BACKUP_DIR"
  rsync -a "$DB_BINARY_DEST_DIR/" "$DB_BINARY_CURRENT_BACKUP_DIR/"
fi

echo "DB_DUMP_DEST_DIR->> $DB_DUMP_DEST_DIR"
echo "DB_DUMP_CURRENT_BACKUP_DIR->> $DB_DUMP_CURRENT_BACKUP_DIR"

if [ "$(ls -A "$DB_DUMP_DEST_DIR" 2>/dev/null)" ]; then
  echo "Hello from dump copy if ->"
  mkdir -p "$DB_DUMP_CURRENT_BACKUP_DIR"
  rsync -a "$DB_DUMP_DEST_DIR/" "$DB_DUMP_CURRENT_BACKUP_DIR/"
else
  echo "Hello from dump copy else"
fi


rsync -az --delete "$DB_BINARY_SOURCE_DIR/" "$DB_BINARY_DEST_DIR/"
rsync -az --delete "$DB_DUMP_SOURCE_DIR/" "$DB_DUMP_DEST_DIR/"
rsync -az --delete "$MEDIA_SOURCE_DIR/" "$MEDIA_DEST_DIR/"


if [ -d "$DB_BINARY_PREVIOUS_BACKUP_DIR" ]; then
  # Delete older backups safely, keeping last 24
  ls -1dt "$DB_BINARY_PREVIOUS_BACKUP_DIR"/db-* 2>/dev/null | tail -n +25 | while IFS= read -r dir; do
      rm -rf "$dir"
  done
fi
if [ -d "$DB_DUMP_PREVIOUS_BACKUP_DIR" ]; then
  echo "Hello form if block"
  ls -1dt "$DB_DUMP_PREVIOUS_BACKUP_DIR"/db-* 2>/dev/null | tail -n +25 | while IFS= read -r dir; do
      rm -rf "$dir"
  done
else
  echo "Backup directory does not exist: $DB_DUMP_PREVIOUS_BACKUP_DIR"
fi


BACKUP_TIME=$(date +"%d %B %Y, %I:%M%p")
README_FILE="$DEST_ROOT_FOLDER/README.md"

if grep -q "Backup Time" "$README_FILE"; then
    sed -i "s|### Backup Time: .*|### Backup Time: $BACKUP_TIME|" "$README_FILE"
else
    sed -i "1i### Backup Time: $BACKUP_TIME" "$README_FILE"
fi


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

/var/micple.com/backup/
├── media/                          # Live synced media from remote server
│
├── db-binary/                      # Latest MongoDB binary data (live copy)
│
├── db-dump/                        # Latest MongoDB dump (live copy)
│
├── previous-backup-db-binary/     # History of DB binary snapshots
│   ├── db-(23_April_2026,_10:00AM)/
│   ├── db-(23_April_2026,_11:00AM)/
│   └── ...
│
├── previous-backup-db-dump/       # History of DB dump snapshots
│   ├── db-(23_April_2026,_10:00AM)/
│   ├── db-(23_April_2026,_11:00AM)/
│   └── ...
│
├── README.md                      # Backup timestamp tracker (updated via sed)
│
└── hourly-backup.log             # (optional) cron logs if configured
``` 
