#!/bin/bash
# deploy.sh — rebuild HTML and push to GitHub Pages
# Usage: ./deploy.sh [trip-id] ["optional commit message"]
#        ./deploy.sh scotland-2026
#        ./deploy.sh lake-garda-2026 "Add Lake Garda day 3"

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAGES_REPO="/Users/davidcastledine/Downloads/trip-planner"

# First arg is trip ID if it doesn't start with a quote/space
TRIP="${1:-scotland-2026}"
MSG="${2:-Update $TRIP $(date '+%d %b %Y %H:%M')}"

echo "✈️  Trip Planner — Deploy [$TRIP]"
echo "────────────────────────────────────────"

# 1. Build HTML
echo "▶ Building HTML..."
python3 "$SCRIPT_DIR/builders/build_html.py" --trip "$TRIP"

# 2. Run tests
echo "▶ Running tests..."
python3 "$SCRIPT_DIR/tests/test_all.py" --trip "$TRIP" --no-live-links 2>/dev/null || \
python3 "$SCRIPT_DIR/tests/test_all.py" --trip "$TRIP" 2>&1 | grep -E "^(  ✗|=)" | grep -v "docx2txt"

# 3. Copy to GitHub Pages repo (each trip gets its own subdirectory)
DEST="$PAGES_REPO/$TRIP"
mkdir -p "$DEST"
echo "▶ Copying index.html → $DEST"
cp "$SCRIPT_DIR/trips/$TRIP/output/index.html" "$DEST/index.html"

# 4. Commit and push
cd "$PAGES_REPO"

if ! git diff --quiet "$TRIP/index.html" 2>/dev/null || git ls-files --others --exclude-standard | grep -q "$TRIP/index.html"; then
    git add "$TRIP/index.html"
    git commit -m "$MSG"
    git push
    echo ""
    echo "✅ Deployed → https://underyoureyes.github.io/trip-planner/$TRIP/"
else
    echo "ℹ  No changes in $TRIP/index.html — nothing to push."
fi
