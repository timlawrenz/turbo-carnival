#!/bin/bash

# Turbo Carnival - Scheduled Posting Script
# This script ensures the correct Ruby version is used via RVM

set -e

APP_DIR="/home/tim/source/activity/turbo-carnival"
LOG_FILE="/home/tim/source/activity/turbo-carnival/log/scheduled_posting.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=========================================="
log "Starting scheduled post check"

if [ -s "$HOME/.rvm/scripts/rvm" ]; then
    source "$HOME/.rvm/scripts/rvm"
elif [ -s "/usr/share/rvm/scripts/rvm" ]; then
    source "/usr/share/rvm/scripts/rvm"
else
    log "ERROR: RVM not found"
    exit 1
fi

cd "$APP_DIR" || {
    log "ERROR: Cannot change to $APP_DIR"
    exit 1
}

rvm use 3.4.1 2>&1 | tee -a "$LOG_FILE"

RUBY_VERSION=$(ruby -v)
log "Using Ruby: $RUBY_VERSION"

log "Running scheduled post task..."
bundle exec rails scheduling:post_scheduled 2>&1 | tee -a "$LOG_FILE"

EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
    log "Completed successfully"
else
    log "ERROR: Task exited with code $EXIT_CODE"
fi

log "=========================================="

exit $EXIT_CODE
