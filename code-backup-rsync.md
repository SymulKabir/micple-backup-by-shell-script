Copy code and ignore /node_modules, storage.imp, venv folders

```bash
rsync -av \
  --exclude='node_modules/' \
  --exclude='storage.imp/' \
  --exclude='venv/' \
  "/Users/micple/Desktop/work station/micple.com/" \
  ./
```
