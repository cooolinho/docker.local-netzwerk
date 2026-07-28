# ☁️ CloudBeaver - Database Web Client

CloudBeaver ist eine browserbasierte Datenbank-UI. In diesem Setup laeuft sie hinter Traefik und greift ueber das interne Docker-Netz direkt auf lokale DB-Container zu.

## Links

- **Domain**: `http://cloudbeaver.docker.lan`
- **Image**: `dbeaver/cloudbeaver:latest`
- **CloudBeaver Docs**: https://dbeaver.com/docs/cloudbeaver/

## Enthaltener Service

- `cloudbeaver` - Web UI fuer Datenbankverbindungen

## Start

```bash
cd projects/cloudbeaver
docker-compose up -d
docker-compose logs -f cloudbeaver
```

## Zugriff und BasicAuth

CloudBeaver ist zusaetzlich durch Traefik BasicAuth geschuetzt.

- **Initialer Benutzer**: `cloudadmin`
- **Initiales Passwort**: `CHANGE_ME`

Wichtig: Bitte das Passwort direkt nach dem Setup ersetzen (Hash in `projects/cloudbeaver/docker-compose.yml`, Label `cloudbeaver-auth`).

## JDBC-Verbindungen zu lokalen Datenbank-Containern

Alle Container im `docker_lan_network` sind per Containername erreichbar.

### 1) Planka PostgreSQL (`planka-db`)

- **Host**: `planka-db`
- **Port**: `5432`
- **Database**: `planka`
- **User**: `planka`
- **Passwort**: `planka-password-change-me` (aus `projects/planka/docker-compose.yml`)

JDBC URL:

```text
jdbc:postgresql://planka-db:5432/planka
```

### 2) Roundcube MariaDB (`roundcube-db`)

- **Host**: `roundcube-db`
- **Port**: `3306`
- **Database**: aus `ROUNDCUBEMAIL_DB_NAME` in `projects/mailserver/.env`
- **User**: aus `ROUNDCUBEMAIL_DB_USER` in `projects/mailserver/.env`
- **Passwort**: aus `ROUNDCUBEMAIL_DB_PASSWORD` in `projects/mailserver/.env`

JDBC URL:

```text
jdbc:mariadb://roundcube-db:3306/<ROUNDCUBEMAIL_DB_NAME>
```

Alternative JDBC URL (MySQL-Driver):

```text
jdbc:mysql://roundcube-db:3306/<ROUNDCUBEMAIL_DB_NAME>
```

## Persistenz

| Volume | Zweck |
|--------|-------|
| `cloudbeaver-workspace` | CloudBeaver Workspace, Verbindungen, Einstellungen |

## Troubleshooting

- **CloudBeaver nicht erreichbar**: `docker-compose ps` und Traefik-Status pruefen.
- **BasicAuth Login scheitert**: Benutzer/Passwort pruefen oder Hash im Compose-Label aktualisieren.
- **DB nicht erreichbar**: Ziel-Container laeuft? (`docker ps | grep -E "planka-db|roundcube-db"`)
- **Verbindungsfehler per JDBC**: Treiber in CloudBeaver korrekt auswaehlen (PostgreSQL bzw. MariaDB/MySQL).

