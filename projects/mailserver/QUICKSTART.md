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

## 4) Stack starten

```bash
docker-compose up -d
docker-compose ps
```

## 5) Aufruf und Test

```bash
curl -I http://mail.docker.lan
```

Dann im Browser öffnen: `http://mail.docker.lan`

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

