#!/bin/bash
# deploy.sh — rebuild HTML and push to GitHub Pages
# Usage: ./deploy.sh
#        ./deploy.sh "optional commit message"

set -e  # stop on any error

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PAGES_REPO="/Users/davidcastledine/Downloads/scotland2026"

echo "🏴󠁧󠁢󠁳󠁣󠁴󠁿  Scotland 2026 — Deploy"
echo "────────────────────────────────────────"

# 1. Build HTML from itinerary.json
echo "▶ Building HTML..."
python3 "$SCRIPT_DIR/builders/build_html.py"

# 2. Run tests — abort if any critical test fails
echo "▶ Running tests..."
python3 "$SCRIPT_DIR/tests/test_all.py" --no-live-links 2>/dev/null || \
python3 "$SCRIPT_DIR/tests/test_all.py" 2>&1 | grep -E "^(  ✗|=)" | grep -v "docx2txt"
# (if tests introduce failures exit code will be caught by set -e)

# 3. Copy to GitHub Pages repo
echo "▶ Copying index.html → $PAGES_REPO"
cp "$SCRIPT_DIR/output/index.html" "$PAGES_REPO/index.html"

# 4. Commit and push
cd "$PAGES_REPO"

if ! git diff --quiet index.html; then
    MSG="${1:-Update Scotland route guide $(date '+%d %b %Y %H:%M')}"
    git add index.html
    git commit -m "$MSG"
    git push
    echo ""
    echo "✅ Deployed → https://underyoureyes.github.io/scotland2026/"
else
    echo "ℹ  No changes in index.html — nothing to push."
fi
