#!/bin/bash

set -e
set -o pipefail

# === VALIDATE ENV VARS ===
REQUIRED_VARS=("PG_HOST" "PG_PORT" "PG_USER" "PG_PASS" "TG_BOT_TOKEN" "TG_CHAT_ID")
MISSING_VARS=()
for VAR in "${REQUIRED_VARS[@]}"; do
    if [ -z "${!VAR}" ]; then
        MISSING_VARS+=("$VAR")
    fi
done

if [ ${#MISSING_VARS[@]} -ne 0 ]; then
    ERROR_MESSAGE="Ошибка бэкапа: Отсутствует env: ${MISSING_VARS[*]}."
    echo "$ERROR_MESSAGE"
    # Try to send error to Telegram, but don't fail if TG vars are missing
    if [ -n "$TG_BOT_TOKEN" ] && [ -n "$TG_CHAT_ID" ]; then
        curl -sS -X POST "https://api.telegram.org/bot$TG_BOT_TOKEN/sendMessage" \
        -d chat_id="$TG_CHAT_ID" \
        -d text="$ERROR_MESSAGE" > /dev/null
    fi
    exit 1
fi

PG_HOST=$PG_HOST
PG_PORT=$PG_PORT
PG_USER=$PG_USER
PG_PASS=$PG_PASS
BACKUP_DIR="/backup"
TG_BOT_TOKEN=$TG_BOT_TOKEN
TG_CHAT_ID=$TG_CHAT_ID

DATE=$(date +%Y-%m-%d_%H-%M)

# === BACKUP GLOBALS ===
echo "--- Backing up global objects ---"
GLOBALS_FILE_NAME="pg_globals_${DATE}.sql.gz"
PGPASSWORD="$PG_PASS" pg_dumpall -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" --globals-only --no-privileges | gzip > "$BACKUP_DIR/$GLOBALS_FILE_NAME"

# === SEND GLOBALS TO TELEGRAM ===
echo "Sending globals backup to Telegram..."
curl -sS -F chat_id="$TG_CHAT_ID" \
     -F document=@"$BACKUP_DIR/$GLOBALS_FILE_NAME" \
     "https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument"

# === CLEANUP GLOBALS ===
echo "Removing local globals backup file..."
rm "$BACKUP_DIR/$GLOBALS_FILE_NAME"
echo "--- Globals backup finished ---"


# === BACKUP DATABASES ===
echo "Fetching list of databases to backup..."
PGPASSWORD="$PG_PASS" psql -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "postgres" -t -c "SELECT datname FROM pg_database WHERE datistemplate = false AND datname <> 'postgres';" | while read -r PG_DB; do
  if [[ -z "$PG_DB" ]]; then
    continue
  fi

  echo "--- Backing up database: $PG_DB ---"
  
  FILE_NAME="pg_backup_${PG_DB}_${DATE}.sql.gz"
  
  # === BACKUP DATABASE ===
  echo "Dumping and compressing database to $BACKUP_DIR/$FILE_NAME"
  PGPASSWORD="$PG_PASS" pg_dump \
    -h "$PG_HOST" -p "$PG_PORT" -U "$PG_USER" -d "$PG_DB" \
    --no-privileges --inserts | gzip > "$BACKUP_DIR/$FILE_NAME"

  # === SEND DATABASE TO TELEGRAM ===
  echo "Sending backup to Telegram..."
  curl -sS -F chat_id="$TG_CHAT_ID" \
       -F document=@"$BACKUP_DIR/$FILE_NAME" \
       "https://api.telegram.org/bot$TG_BOT_TOKEN/sendDocument"

  # === CLEANUP DATABASE ===
  echo "Removing local backup file..."
  rm "$BACKUP_DIR/$FILE_NAME"
  echo "--- Backup for $PG_DB finished ---"
done

echo "All databases backed up successfully."
