#### Create Shell Script 

```bash
mkdir ~/customBin
nano ~/customBin/code-backup
```
Copy and Pest this code in editor
```text
#!/bin/bash
#!/bin/bash

# ===== CONFIG =====
SOURCE_DIR="/Users/micple/Desktop/work station/micple.com"

DATE=$(date +"%d-%B-%Y_%H-%M-%S")

DEST_HOST="root@76.13.185.44"
DEST_ROOT="/var/micple.backup"

DEST_DIR="$DEST_ROOT/micple.com"
BACKUP_DIR="$DEST_ROOT/backups/backup-of-$DATE"

# ===== 1. CREATE BACKUP OF OLD CODE =====
ssh $DEST_HOST "
mkdir -p $BACKUP_DIR
if [ -d $DEST_DIR ]; then
    cp -r $DEST_DIR $BACKUP_DIR/
fi
"

# ===== 2. DEPLOY NEW CODE =====
rsync -avz --delete \
  --exclude='node_modules/' \
  --exclude='storage.imp/' \
  --exclude='venv/' \
  "$SOURCE_DIR/" \
  "$DEST_HOST:$DEST_DIR/"

# ===== 3. CLEAN OLD BACKUPS (KEEP LAST 30) =====
ssh $DEST_HOST "
cd $DEST_ROOT/backups && ls -1t | tail -n +31 | xargs -r rm -rf
"
```
Make script executeable
```bash
chmod +x ~/customBin/code-backup
```

#### Make script available globally
```bash
nano ~/.zshrc
```
Add this line
```nano
export PATH="/Users/micple/customBin:$PATH"
```
Activate script
```bash
source ~/.zshrc
```
#### Set Schedule
```bash
crontab -e
```
Copy and Pest in editor
```text
0 16 * * * sh backup-code  >> /tmp/backup.log 2>&1
```
To Save Press `Esc` --> `:` Type `wq` --> `Enter`
