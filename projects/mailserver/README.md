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

Dieser Stack nutzt zusaetzlich **Alias-Only-Login** ueber ein Roundcube-Plugin:

- Loginname in Roundcube nur als `alias@` (z. B. `mail@`, `dev@`)
- Domain wird intern fest auf `@cooolinho.de` gesetzt
- Ein globales Master-Passwort gilt fuer alle Alias-Logins
- Alias wird nur gegen eine lokale zentrale Alias-Datei auf Existenz geprueft
- Bei Erfolg nutzt Roundcube intern die echten Hetzner-Mailbox-Zugangsdaten
- Es gibt **keinen Fallback** auf normalen Login mit voller Mailadresse

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

### Zentrale Alias-Accounts Datei

Die zentrale Zuordnung liegt lokal in:

- `projects/mailserver/secrets/alias-accounts.php` (nicht in Git)
- `projects/mailserver/secrets/alias-master-password.txt` (nicht in Git)

Template:

- `projects/mailserver/secrets/alias-accounts.example.php`
- `projects/mailserver/secrets/alias-master-password.example.txt`

Beispiel:

```php
<?php

return [
	'mail@cooolinho.de' => [
		'mailbox_user' => 'mail@cooolinho.de',
		'mailbox_password' => 'DEIN_ECHTES_HETZNER_PASSWORT',
	],
	'dev@cooolinho.de' => [
		'mailbox_user' => 'dev@cooolinho.de',
		'mailbox_password' => 'DEIN_ECHTES_HETZNER_PASSWORT',
	],
];
```

## 🚀 Start

```bash
cd projects/mailserver
cp .env.example .env
# .env anpassen
cp secrets/alias-accounts.example.php secrets/alias-accounts.php
cp secrets/alias-master-password.example.txt secrets/alias-master-password.txt
# secrets/alias-accounts.php mit echten Mailbox-Passwoertern pflegen
# secrets/alias-master-password.txt auf ein starkes Master-Passwort setzen

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
- **Alias-Login scheitert sofort**: `secrets/alias-accounts.php` vorhanden und Format pruefen.
- **Alias-Login scheitert sofort**: `secrets/alias-master-password.txt` vorhanden und nicht leer.
- **Alias wird nicht akzeptiert**: Nur `alias@` ist gueltig, z. B. `mail@` statt `mail@cooolinho.de`.

