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
