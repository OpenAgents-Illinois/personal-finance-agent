#!/usr/bin/env bash
# record.sh — Mac app mode screen recording for Personal Finance Agent (localhost:3000)
# Prerequisites: ffmpeg, cliclick, and Accessibility permission for cliclick
# Usage: bash recordings/record.sh

set -euo pipefail

RECORDINGS_DIR="$(cd "$(dirname "$0")" && pwd)"
RAW_MP4="$RECORDINGS_DIR/raw.mp4"
MOMENTS_FILE="$RECORDINGS_DIR/moments.jsonl"

# ── Timing constants (ms) ────────────────────────────────────────────────────
CLIP_START_OFFSET_MS=500
CLIP_END_OFFSET_MS=1000
MERGE_GAP_THRESHOLD=2000
SPLIT_GAP_THRESHOLD=3000

# ── Helpers ──────────────────────────────────────────────────────────────────
ts() { date +%s%3N; }

log_moment() {
  local type="$1" label="$2" x="${3:-0}" y="${4:-0}" value="${5:-}"
  local t; t=$(ts)
  echo "{\"timestamp\": $t, \"type\": \"$type\", \"x\": $x, \"y\": $y, \"label\": \"$label\", \"value\": \"$value\"}" >> "$MOMENTS_FILE"
}

click() {
  local x=$1 y=$2 label="${3:-click}"
  log_moment "click" "$label" "$x" "$y"
  cliclick c:"$x,$y"
}

dclick() {
  local x=$1 y=$2 label="${3:-double-click}"
  log_moment "click" "$label" "$x" "$y"
  cliclick dc:"$x,$y"
}

type_text() {
  local text="$1" label="${2:-type}"
  log_moment "type" "$label" 0 0 "$text"
  osascript -e "tell application \"System Events\" to keystroke \"$text\""
}

keystroke() {
  local key="$1" label="${2:-keystroke}"
  log_moment "keystroke" "$label" 0 0 "$key"
  osascript -e "tell application \"System Events\" to key code $(key_code \"$key\")" 2>/dev/null \
    || cliclick kp:"$key"
}

key_code() {
  case "$1" in
    return|enter) echo 36 ;;
    tab)          echo 48 ;;
    arrow-down)   echo 125 ;;
    arrow-up)     echo 126 ;;
    arrow-left)   echo 123 ;;
    arrow-right)  echo 124 ;;
    esc)          echo 53 ;;
    space)        echo 49 ;;
    delete)       echo 51 ;;
    *)            echo 36 ;;  # fallback to return
  esac
}

move_to() {
  local x=$1 y=$2 label="${3:-move}"
  log_moment "move" "$label" "$x" "$y"
  cliclick m:"$x,$y"
}

pause() {
  local ms=$1
  sleep "$(echo "scale=3; $ms/1000" | bc)"
}

scroll_down() {
  local x=$1 y=$2 label="${3:-scroll}"
  log_moment "scroll" "$label" "$x" "$y"
  # Simulate scroll with AppleScript
  osascript -e "tell application \"System Events\" to scroll down in scroll area 1 of window 1 of process \"Google Chrome\""
}

# ── Pre-flight ────────────────────────────────────────────────────────────────
echo "▶ Checking prerequisites..."
command -v ffmpeg   >/dev/null || { echo "✗ ffmpeg not found. Run: brew install ffmpeg"; exit 1; }
command -v cliclick >/dev/null || { echo "✗ cliclick not found. Run: brew install cliclick"; exit 1; }

echo "▶ Listing avfoundation devices..."
ffmpeg -f avfoundation -list_devices true -i "" 2>&1 | grep -E "AVFoundation|^\[" || true

# Clean previous run
rm -f "$RAW_MP4" "$MOMENTS_FILE"
touch "$MOMENTS_FILE"

# ── Step 1: Focus Chrome (tab already open at localhost:3000) ────────────────
echo "▶ Focusing Chrome (localhost:3000 tab should already be open)..."
osascript -e 'tell application "Google Chrome" to activate'
pause 1000

