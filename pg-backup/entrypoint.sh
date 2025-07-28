#!/bin/sh

printenv | grep -E "PG_HOST|PG_PORT|PG_USER|PG_PASS|TG_BOT_TOKEN|TG_CHAT_ID" > /etc/environment

#./app/pg_backup_and_send.sh
crontab /app/crontab.txt
cron
touch /var/log/cron.log
tail -f /var/log/cron.log
