server {
  listen ${PROXY_PORT};
  listen [::]:${PROXY_PORT};
  server_name localhost;

  location / {
    proxy_pass http://${APP_HOST}:${APP_PORT};
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host $host;
    proxy_cache_bypass $http_upgrade;
  }
}
