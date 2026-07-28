# 📋 Dozzle – Echtzeit Container Log Viewer

## Beschreibung

**Dozzle** ist ein leichtgewichtiger, browserbasierter Log-Viewer für Docker-Container.  
Er liest Logs in Echtzeit direkt über den Docker Socket – ohne Speicherung, ohne externe Datenbank.  
Ideal zum schnellen Nachschauen was in einem Container gerade passiert.

## Links

- **Domain**: `http://dozzle.docker.lan`
- **Image**: `amir20/dozzle:latest`
- **Dozzle GitHub**: https://github.com/amir20/dozzle
- **Dozzle Docs**: https://dozzle.dev/

## Features

- ✅ Echtzeit Log-Streaming aller Container
- ✅ Multi-Container-Ansicht (mehrere Logs gleichzeitig)
- ✅ Log-Suche & Filter
- ✅ JSON-Log-Formatierung (strukturierte Logs)
- ✅ Container-Status-Übersicht
- ✅ Eigene Benutzerauthentifizierung (Simple Auth via `data/users.yml`)
- ✅ Keine Datenspeicherung – reine Live-Ansicht

> **Hinweis**: Für persistente Logs mit Suchfunktion → [Loki + Grafana](../logging/README.md)

## Authentifizierung einrichten

Dozzle nutzt eine lokale `data/users.yml` für die Benutzerverwaltung.

### Benutzer generieren

```bash
cd projects/dozzle

# Eintrag generieren (Passwort anpassen!)
docker run --rm amir20/dozzle generate \
--name "Admin" \
--email admin@example.com \
--password DEIN_SICHERES_PASSWORT \
admin
```

Den ausgegebenen YAML-Block in `data/users.yml` einfügen:

```yaml
users:
  admin:
    name: Admin
    email: admin@example.com
    password: "$2a$10$..."  # Hash aus dem generate-Befehl
```

## Setup

```bash
cd projects/dozzle

# 1. Benutzer generieren (siehe oben)

# 2. Dozzle starten
docker-compose up -d

# 3. Logs prüfen
docker-compose logs -f dozzle

# 4. Browser öffnen
# http://dozzle.docker.lan
```

## Konfiguration

| Umgebungsvariable | Wert | Beschreibung |
|-------------------|------|-------------|
| `DOZZLE_AUTH_PROVIDER` | `simple` | Einfache Benutzerauthentifizierung via users.yml |
| `DOZZLE_NO_ANALYTICS` | `true` | Keine anonymen Nutzungsstatistiken senden |
| `TZ` | `Europe/Berlin` | Zeitzone für Log-Timestamps |

## Volumes

| Mount | Pfad | Zweck |
|-------|------|-------|
| `/var/run/docker.sock` | Host Docker Socket (read-only) | Zugriff auf Container & Logs |
| `./data` | `/data` | users.yml für Authentifizierung |

## Logs

```bash
docker-compose logs -f dozzle
```

## Problembehebung

| Problem | Lösung |
|---------|--------|
| Login schlägt fehl | `data/users.yml` prüfen, Passwort neu generieren |
| Keine Container sichtbar | Docker Socket Mount prüfen: `/var/run/docker.sock` |
| Seite nicht erreichbar | Traefik prüfen: `docker ps \| grep traefik` |
| Container startet nicht | Logs: `docker-compose logs dozzle` |


