## SSL directory
Files `logotipiwe.ru.crt` and `logotipiwe.ru.key` should be copied here by deploy script

## Create local certs 
```shell
openssl req -newkey rsa:2048 -nodes -keyout privkey.pem -out domain.csr && \
openssl x509 -signkey privkey.pem -in domain.csr -req -days 365 -out fullchain.pem && \
rm domain.csr
```

## Create certs by certbot
### Regular domain cert
On server shell:
```shell
sudo apt install certbot -y
sudo certbot certonly --webroot --webroot-path /honest/ingress/well-known -m german.reus@bk.ru -n --agree-tos -d chestno-game.online
```
Copy certs from `/etc/letsencrypt/live/chestno-game.online/` to secrets repo

### Wildcard domain cert
On server shell:
```shell
certbot certonly -d *.chestno-game.online --manual
```
Put txt record in <a href="https://www.reg.ru/user/account/#/services">reg.ru panel</a>. Wait for 20m or more :(