# 1. For Nginx setup
FROM nginx:latest

ARG ollama_host_name=localhost
ENV OLLAMA_HOST_NAME=$ollama_host_name

# Copy NGINX configuration template into the container
COPY .nginx/nginx.conf.template /etc/nginx/templates/nginx.conf.template

# Install envsubst, which is part of gettext package
RUN apt-get update && apt-get install -y gettext-base && apt-get clean

# Command to replace placeholders with environment variables and start NGINX
CMD ["/bin/sh", "-c", "envsubst '${OLLAMA_HOST_NAME}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]