# ── Step 2: Get Chrome window bounds for ffmpeg crop ─────────────────────────
BOUNDS=$(osascript -e '
  tell application "Google Chrome"
    set b to bounds of front window
    return ((item 1 of b) as string) & "," & ((item 2 of b) as string) & "," & ((item 3 of b) as string) & "," & ((item 4 of b) as string)
  end tell')
echo "▶ Chrome bounds: $BOUNDS"

# Strip any spaces AppleScript may inject around commas
BOUNDS_CLEAN="${BOUNDS// /}"
IFS=',' read -r WIN_X WIN_Y WIN_X2 WIN_Y2 <<< "$BOUNDS_CLEAN"
WIN_X="${WIN_X//[^0-9-]/}"
WIN_Y="${WIN_Y//[^0-9-]/}"
WIN_X2="${WIN_X2//[^0-9-]/}"
WIN_Y2="${WIN_Y2//[^0-9-]/}"
WIN_W=$(( WIN_X2 - WIN_X ))
WIN_H=$(( WIN_Y2 - WIN_Y ))

# Ensure even dimensions for libx264
WIN_W=$(( WIN_W - (WIN_W % 2) ))
WIN_H=$(( WIN_H - (WIN_H % 2) ))

echo "▶ Capture region: ${WIN_W}x${WIN_H} at (${WIN_X},${WIN_Y})"

# ── Step 3: Start ffmpeg capture ─────────────────────────────────────────────
echo "▶ Starting screen capture..."
# Device index 1 = main display (adjust if your setup differs)
ffmpeg -y \
  -f avfoundation \
  -framerate 30 \
  -i "1:none" \
  -vf "crop=${WIN_W}:${WIN_H}:${WIN_X}:${WIN_Y},scale=1280:-2" \
  -c:v libx264 \
  -preset ultrafast \
  -pix_fmt yuv420p \
  -movflags frag_keyframe+empty_moov+default_base_moof \
  "$RAW_MP4" \
  > "$RECORDINGS_DIR/ffmpeg.log" 2>&1 &
FFMPEG_PID=$!
echo "▶ ffmpeg PID: $FFMPEG_PID"

# Wait for ffmpeg to start capturing
pause 2000
log_moment "start" "recording started" 0 0

# ── Step 4: Log in (via JavaScript — no coordinate guessing) ─────────────────
echo "▶ Logging in..."
CENTER_X=$(( WIN_X + WIN_W / 2 ))
CENTER_Y=$(( WIN_Y + WIN_H / 2 ))

pause 1000
log_moment "navigate" "Sign In page" "$CENTER_X" "$CENTER_Y"

# Fill credentials and submit using JS so it works regardless of layout/resolution.
# Change EMAIL and PASSWORD to match your actual account.
# Load credentials from recordings/.env (never committed — see .gitignore)
ENV_FILE="$RECORDINGS_DIR/.env"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE" || { echo "✗ Missing $ENV_FILE — copy recordings/.env.example and fill in credentials"; exit 1; }
EMAIL="${RECORDING_EMAIL:?RECORDING_EMAIL not set in .env}"
PASSWORD="${RECORDING_PASSWORD:?RECORDING_PASSWORD not set in .env}"
# Plaid sandbox credentials (public test values — safe to hardcode)
PLAID_USER="user_good"
PLAID_PASS="pass_good"
PLAID_PHONE="4155550011"
PLAID_OTP="123456"

osascript <<APPLESCRIPT
tell application "Google Chrome"
  tell front window's active tab
    execute javascript "
      document.getElementById('user_email').value = '${EMAIL}';
      document.getElementById('user_password').value = '${PASSWORD}';
    "
  end tell
end tell
APPLESCRIPT
pause 600

log_moment "type" "fill email" "$CENTER_X" "$CENTER_Y" "$EMAIL"
log_moment "type" "fill password" "$CENTER_X" "$CENTER_Y" "***"

# Click the submit button visually so it appears in the recording
osascript <<APPLESCRIPT
tell application "Google Chrome"
  tell front window's active tab
    execute javascript "document.querySelector('input[type=submit]').click();"
  end tell
end tell
APPLESCRIPT

log_moment "click" "Sign In button" "$CENTER_X" "$CENTER_Y"
pause 3000  # wait for redirect to dashboard

# ── Step 5: Dashboard ─────────────────────────────────────────────────────────
echo "▶ Recording Dashboard..."
log_moment "navigate" "Dashboard" "$CENTER_X" "$CENTER_Y"
pause 1500

# Scroll down to show spending breakdown
move_to "$CENTER_X" "$CENTER_Y" "hover dashboard"
pause 800
log_moment "scroll" "scroll to categories" "$CENTER_X" "$CENTER_Y"
osascript -e "
  tell application \"System Events\"
    tell process \"Google Chrome\"
      scroll (scroll area 1 of group 1 of group 1 of UI element 1 of tab group 1 of front window) by -5
    end tell
  end tell" 2>/dev/null || true
pause 1200

# Month nav — click previous month
PREV_BTN_X=$(( WIN_X + 160 ))
PREV_BTN_Y=$(( WIN_Y + 120 ))
click "$PREV_BTN_X" "$PREV_BTN_Y" "Previous month button"
pause 1500
log_moment "navigate" "previous month view" "$PREV_BTN_X" "$PREV_BTN_Y"

# Next month back
NEXT_BTN_X=$(( WIN_X + WIN_W - 160 ))
click "$NEXT_BTN_X" "$PREV_BTN_Y" "Next month button"
pause 1500

# ── Step 6: Subscriptions page ───────────────────────────────────────────────
echo "▶ Navigating to Subscriptions..."
# Click nav link (left sidebar) — approximated position
NAV_SUBS_X=$(( WIN_X + 100 ))
NAV_SUBS_Y=$(( WIN_Y + 220 ))
click "$NAV_SUBS_X" "$NAV_SUBS_Y" "Subscriptions nav link"
pause 2000
log_moment "navigate" "Subscriptions page" "$NAV_SUBS_X" "$NAV_SUBS_Y"
pause 1000

# ── Step 7: Action Plan page ──────────────────────────────────────────────────
echo "▶ Navigating to Action Plan..."
NAV_ACTION_Y=$(( WIN_Y + 280 ))
click "$NAV_SUBS_X" "$NAV_ACTION_Y" "Action Plan nav link"
pause 2000
log_moment "navigate" "Action Plan page" "$NAV_SUBS_X" "$NAV_ACTION_Y"
pause 1000

# Scroll to see recommendations
move_to "$CENTER_X" "$CENTER_Y" "hover action plan"
pause 800

# ── Step 8: Settings page + Plaid sandbox connect ────────────────────────────
echo "▶ Navigating to Settings..."
NAV_SETTINGS_Y=$(( WIN_Y + 340 ))
click "$NAV_SUBS_X" "$NAV_SETTINGS_Y" "Settings nav link"
pause 2000
log_moment "navigate" "Settings page" "$NAV_SUBS_X" "$NAV_SETTINGS_Y"
pause 1500

# Click "Connect a bank account" button via JS — reliable regardless of layout
echo "▶ Clicking Connect a bank account..."
osascript <<APPLESCRIPT
tell application "Google Chrome"
  tell front window's active tab
    execute javascript "document.querySelector('[data-controller=\"plaid-link\"]').click();"
  end tell
end tell
APPLESCRIPT
CONNECT_BTN_X=$(( WIN_X + WIN_W / 2 ))
CONNECT_BTN_Y=$(( WIN_Y + 420 ))
log_moment "click" "Connect a bank account button" "$CONNECT_BTN_X" "$CONNECT_BTN_Y"
pause 3000  # Plaid Link modal takes a moment to load
log_moment "navigate" "Plaid Link modal opened" "$CONNECT_BTN_X" "$CONNECT_BTN_Y"

# ── Plaid Link modal interaction ──────────────────────────────────────────────
# Plaid modal is a centered iframe overlay. Search input is auto-focused on open.
# We use keyboard navigation so typing is visible and focus is guaranteed.
MODAL_X="$CENTER_X"
MODAL_TOP=$(( WIN_Y + 80 ))

# ── Plaid Link modal flow ─────────────────────────────────────────────────────
# Order: phone → OTP → select Tartan Bank → username/password → continue
MODAL_X="$CENTER_X"
MODAL_TOP=$(( WIN_Y + 80 ))
SUBMIT_Y=$(( MODAL_TOP + 410 ))
INPUT_Y=$(( MODAL_TOP + 280 ))

# Step 1: Phone number
echo "▶ Entering Plaid sandbox phone number..."
click "$MODAL_X" "$INPUT_Y" "Plaid phone field"
pause 600
type_text "$PLAID_PHONE"
pause 500
log_moment "type" "Plaid phone" "$MODAL_X" "$INPUT_Y" "$PLAID_PHONE"
click "$MODAL_X" "$SUBMIT_Y" "Plaid submit phone"
pause 2500
log_moment "navigate" "Plaid: phone submitted" "$MODAL_X" "$SUBMIT_Y"

# Step 2: OTP code
echo "▶ Entering Plaid sandbox OTP..."
click "$MODAL_X" "$INPUT_Y" "Plaid OTP field"
pause 600
type_text "$PLAID_OTP"
pause 500
log_moment "type" "Plaid OTP" "$MODAL_X" "$INPUT_Y" "$PLAID_OTP"
click "$MODAL_X" "$SUBMIT_Y" "Plaid submit OTP"
pause 2500
log_moment "navigate" "Plaid: OTP submitted" "$MODAL_X" "$SUBMIT_Y"

# Step 3: Tartan Bank appears — click it
TARTAN_Y=$(( MODAL_TOP + 220 ))
echo "▶ Clicking Tartan Bank..."
click "$MODAL_X" "$TARTAN_Y" "Select Tartan Bank"
pause 2500
log_moment "navigate" "Plaid: selected Tartan Bank" "$MODAL_X" "$TARTAN_Y"

# Step 4: Password only
PASS_Y=$(( MODAL_TOP + 280 ))
echo "▶ Entering Plaid sandbox password..."
click "$MODAL_X" "$PASS_Y" "Plaid password field"
pause 600
type_text "$PLAID_PASS"
pause 500
log_moment "type" "Plaid password" "$MODAL_X" "$PASS_Y" "$PLAID_PASS"

# Submit credentials
click "$MODAL_X" "$SUBMIT_Y" "Plaid submit credentials"
pause 3000
log_moment "navigate" "Plaid: credentials submitted" "$MODAL_X" "$SUBMIT_Y"

# Account selection — Continue
click "$MODAL_X" "$SUBMIT_Y" "Plaid continue account selection"
pause 3000
log_moment "navigate" "Plaid: accounts selected" "$MODAL_X" "$SUBMIT_Y"

# Success — Continue
click "$MODAL_X" "$SUBMIT_Y" "Plaid finish connection"
pause 3000
log_moment "navigate" "Plaid: bank connected" "$MODAL_X" "$SUBMIT_Y"
echo "▶ Plaid sandbox bank connected."
pause 2000  # page reloads with connected bank visible

# ── Step 9: Back to Dashboard ─────────────────────────────────────────────────
echo "▶ Returning to Dashboard..."
NAV_DASH_Y=$(( WIN_Y + 160 ))
click "$NAV_SUBS_X" "$NAV_DASH_Y" "Dashboard nav link"
pause 2000
log_moment "navigate" "back to Dashboard" "$NAV_SUBS_X" "$NAV_DASH_Y"
pause 1000

# ── Step 10: Stop capture ─────────────────────────────────────────────────────
echo "▶ Stopping capture..."
log_moment "end" "recording complete" 0 0

# SIGINT tells ffmpeg to stop capturing; fragmented MP4 is already valid on disk
kill -INT "$FFMPEG_PID" 2>/dev/null || true
sleep 3
# Force kill if still alive — file is safe because of frag_keyframe+empty_moov
kill -9 "$FFMPEG_PID" 2>/dev/null || true

echo ""
echo "✔ Raw recording saved to: $RAW_MP4"
echo "✔ Moments log saved to:   $MOMENTS_FILE"
echo ""
echo "Next: run  node recordings/process.mjs  to render the polished video."
