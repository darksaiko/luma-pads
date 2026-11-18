#!/bin/bash
# Auto-deploy for Luma Trigger.
# Run by a cPanel cron job every few minutes: checks GitHub for a new version and,
# if the live copy is out of date, copies index.html into the live folder.
# Paths can be overridden with environment variables (used for testing).

REPO="${REPO:-/home/alpacaqr/repositories/trigger}"
LIVE="${LIVE:-/home/alpacaqr/public_html/trigger}"
LOG="${LOG:-/home/alpacaqr/deploy-trigger.log}"
LOCK="${LOCK:-/home/alpacaqr/.deploy-trigger.lock}"

cd "$REPO" || exit 1

# Only one run at a time: if a previous run is still going, this one just skips.
if command -v flock >/dev/null 2>&1; then exec 9>"$LOCK"; flock -n 9 || exit 0; fi
# Never let a check hang: give up on GitHub after 60 seconds and try again on the next run.
T=""; command -v timeout >/dev/null 2>&1 && T="timeout 60"

$T git fetch -q origin main 2>>"$LOG" || { echo "$(date '+%F %T') fetch failed" >> "$LOG"; exit 1; }

# Make the repo folder match GitHub exactly (this folder is only used for deploying).
git reset -q --hard origin/main 2>>"$LOG" || { echo "$(date '+%F %T') reset failed" >> "$LOG"; exit 1; }

# Copy only when the live file is missing or different.
if ! cmp -s "$REPO/index.html" "$LIVE/index.html"; then
  mkdir -p "$LIVE" && cp -f "$REPO/index.html" "$LIVE/index.html" && chmod 644 "$LIVE/index.html" \
    && echo "$(date '+%F %T') deployed $(git rev-parse --short HEAD): $(git log -1 --pretty=%s)" >> "$LOG" \
    || echo "$(date '+%F %T') copy failed" >> "$LOG"
fi
