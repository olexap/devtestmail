# devtestmail

A minimal Docker-based mail server for local development and testing.

* **SMTP** on port 25 (plain) and 587 (submission)
* **IMAP** on port 143
* All mail is **always delivered locally** – no message ever leaves the container.
* A configurable **catch-all mailbox** receives every email regardless of recipient address or domain.

---

## Quick start

```bash
docker compose up --build
```

That's it. The server is ready once you see `postfix/master` in the log output.

### Default credentials

| Setting | Default |
|---------|---------|
| IMAP / SMTP user | `testuser` |
| IMAP / SMTP password | `testpass` |
| Domain | `devtestmail.local` |

Credentials and domain can be changed via environment variables (see *Configuration* below).

---

## Connecting from another container

Add `devtestmail` (the container name) as the SMTP host in your application's mail settings:

```
SMTP host : devtestmail   (or the service name from your compose file)
SMTP port : 25            (no auth) or 587
IMAP host : devtestmail
IMAP port : 143
Username  : testuser
Password  : testpass
```

Example `docker-compose.yml` fragment that links your app to this mail server:

```yaml
services:
  myapp:
    image: myapp
    depends_on:
      - mail
    environment:
      SMTP_HOST: mail
      SMTP_PORT: 25

  mail:
    image: devtestmail   # built from this repo
    # … (ports, env, etc.)
```

---

## Reading sent mail

Point any IMAP client at `localhost:143` (or the container's host) and log in with the credentials above. Every email delivered to **any** address lands in `testuser`'s inbox.

Popular desktop clients: **Thunderbird**, **Apple Mail**, **Outlook**.  
CLI option: `mutt -f imap://testuser:testpass@localhost/INBOX`

---

## Configuration

| Environment variable | Default | Description |
|----------------------|---------|-------------|
| `MAIL_USER` | `testuser` | Linux user and IMAP/SMTP login |
| `MAIL_PASS` | `testpass` | Password for that user |
| `MAIL_DOMAIN` | `devtestmail.local` | Mail domain used by Postfix |

---

## Architecture

| Component | Role |
|-----------|------|
| **Postfix** | Accepts SMTP connections; routes all mail to the local transport (never relays outward) |
| **Dovecot** | Serves IMAP so clients can read the delivered mail |
| **catch-all** | Postfix `luser_relay` redirects any unknown recipient to `MAIL_USER`, so mail to `alice@example.com`, `bob@gmail.com`, etc. all end up in the same inbox |
