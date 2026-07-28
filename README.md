# 🐳 Docker Local Network mit Traefik Reverse Proxy

Lokale Docker-Umgebung mit Traefik als zentralem Reverse Proxy zur Verwaltung mehrerer Services über Subdomains im lokalen Netzwerk.

## 📋 Inhalt

- [Überblick](#überblick)
- [Architektur](#architektur)
- [Verfügbare Services](#verfügbare-services)
- [Installation & Setup](#installation--setup)
- [DNS-Konfiguration](#dns-konfiguration)
- [Verwendung](#verwendung)
- [Private Projekte per Symlink](#private-projekte-per-symlink)
- [Traefik Dashboard](#traefik-dashboard)
- [Fehlerbehebung](#fehlerbehebung)
- [Sicherheit](#sicherheit)

## 🎯 Überblick

Diese Struktur ermöglicht es dir, mehrere Docker-Container über einen Reverse Proxy (Traefik) zu verwalten. Statt Container mit Ports aufzurufen (z.B. `docker.lan:3000`), erreichst du sie über aussagekräftige Subdomains:

- 🏠 **Dashy (Dashboard)**: `http://dashy.docker.lan`
- 🛠️ **IT-Tools**: `http://it-tools.docker.lan`
- 📋 **Planka (Kanban Board)**: `http://planka.docker.lan`
- 🐋 **Portainer (Docker Management)**: `http://portainer.docker.lan`
- 🔍 **Traefik Dashboard**: `http://traefik.docker.lan`
- 📋 **Dozzle (Echtzeit Log-Viewer)**: `http://dozzle.docker.lan`
- 📊 **Grafana (Log-Suche & Dashboards)**: `http://grafana.docker.lan`
- 📧 **Roundcube (Webmail)**: `http://mail.docker.lan`
- ☁️ **CloudBeaver (DB Web Client)**: `http://cloudbeaver.docker.lan`

## 🏗️ Architektur

```
┌─────────────────────────────────────────────────────────┐
│              Host (192.168.178.1)                       │
│  ┌──────────────────────────────────────────────────┐   │
│  │  Windows Hosts-Datei (.docker.lan DNS)         │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
                         │
                         │ HTTP/HTTPS
                         ▼
┌─────────────────────────────────────────────────────────┐
│      VM / Docker Host (192.168.178.6)                   │
│                                                         │
│  ┌───────────────────────────────────────────────────┐  │
│  │  Docker Network: docker_lan_network             │  │
│  │                                                   │  │
│  │  ┌─────────────────────────────────────────┐      │  │
│  │  │  Traefik (Reverse Proxy)                │      │  │
│  │  │  Port: 80 (HTTP), 8080 (Dashboard)      │      │  │
│  │  └─────────────────────────────────────────┘      │  │
│  │         │        │         │        │             │  │
│  │    ┌────▼─┐  ┌──▼──┐  ┌───▼──┐ ┌──▼────┐          │  │
│  │    │Dashy │  │IT   │  │Planka│ │Private│          │  │
│  │    │3000  │  │Tools│  │3000  │ │Proj.  │          │  │
│  │    │      │  │3000 │  │      │ │3000   │          │  │
│  │    └──────┘  └─────┘  └──────┘ └───────┘          │  │
│  │                                                   │  │
│  └───────────────────────────────────────────────────┘  │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## 📦 Verfügbare Services

| Service | Image | Domain | Port | Beschreibung |
|---------|-------|--------|------|-------------|
| **Dashy** | `lissy93/dashy` | `dashy.docker.lan` | 80 | Personal Dashboard |
| **IT-Tools** | `corentinth/it-tools` | `it-tools.docker.lan` | 80 | IT-Werkzeug-Sammlung |
| **Planka** | `ghcr.io/plankanban/planka` | `planka.docker.lan` | 3000 | Kanban Board |
| **Portainer** | `portainer/portainer-ce` | `portainer.docker.lan` | 9000 | Docker Management UI |
| **Traefik** | `traefik:v2.10` | `traefik.docker.lan` | 80 | Reverse Proxy Dashboard |
| **Dozzle** | `amir20/dozzle` | `dozzle.docker.lan` | 8080 | Echtzeit Container Log-Viewer |
| **Grafana** | `grafana/grafana` | `grafana.docker.lan` | 3000 | Log-Suche & Dashboards (Loki) |
| **Roundcube** | `roundcube/roundcubemail` | `mail.docker.lan` | 80 | Webmail (mit MariaDB im Mailserver-Stack) |
| **CloudBeaver** | `dbeaver/cloudbeaver` | `cloudbeaver.docker.lan` | 8978 | Datenbank-Webclient (JDBC) |

## 🚀 Installation & Setup

### Voraussetzungen

- Docker & Docker Compose auf VM installiert
- Netzwerkverbindung zwischen Host und VM
- Windows Host (für AdGuard Home DNS-Konfiguration)

### 1. Repository klonen/einrichten

```bash
cd D:\Projekte\docker.lan-netzwerk
```

### 2. Umgebungsvariablen konfigurieren

Die `.env` Datei ist bereits vorkonfiguriert. Passe folgende Werte an falls nötig:

```env
DOMAIN=docker.lan                           # Domain-Endung
DOCKER_HOST=192.168.178.6                     # IP der VM
TRAEFIK_DASHBOARD_USER=admin                  # Dashboard Benutzername
TRAEFIK_DASHBOARD_PASSWORD=admin              # Dashboard Passwort
TRAEFIK_API_MONITOR_USER=monitor-api          # Read-only API Benutzername
TRAEFIK_API_MONITOR_PASSWORD=monitor-readonly # Read-only API Passwort
```

### 3. DNS-Konfiguration (AdGuard Home)

DNS wird über **AdGuard Home** (192.168.178.3) mit Wildcard-Einträgen verwaltet.
Ein einziger Eintrag macht alle Subdomains automatisch verfügbar:

| Domain | IP | Zweck |
|--------|-----|-------|
| `*.docker.lan` | `192.168.178.6` | Alle Subdomains (Wildcard) |
| `docker.lan` | `192.168.178.6` | Root-Domain |

**Einrichten in AdGuard Home:**
1. Öffne `http://192.168.178.3`
2. Navigiere zu **Einstellungen** → **DNS-Einstellungen** → **DNS-Rewrites**
3. Füge `*.docker.lan` → `192.168.178.6` hinzu
4. Füge `docker.lan` → `192.168.178.6` hinzu

➡️ Detaillierte Anleitung: [DNS_SETUP.md](./DNS_SETUP.md)

### 4. Externes Netzwerk erstellen (auf Docker Host)

```bash
# SSH auf VM oder direkt auf Docker Host
docker network create docker_lan_network --driver bridge
```

### 5. Traefik starten

```bash
# Vom root-Verzeichnis des Projekts
docker-compose up -d
```

Überprüfe den Status:

```bash
docker-compose ps
docker-compose logs -f traefik
```

### 6. Projekte starten

```bash
# Dashy
cd projects/dashy
docker-compose up -d

# IT-Tools
cd ../it-tools
docker-compose up -d

# Planka
cd ../planka
docker-compose up -d

# Dozzle (Echtzeit Log-Viewer)
cd ../dozzle
cp .env.example .env
# Benutzer generieren (siehe projects/dozzle/README.md)
docker-compose up -d

# Logging-Stack (Loki + Promtail + Grafana)
cd ../logging
cp .env.example .env
nano .env    # GF_SECURITY_ADMIN_PASSWORD setzen!
docker-compose up -d

# Mailserver (Roundcube)
cd ../mailserver
cp .env.example .env
# .env anpassen (IMAP/SMTP Host + DB Variablen)
docker-compose up -d

# CloudBeaver (DB Web Client)
cd ../cloudbeaver
docker-compose up -d

# ... usw.
```

## 🌐 DNS-Konfiguration

### AdGuard Home (empfohlen — Wildcard DNS)

DNS wird zentral über **AdGuard Home** (192.168.178.3) verwaltet.

**Einrichten:**
1. Öffne `http://192.168.178.3`
2. **Einstellungen** → **DNS-Einstellungen** → **DNS-Rewrites**
3. Eintrag 1: `*.docker.lan` → `192.168.178.6`
4. Eintrag 2: `docker.lan` → `192.168.178.6`

**Vorteil**: Wildcard-Eintrag — neue Projekte sind sofort erreichbar, kein manuelles DNS-Update!

Detaillierte Anleitung: [DNS_SETUP.md](./DNS_SETUP.md)

### Fallback: Windows Hosts-Datei

Falls AdGuard Home nicht verfügbar ist:

```hosts
192.168.178.6  docker.lan
192.168.178.6  dashy.docker.lan
192.168.178.6  it-tools.docker.lan
192.168.178.6  planka.docker.lan
192.168.178.6  portainer.docker.lan
192.168.178.6  traefik.docker.lan
192.168.178.6  dozzle.docker.lan
192.168.178.6  grafana.docker.lan
192.168.178.6  mail.docker.lan
192.168.178.6  cloudbeaver.docker.lan
```

> ⚠️ Hosts-Datei hat keinen Wildcard-Support — neue Projekte müssen manuell eingetragen werden.

## 🔧 Verwendung

### Neues Projekt hinzufügen

1. **Verzeichnis erstellen**:
   ```bash
   mkdir -p projects/mein-neues-projekt
   cd projects/mein-neues-projekt
   ```

2. **docker-compose.yml erstellen** (basierend auf Template):
   ```yaml
   version: '3.8'
   services:
     mein-service:
       image: mein-image:latest
       container_name: mein-service
       restart: unless-stopped
       networks:
         - docker_lan_network
       labels:
         - "traefik.enable=true"
         - "traefik.http.routers.mein-projekt.rule=Host(`mein-projekt.docker.lan`)"
         - "traefik.http.routers.mein-projekt.entrypoints=web"
         - "traefik.http.services.mein-projekt.loadbalancer.server.port=3000"

   networks:
     docker_lan_network:
       external: true
   ```

3. **Starten**:
   ```bash
   docker-compose up -d
   ```

4. **DNS aktualisieren** — dank AdGuard Home Wildcard **nicht nötig**! Neues Projekt ist sofort unter `http://mein-projekt.docker.lan` erreichbar.

### Container verwalten

```bash
# Alle Container anzeigen
docker ps -a

# Logs eines Services anzeigen
docker-compose -f projects/dashy/docker-compose.yml logs -f

# Container neustarten
docker-compose -f projects/dashy/docker-compose.yml restart

# Container stoppen/starten
docker-compose -f projects/dashy/docker-compose.yml down
docker-compose -f projects/dashy/docker-compose.yml up -d
```

## 🔗 Private Projekte per Symlink

Der Ordner `projects/private` ist als Sammelpunkt fuer private, separat versionierte Projekte gedacht.
Nutze dafuer das interaktive Skript `scripts/create-private-symlink.sh`.

### Was das Skript macht

- Erstellt Symlinks in `projects/private` auf externe Projektordner
- Fragt interaktiv nach Symlink-Typ (`absolut` oder `relativ`), Quellpfad und Link-Name
- Kann bestehende Ziele auf Wunsch ersetzen
- Kann bestehende Symlinks in `projects/private` auflisten und gezielt loeschen

### Bedienung

```bash
# aus dem Repo-Root
bash scripts/create-private-symlink.sh
```

Im Menue waehlen:
1. `Symlink erstellen`
2. `Symlink loeschen` (zeigt alle vorhandenen Symlinks im Ordner zur Auswahl)

### Optional: Zielordner ueberschreiben

Standard ist `<repo>/projects/private`. Auf dem Server kannst du den Zielordner explizit setzen:

```bash
bash scripts/create-private-symlink.sh --private-dir /home/cooolinho/docker.local-netzwerk/projects/private

# alternativ per Umgebungsvariable
PRIVATE_PROJECTS_DIR=/home/cooolinho/docker.local-netzwerk/projects/private bash scripts/create-private-symlink.sh
```

Beispiel fuer den Projekt-Quellpfad waehrend der interaktiven Abfrage:
`/home/cooolinho/projects/laravel-my-media-library`

## 📊 Traefik Dashboard

**URL**: `http://traefik.docker.lan`

**Anmeldedaten**:
- Benutzername: `admin`
- Passwort: `admin`

Hier siehst du:
- ✅ Alle Router (Subdomains)
- ✅ Alle Services (Container)
- ✅ Health Status
- ✅ Request-Statistiken
- ✅ Fehlerlog

### Read-only API fuer Monitoring

- **API-Basis**: `http://traefik.docker.lan/api`
- **Scope**: Nur `GET /api/http/services/*` (read-only)
- **Credentials**: `TRAEFIK_API_MONITOR_USER` / `TRAEFIK_API_MONITOR_PASSWORD`

Beispiele fuer feste Service-IDs:

```bash
curl -u monitor-api:monitor-readonly http://traefik.docker.lan/api/http/services/dashy@docker
curl -u monitor-api:monitor-readonly http://traefik.docker.lan/api/http/services/it-tools@docker
curl -u monitor-api:monitor-readonly http://traefik.docker.lan/api/http/services/planka@docker
curl -u monitor-api:monitor-readonly http://traefik.docker.lan/api/http/services/portainer@docker
curl -u monitor-api:monitor-readonly http://traefik.docker.lan/api/http/services/roundcube@docker
```

## ⚙️ Konfiguration

### Traefik Logging

Passe das Log-Level in `.env` an:

```env
TRAEFIK_LOG_LEVEL=DEBUG    # DEBUG, INFO (default), WARN, ERROR
```

### SSL/TLS (für Zukunft)

Die `.env` ist vorbereitet für Let's Encrypt:

```env
SSL_ENABLED=true
LETSENCRYPT_EMAIL=deine-email@example.com
```

Aktiviere SSL in `traefik/traefik.yml` für Production.

### Middleware (z.B. Authentication)

Beispiel Basic Auth in `traefik/config/dynamic.yml`:

```yaml
middlewares:
  basic-auth:
    basicAuth:
      users:
        - "admin:$apr1$r31.....$HqJZimcKQFAMYayBlzkrq/"
```

Nutze in Labels:

```yaml
- "traefik.http.routers.dashy.middlewares=basic-auth"
```

## 🐛 Fehlerbehebung

### "Verbindung verweigert" / Seite nicht erreichbar

1. **Traefik läuft nicht**:
   ```bash
   docker ps | grep traefik
   docker-compose logs traefik
   ```

2. **Netzwerk nicht existiert**:
   ```bash
   docker network ls
   docker network create docker_lan_network
   ```

3. **Service läuft nicht**:
   ```bash
   docker-compose -f projects/dashy/docker-compose.yml logs
   ```

### DNS-Fehler

1. **AdGuard Home DNS-Rewrite korrekt?**
   - Öffne `http://192.168.178.3` → DNS-Rewrites prüfen
   - `*.docker.lan` → `192.168.178.6` vorhanden?
2. **Richtigen DNS-Server nutzen?**
   ```powershell
   nslookup dashy.docker.lan 192.168.178.3
   ```
3. **DNS Cache leeren** (Windows):
   ```powershell
   ipconfig /flushdns
   ```

### Traefik erkennt Container nicht

1. **Überprüfe Labels in docker-compose.yml**:
   - `traefik.enable=true`?
   - Hostname in Rule korrekt?

2. **Netzwerk korrekt?**:
   ```bash
   docker inspect container-name | grep Networks
   ```

3. **Traefik neustarten**:
   ```bash
   docker-compose restart traefik
   ```

### Port-Konflikte

Wenn Port 80 schon belegt:

```yaml
ports:
  - "8000:80"  # Extern 8000 → Intern 80
  - "8443:443"
```

## 🔐 Sicherheit

⚠️ **Diese Konfiguration ist für lokales Netzwerk gedacht!**

Für Production:

1. **Starke Passwörter** (Traefik Dashboard)
2. **SSL/TLS mit Let's Encrypt** aktivieren
3. **Firewall Rules** auf VM
4. **Container Security Updates** regelmäßig
5. **Secrets Management** (statt hardcodiert in .env)
6. **Rate Limiting** in Traefik
7. **IP-Whitelisting** für sensible Projekte

## 📚 Weitere Ressourcen

- [Traefik Dokumentation](https://doc.traefik.io/)
- [Docker Compose Dokumentation](https://docs.docker.com/compose/)
- [Docker Networking](https://docs.docker.com/network/)

## 👨‍💼 Support & Verwaltung

Siehe `AGENTS.md` für Rollen und Verantwortlichkeiten.

---

**Zuletzt aktualisiert**: 2026-07-28  
**Traefik Version**: v2.10  
**Docker Compose Version**: 3.8  
**Logging-Stack**: Loki 3.5 + Promtail 3.5 + Grafana latest

