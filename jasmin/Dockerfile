FROM python:3.12-slim

# Install system deps Jasmin expects
RUN apt-get update && apt-get install -y \
    redis-server \
    rabbitmq-server \
    supervisor \
    telnet \
    && rm -rf /var/lib/apt/lists/*

# Install Jasmin properly (like the devs expect)
RUN pip install --no-cache-dir "setuptools<81" jasmin

# Create required dirs
RUN mkdir -p /etc/jasmin /var/log/jasmin /var/lib/jasmin

# Copy supervisor config
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 2775 1401 8990

CMD ["/usr/bin/supervisord"]
