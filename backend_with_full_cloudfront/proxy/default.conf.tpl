server {
  listen ${PROXY_PORT};
  listen [::]:${PROXY_PORT};
  server_name localhost;

  location / {
    proxy_pass http://${APP_HOST}:${APP_PORT};
    include proxy_params;
  }
}
