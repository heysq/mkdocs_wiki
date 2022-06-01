```shell
sudo certbot certonly  -d "*.heysq.com" -d heysq.com --manual --preferred-challenges dns  --server https://acme-v02.api.letsencrypt.org/directory
```