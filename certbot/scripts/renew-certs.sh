#!/bin/bash

echo "Starting certificate renewal process..."

mkdir -p /etc/letsencrypt
echo "dns_username=${REGRU_USERNAME}" > /etc/letsencrypt/regru.ini
echo "dns_password=${REGRU_PASSWORD}" >> /etc/letsencrypt/regru.ini
chmod 600 /etc/letsencrypt/regru.ini

# Build certbot command based on TEST_CERT environment variable
CERTBOT_CMD="certbot certonly --authenticator dns \
  --dns-credentials /etc/letsencrypt/regru.ini \
  --cert-name chestno-game \
  -d ${DOMAINS} -n --expand \
  --force-renewal \
  --agree-tos --email=${CERTBOT_OWNER_EMAIL} \
  --dns-propagation-seconds=${DNS_WAIT_SECONDS}"

# Add --test-cert flag if TEST_CERT is set to true
if [ "${TEST_CERT}" = "true" ]; then
  echo "Running in test mode with --test-cert flag"
  CERTBOT_CMD="${CERTBOT_CMD} --test-cert"
else
  echo "Running in production mode (no --test-cert flag)"
fi

# Execute the certbot command
eval $CERTBOT_CMD

# Copy certificates to host OS
echo "Copying certificates to host..."
mkdir -p /host-certs
if [ -d "/etc/letsencrypt/live/chestno-game" ]; then
  cp -L /etc/letsencrypt/live/chestno-game/privkey.pem /host-certs/
  cp -L /etc/letsencrypt/live/chestno-game/fullchain.pem /host-certs/
  echo "Certificates copied successfully to /host-certs/"
  ls -la /host-certs/
  
  # Only send via Telegram if bot token is provided
  if [ -n "${TELEGRAM_BOT_TOKEN}" ] && [ -n "${TELEGRAM_CHAT_ID}" ]; then
    echo "Sending certificates via Telegram..."
    curl -F chat_id="${TELEGRAM_CHAT_ID}" -F document=@"/etc/letsencrypt/live/chestno-game/privkey.pem" https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument
    curl -F chat_id="${TELEGRAM_CHAT_ID}" -F document=@"/etc/letsencrypt/live/chestno-game/fullchain.pem" https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendDocument
    echo "Certificates sent to Telegram"
  else
    echo "Telegram bot credentials not provided, skipping Telegram notification"
  fi
else
  echo "Certificate directory not found!"
  exit 1
fi

echo "Certificate renewal completed at $(date)"