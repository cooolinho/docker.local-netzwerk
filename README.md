# 🐳 Docker Local Network mit Traefik Reverse Proxy

Lokale Docker-Umgebung mit Traefik als zentralem Reverse Proxy zur Verwaltung mehrerer Services über Subdomains im lokalen Netzwerk.

## 📋 Inhalt

- [Überblick](#überblick)
- [Architektur](#architektur)
- [Verfügbare Services](#verfügbare-services)
- [Installation & Setup](#installation--setup)
- [DNS-Konfiguration](#dns-konfiguration)
- [Verwendung](#verwendung)
- [Traefik Dashboard](#traefik-dashboard)
- [Fehlerbehebung](#fehlerbehebung)
- [Sicherheit](#sicherheit)

## 🎯 Überblick

Diese Struktur ermöglicht es dir, mehrere Docker-Container über einen Reverse Proxy (Traefik) zu verwalten. Statt Container mit Ports aufzurufen (z.B. `docker.lan:3000`), erreichst du sie über aussagekräftige Subdomains:

- 🏠 **Dashy (Dashboard)**: `http://dashy.docker.lan`
- 🛠️ **IT-Tools**: `http://it-tools.docker.lan`
- 📋 **Planka (Kanban Board)**: `http://planka.docker.lan`
- 🐋 **Portainer (Docker Management)**: `http://portainer.docker.lan`
- 🔧 **Private Projekte**: `http://private-project-1.docker.lan` usw.
- 🔍 **Traefik Dashboard**: `http://traefik.docker.lan:8080`

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
| **Private Projekt 1-3** | Custom | `private-project-*.docker.lan` | Custom | Deine Projekte |
| **Traefik** | `traefik:v2.10` | `traefik.docker.lan:8080` | 8080 | Reverse Proxy Dashboard |

## 🚀 Installation & Setup

### Voraussetzungen

- Docker & Docker Compose auf VM installiert
- Netzwerkverbindung zwischen Host und VM
- Windows Host (für Hosts-Datei-Konfiguration)

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
```

### 3. DNS-Konfiguration (Windows Host)

Bearbeite `C:\Windows\System32\drivers\etc\hosts` als Administrator:

```hosts
# Docker Local Network
192.168.178.6  docker.lan
192.168.178.6  dashy.docker.lan
192.168.178.6  it-tools.docker.lan
192.168.178.6  planka.docker.lan
192.168.178.6  portainer.docker.lan
192.168.178.6  private-project-1.docker.lan
192.168.178.6  private-project-2.docker.lan
192.168.178.6  private-project-3.docker.lan
192.168.178.6  traefik.docker.lan
```

**Oder nutze einen lokalen DNS-Server** (z.B. auf deinem Docker Host) mit Wildcard-Einträgen:

```dns
*.docker.lan  A  192.168.178.6
docker.lan    A  192.168.178.6
```

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

# Deine privaten Projekte
cd ../private-project-1
docker-compose up -d
# ... usw.
```

## 🌐 DNS-Konfiguration

### Option 1: Windows Hosts-Datei (einfach, manuell)

1. Öffne Editor als Administrator
2. Öffne: `C:\Windows\System32\drivers\etc\hosts`
3. Füge die Einträge am Ende hinzu (siehe oben)
4. Speichern

**Vorteil**: Einfach  
**Nachteil**: Manuelle Verwaltung bei neuen Projekten

### Option 2: Lokaler DNS-Server (advanced, dynamisch)

Nutze ein Tool wie:
- **dnsmasq** (Linux)
- **CoreDNS** (Docker Container)
- **Unbound** (alle Plattformen)

Beispiel mit dnsmasq in Docker:

```yaml
dns-server:
  image: jpillora/dnsmasq:latest
  ports:
    - "53:53/udp"
  volumes:
    - ./dnsmasq.conf:/etc/dnsmasq.conf
  networks:
    - docker_lan_network
```

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

4. **DNS aktualisieren** (Hosts-Datei):
   ```hosts
   192.168.178.6  mein-projekt.docker.lan
   ```

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

## 📊 Traefik Dashboard

**URL**: `http://traefik.docker.lan:8080`

**Anmeldedaten**:
- Benutzername: `admin`
- Passwort: `admin`

Hier siehst du:
- ✅ Alle Router (Subdomains)
- ✅ Alle Services (Container)
- ✅ Health Status
- ✅ Request-Statistiken
- ✅ Fehlerlog

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

1. **Hosts-Datei nicht aktualisiert**:
   - Admin-Rechte?
   - Richtige IP-Adresse?
   - nslookup Test: `nslookup dashy.docker.lan`

2. **DNS Cache leeren** (Windows):
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

**Zuletzt aktualisiert**: 2024-07-26  
**Traefik Version**: v2.10  
**Docker Compose Version**: 3.8

