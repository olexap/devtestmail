#!/bin/bash
# entrypoint.sh – set up the mail user and start Postfix + Dovecot.
set -e

MAIL_USER="${MAIL_USER:-testuser}"
MAIL_PASS="${MAIL_PASS:-testpass}"
MAIL_DOMAIN="${MAIL_DOMAIN:-devtestmail.local}"

# ── Create the mail user ──────────────────────────────────────────────────────
if ! id "${MAIL_USER}" &>/dev/null; then
    useradd -m -s /usr/sbin/nologin "${MAIL_USER}"
fi
echo "${MAIL_USER}:${MAIL_PASS}" | chpasswd
mkdir -p "/home/${MAIL_USER}/Maildir/"{cur,new,tmp}
chown -R "${MAIL_USER}:${MAIL_USER}" "/home/${MAIL_USER}/Maildir"

# ── Configure Postfix ─────────────────────────────────────────────────────────
postconf -e "luser_relay = ${MAIL_USER}"
postconf -e "mydomain = ${MAIL_DOMAIN}"
postconf -e "myorigin = ${MAIL_DOMAIN}"

# Enable the submission (587) port if not already present in master.cf
if ! grep -qE "^submission" /etc/postfix/master.cf; then
    printf 'submission inet n - y - - smtpd\n' >> /etc/postfix/master.cf
fi

# Build the transport hash map
postmap /etc/postfix/transport

# ── Configure Dovecot ─────────────────────────────────────────────────────────
# Write a passwd-file entry for Dovecot authentication
MAIL_UID=$(id -u "${MAIL_USER}")
MAIL_GID=$(id -g "${MAIL_USER}")
printf '%s:{PLAIN}%s:%s:%s::/home/%s::\n' \
    "${MAIL_USER}" "${MAIL_PASS}" "${MAIL_UID}" "${MAIL_GID}" "${MAIL_USER}" \
    > /etc/dovecot/users
chmod 640 /etc/dovecot/users
chgrp dovecot /etc/dovecot/users

# ── Start services ────────────────────────────────────────────────────────────
# Ensure Postfix queue and chroot are initialised
postfix check

# Start Dovecot in the background
dovecot

# Run Postfix in the foreground – keeps the container alive
exec postfix start-fg
