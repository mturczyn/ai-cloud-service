# 1. For Nginx setup
# FROM ollama/ollama:latest
FROM nginx:latest
# COPY ./index.html /usr/share/nginx/html/index.html

# Copy config nginx
COPY /.nginx/nginx.conf /etc/nginx/conf.d/default.conf

# WORKDIR /usr/share/nginx/html

# # Remove default nginx static assets
# RUN rm -rf ./*

# Containers run nginx with global directives and daemon off
# ENTRYPOINT ["nginx", "-g", "daemon off;"]