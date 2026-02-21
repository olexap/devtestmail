FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
        postfix \
        dovecot-imapd \
    && rm -rf /var/lib/apt/lists/*

COPY config/postfix/main.cf     /etc/postfix/main.cf
COPY config/postfix/transport   /etc/postfix/transport
COPY config/dovecot/dovecot.conf /etc/dovecot/dovecot.conf
COPY entrypoint.sh              /entrypoint.sh

RUN chmod +x /entrypoint.sh \
    && chmod 644 /etc/postfix/transport

# SMTP (25), SMTP submission (587), IMAP (143)
EXPOSE 25 587 143

ENTRYPOINT ["/entrypoint.sh"]
