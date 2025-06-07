#!/usr/bin/env bash
#===============================================================================
# PostgreSQL Backup Script
# Creates a compressed backup of a PostgreSQL database securely
# Supports options:
#   -d <days>    : delete backups older than <days>
#   -c           : clear all backups except the latest one (asks for confirmation)
#===============================================================================
set -euo pipefail
IFS=$'\n\t'

#===============================================================================
# Configuration and argument parsing
#===============================================================================

# Load environment variables from .env file if present
if [ -f ".env" ]; then
  source .env
else
  echo "❌ .env file not found. Please create one based on .env.example"
  exit 1
fi

# Ensure required variables are set
: "${DB_NAME:?DB_NAME must be set}"
: "${DB_USER:?DB_USER must be set}"
: "${DATABASES_PASSWORD:?DATABASES_PASSWORD must be set}"

# Optional variables with defaults
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
BACKUP_DIR="${BACKUP_DIR:-./backups}"

# Defaults for retention and clear flags
RETENTION_DAYS=""
CLEAR_ALL=false

usage() {
  echo "Usage: $0 [-d <days>] [-c]"
  echo "  -d <days>   Delete backups older than <days>"
  echo "  -c          Clear all backups except the latest one (asks for confirmation)"
  exit 1
}

# Parse arguments
while getopts ":d:c" opt; do
  case $opt in
    d)
      if [[ "$OPTARG" =~ ^[0-9]+$ ]]; then
        RETENTION_DAYS="$OPTARG"
      else
        echo "❌ Option -d requires a numeric argument."
        usage
      fi
      ;;
    c)
      CLEAR_ALL=true
      ;;
    \?)
      echo "❌ Invalid option: -$OPTARG"
      usage
      ;;
    :)
      echo "❌ Option -$OPTARG requires an argument."
      usage
      ;;
  esac
done

#===============================================================================
# Backup filename and logging setup
#===============================================================================
DATE=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${DB_NAME}_${DATE}.dump"
LOG_FILE="${BACKUP_DIR}/backup.log"

#===============================================================================
# Run backup
#===============================================================================
mkdir -p "$BACKUP_DIR"
echo "[INFO] Starting backup of ${DB_NAME} at ${DATE}" | tee -a "$LOG_FILE"

export PGPASSWORD="$DATABASES_PASSWORD"
if pg_dump -U "$DB_USER" -h "$DB_HOST" -p "$DB_PORT" -Fc -f "$BACKUP_FILE" "$DB_NAME"; then
  echo "[✅] Backup completed successfully: $BACKUP_FILE" | tee -a "$LOG_FILE"
else
  echo "[❌] Backup failed!" | tee -a "$LOG_FILE" >&2
  exit 1
fi

#===============================================================================
# Cleanup old backups or clear all except latest
#===============================================================================
if [ "$CLEAR_ALL" = true ]; then
  echo -n "[WARNING] You are about to delete ALL backup files except the latest one ($BACKUP_FILE). Are you sure? (y/n): "
  read -r answer
  case "$answer" in
    [Yy]* )
      echo "[INFO] Deleting all backup files except the latest backup..." | tee -a "$LOG_FILE"
      find "$BACKUP_DIR" -type f -name "*.dump" ! -name "$(basename "$BACKUP_FILE")" -print -delete | tee -a "$LOG_FILE"
      echo "[✔] Old backups deleted, latest backup preserved." | tee -a "$LOG_FILE"
      ;;
    * )
      echo "[INFO] Delete all backups canceled by user." | tee -a "$LOG_FILE"
      ;;
  esac
elif [ -n "$RETENTION_DAYS" ]; then
  echo "[INFO] Cleaning up backups older than ${RETENTION_DAYS} days..." | tee -a "$LOG_FILE"
  find "$BACKUP_DIR" -type f -name "*.dump" -mtime +"$RETENTION_DAYS" -print -delete | tee -a "$LOG_FILE"
  echo "[✔] Cleanup done." | tee -a "$LOG_FILE"
else
  echo "[INFO] No cleanup option specified, skipping backup deletion." | tee -a "$LOG_FILE"
fi
