# 1. Base image
FROM nginx:latest

ARG ollama_host_name=ollama
ENV OLLAMA_HOST_NAME=$ollama_host_name

# Install required packages: SSH + envsubst
RUN apt-get update && \
    apt-get install -y \
        openssh-server \
        gettext-base \
        curl \
    && apt-get clean

# Configure SSH
RUN mkdir /var/run/sshd

# Set root password (CHANGE THIS!)
RUN echo 'root:root' | chpasswd

# Allow root login (for debugging only)
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# Optional: avoid PAM issues
RUN sed -i 's@session\s\+required\s\+pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

# Copy NGINX template
COPY .nginx/nginx.conf.template /etc/nginx/templates/nginx.conf.template

# Expose ports
EXPOSE 80 2222

# Start both SSH and Nginx
CMD ["/bin/sh", "-c", "\
    envsubst '${OLLAMA_HOST_NAME}' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/conf.d/default.conf && \
    service ssh start && \
    nginx -g 'daemon off;' \
"]