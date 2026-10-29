#!/bin/bash
set -e

REPO="nullsave-ai/DesertOutpost"
FINAL_APK="/storage/emulated/0/Download/DesertOutpost.apk"

echo "=== Desert Outpost - Tracking Build & Downloading APK ==="

# Get latest run
RUN_ID=$(gh run list --repo "$REPO" --limit 1 --json databaseId -q '.[0].databaseId')
echo "Tracking Run ID: $RUN_ID"

gh run watch "$RUN_ID" --repo "$REPO"

echo "Build finished! Fetching APK from Release..."
gh release download --repo "$REPO" --pattern "*.apk" --dir /storage/emulated/0/Download/ --clobber || \
gh run download "$RUN_ID" --repo "$REPO" --name DesertOutpost-apk --dir /storage/emulated/0/Download/

echo "=== SUCCESS: APK downloaded and ready! ==="
ls -lh /storage/emulated/0/Download/DesertOutpost*.apk
