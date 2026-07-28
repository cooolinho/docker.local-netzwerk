# ⚡ Quickstart Mailserver (Roundcube)

In wenigen Schritten startest du Roundcube lokal hinter Traefik.

## 1) Voraussetzungen

- Traefik läuft im Root-Projekt
- Docker Netzwerk `docker_lan_network` existiert
- DNS für `mail.docker.lan` zeigt auf den Docker Host

## 2) In Projekt wechseln

```bash
cd projects/mailserver
```

## 3) Umgebungsdatei erstellen

```bash
cp .env.example .env
```

Danach `.env` anpassen (mindestens Hosts und Passwörter):

- `ROUNDCUBEMAIL_DEFAULT_HOST`
- `ROUNDCUBEMAIL_SMTP_SERVER`
- `ROUNDCUBEMAIL_DB_HOST` (typisch `roundcube-db`)
- `ROUNDCUBEMAIL_DB_PASSWORD`
- `ROUNDCUBEMAIL_DB_ROOT_PASSWORD`

## 4) Alias-Accounts zentral anlegen

```bash
cp secrets/alias-accounts.example.php secrets/alias-accounts.php
cp secrets/alias-master-password.example.txt secrets/alias-master-password.txt
```

Dann `secrets/alias-accounts.php` bearbeiten:

- Keys immer als volle Mailbox (`mail@cooolinho.de`)
- Alias-Login in Roundcube spaeter nur als `alias@` (z. B. `mail@`)
- Echte Hetzner-Mailbox-Credentials als `mailbox_user`/`mailbox_password`
- In `secrets/alias-master-password.txt` ein globales Master-Passwort setzen

Optionaler Syntax- und Strukturcheck:

```bash
php scripts/check-alias-config.php
```

## 5) Stack starten

```bash
docker-compose up -d
docker-compose ps
```

## 6) Aufruf und Test

```bash
curl -I http://mail.docker.lan
```

Dann im Browser öffnen: `http://mail.docker.lan`

Login-Format im Roundcube-Formular:

- Benutzername: `mail@` oder `dev@`
- Passwort: globales Master-Passwort

## Nützliche Kommandos

```bash
# Logs verfolgen
docker-compose logs -f roundcube
docker-compose logs -f roundcube-db

# Neustart
docker-compose restart

# Stoppen
docker-compose down
```

