## SSL directory
Files `logotipiwe.ru.crt` and `logotipiwe.ru.key` should be copied here by deploy script

## Create local certs 
```shell
openssl req -newkey rsa:2048 -nodes -keyout logotipiwe.ru.key -out logotipiwe.ru.csr && \
openssl x509 -signkey logotipiwe.ru.key -in logotipiwe.ru.csr -req -days 365 -out logotipiwe.ru.crt
```

## Create certs by certbot
On server shell:
```shell
sudo apt install certbot -y
sudo certbot certonly --webroot --webroot-path /honest/ingress/well-known -m german.reus@bk.ru -n --agree-tos -d chestno-game.online
```
Copy certs from `/etc/letsencrypt/live/chestno-game.online/` to secrets repo
