#!/bin/bash

DASTINATION="$1"

rsync -av --delete \
  --exclude='node_modules/' \
  --exclude='storage.imp/' \
  --exclude='venv/' \
  "/Users/micple/Desktop/work station/micple.com/" \
  "$DASTINATION"
