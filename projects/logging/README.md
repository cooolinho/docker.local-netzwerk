# 📊 Logging-Stack – Loki + Promtail + Grafana

## Beschreibung

Zentraler Log-Stack für persistente, durchsuchbare Container-Logs:

| Service | Aufgabe |
|---------|---------|
| **Loki** | Log-Aggregation & Storage (30 Tage Retention) |
| **Promtail** | Log-Shipper – liest Docker-Logs & sendet an Loki |
| **Grafana** | Web-UI für Log-Suche, Visualisierung & Dashboards |

## Links

- **Grafana**: `http://grafana.docker.lan`
- **Loki** (intern): `http://loki:3100` (nicht direkt erreichbar)
- **Grafana Image**: `grafana/grafana:latest`
- **Loki Image**: `grafana/loki:3.5.0`
- **Promtail Image**: `grafana/promtail:3.5.0`

## Enthaltene Dashboards

Nach dem Start ist direkt verfügbar:

- 🐳 **Docker Container Logs** – Vorgefertigtes Dashboard mit:
  - Log-Rate pro Container (Zeitreihe)
  - Fehler & Warnungen (Bar Chart)
  - Stat-Panels: Fehleranzahl, Warnungen, Gesamtlogs, aktive Container
  - Fehler-Log Panel (gefiltert auf error/exception/fatal)
  - Vollständiger Log Explorer (mit Freitext-Suche)
  - Filter-Variablen: Compose-Projekt, Container, Stream, Freitext-Suche

## Setup

### 1. `.env` anlegen

```bash
cd projects/logging
cp .env.example .env
nano .env    # GF_SECURITY_ADMIN_PASSWORD setzen!
```

### 2. Stack starten

```bash
cd projects/logging
docker-compose up -d
```

### 3. Start-Reihenfolge beobachten

Loki startet zuerst (Health Check), dann Promtail und Grafana.  
Kann ~60 Sekunden dauern.

```bash
docker-compose logs -f
```

### 4. Grafana öffnen

```
http://grafana.docker.lan
```

Login: `admin` / `DEIN_PASSWORT` (aus `.env`)

### 5. Dashboard öffnen

**Dashboards → Browse → 🐳 Docker Container Logs**

## Konfiguration

### Loki (`config/loki.yml`)

| Parameter | Wert | Beschreibung |
|-----------|------|-------------|
| `retention_period` | `720h` | Log-Retention: 30 Tage |
| `retention_enabled` | `true` | Automatische Bereinigung aktiv |
| `http_listen_port` | `3100` | Loki API Port (intern) |
| `store` | `tsdb` | Index-Format (aktueller Standard) |

### Promtail (`config/promtail.yml`)

| Parameter | Wert | Beschreibung |
|-----------|------|-------------|
| `docker_sd_configs` | `/var/run/docker.sock` | Automatische Container-Erkennung |
| Labels | `container`, `image`, `compose_project`, `compose_service`, `stream` | Übertragene Metadaten |
| Pipeline | JSON-Parsing | Level-Label aus strukturierten Logs |

### Grafana (Umgebungsvariablen)

| Variable | Beschreibung |
|----------|-------------|
| `GF_SECURITY_ADMIN_USER` | Admin-Benutzername (Standard: `admin`) |
| `GF_SECURITY_ADMIN_PASSWORD` | Admin-Passwort (**muss gesetzt werden!**) |
| `GF_AUTH_ANONYMOUS_ENABLED` | `false` – kein anonymer Zugriff |

## Volumes

| Volume | Zweck |
|--------|-------|
| `loki-data` | Log-Chunks & Index (persistente Speicherung) |
| `grafana-data` | Grafana-Einstellungen, Benutzer, weitere Dashboards |
| `promtail-positions` | Leseposition (damit Logs nach Neustart nicht doppelt) |

## Abhängigkeiten

- Promtail: `depends_on: loki` (wartet auf Loki Health Check)
- Grafana: `depends_on: loki` (wartet auf Loki Health Check)

## Logs prüfen

```bash
# Alle Services
docker-compose logs -f

# Einzeln
docker-compose logs -f loki
docker-compose logs -f promtail
docker-compose logs -f grafana
```

## Problembehebung

| Problem | Ursache | Lösung |
|---------|---------|--------|
| Grafana zeigt keine Daten | Promtail noch nicht gestartet | `docker-compose logs promtail` prüfen |
| Loki startet nicht | Volume-Permissions | `docker volume rm logging_loki-data` dann neu starten |
| Fehler: `GF_SECURITY_ADMIN_PASSWORD` nicht gesetzt | `.env` fehlt | `cp .env.example .env` und Passwort setzen |
| Container-Logs fehlen | Promtail hat kein Docker-Socket-Zugriff | `/var/run/docker.sock` Berechtigungen auf Ubuntu prüfen |
| Logs erscheinen nicht in Loki | Retention zu kurz, Query-Bereich zu alt | Zeitbereich in Grafana auf `Last 1h` setzen |

### Promtail Docker Socket Berechtigungen (Ubuntu)

Falls Promtail keinen Zugriff auf den Docker Socket hat:

```bash
# Nutzer zur docker-Gruppe hinzufügen (auf dem Host)
sudo usermod -aG docker $USER

# Oder Socket-Berechtigungen prüfen
ls -la /var/run/docker.sock
```

## Stack stoppen / entfernen

```bash
# Stoppen (Daten bleiben erhalten)
docker-compose down

# Stoppen + Daten löschen (ACHTUNG: alle Logs weg!)
docker-compose down -v
```

