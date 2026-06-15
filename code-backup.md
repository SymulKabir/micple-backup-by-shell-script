#### Create Shell Script 

```bash
mkdir ~/customBin
nano ~/customBin/code-backup
```
Copy and Pest this code in editor
```text
#!/bin/bash

DASTINATION="$1"

rsync -av --delete \
  --exclude='node_modules/' \
  --exclude='storage.imp/' \
  --exclude='venv/' \
  "/Users/micple/Desktop/work station/micple.com/" \
  "$DASTINATION"
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
0 16 * * * sh backup-code "root@76.13.185.44:/var/micple.backup/micple.com"  >> /tmp/backup.log 2>&1
```
To Save Press `Esc` --> `:` Type `wq` --> `Enter`
