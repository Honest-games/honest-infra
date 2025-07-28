FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y wget gnupg2 curl lsb-release cron && \
    echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get install -y postgresql-client-16 && \
    mkdir /backup

COPY pg_backup_and_send.sh /app/pg_backup_and_send.sh
COPY crontab.txt /app/crontab.txt
COPY entrypoint.sh /app/entrypoint.sh

RUN chmod +x /app/*.sh

VOLUME /backup

ENTRYPOINT ["/app/entrypoint.sh"]
