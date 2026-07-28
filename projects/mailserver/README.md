# 📧 Mailserver (Roundcube)

Roundcube stellt ein webbasiertes E-Mail-Frontend bereit und läuft hier zusammen mit einer MariaDB als Compose-Stack.

## 🔗 Links

- **Domain**: `http://mail.docker.lan`
- **Image (Webmail)**: `roundcube/roundcubemail:latest`
- **Image (DB)**: `mariadb:latest`
- **Roundcube Doku**: https://github.com/roundcube/roundcubemail

## 🧱 Enthaltene Services

- `roundcube` - Webmail UI hinter Traefik
- `roundcube-db` - MariaDB für Roundcube-Daten

## ⚙️ Konfiguration

Die Variablen liegen in `projects/mailserver/.env` (aus `projects/mailserver/.env.example` erzeugen).

Wichtige Variablen:

| Variable | Beispiel | Beschreibung |
|----------|----------|-------------|
| `ROUNDCUBEMAIL_DEFAULT_HOST` | `mail.example.lan` | IMAP Host für Login |
| `ROUNDCUBEMAIL_SMTP_SERVER` | `mail.example.lan` | SMTP Host |
| `ROUNDCUBEMAIL_SMTP_PORT` | `587` | SMTP Port |
| `ROUNDCUBEMAIL_IMAP_PORT` | `143` | IMAP Port |
| `ROUNDCUBEMAIL_DB_HOST` | `roundcube-db` | DB Hostname im Compose-Netz |
| `ROUNDCUBEMAIL_DB_USER` | `roundcube` | DB User |
| `ROUNDCUBEMAIL_DB_PASSWORD` | `change-me` | DB Passwort |
| `ROUNDCUBEMAIL_DB_ROOT_PASSWORD` | `change-me` | MariaDB Root Passwort |
| `ROUNDCUBEMAIL_DB_NAME` | `roundcube` | Datenbankname |

## 🚀 Start

```bash
cd projects/mailserver
cp .env.example .env
# .env anpassen

docker-compose up -d
docker-compose ps
```

## 🧪 Funktionstest

```bash
curl -I http://mail.docker.lan
```

Erwartet: HTTP-Antwort von Traefik/Roundcube (z. B. `200` oder `302`).

## 📦 Persistenz

| Volume | Zweck |
|--------|-------|
| `roundcube_data` | Roundcube Dateien und Daten |
| `roundcube_db_data` | MariaDB Daten |

## 🛠️ Logs

```bash
docker-compose logs -f roundcube
docker-compose logs -f roundcube-db
```

## 🐛 Troubleshooting

- **Seite nicht erreichbar**: `docker-compose ps` und Traefik-Status prüfen.
- **DB-Verbindung schlägt fehl**: `ROUNDCUBEMAIL_DB_HOST` auf `roundcube-db` setzen.
- **Login auf Mailserver klappt nicht**: IMAP/SMTP Host und Ports in `.env` prüfen.

