FROM certbot/certbot:latest

RUN apk add --no-cache dcron curl
RUN pip install certbot-regru
WORKDIR /

ENTRYPOINT ["sh", "/entrypoint.sh"]