# 1. For Nginx setup
FROM nginx:latest

# Copy config nginx
COPY /.nginx/nginx.conf /etc/nginx/conf.d/default.conf