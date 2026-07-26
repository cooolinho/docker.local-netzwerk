# 👥 AGENTS.md - Rollen & Verantwortlichkeiten

Dieses Dokument definiert die Rollen und Verantwortlichkeiten für die Verwaltung und Wartung der Docker Local Network Infrastruktur.

## 📋 Übersicht der Rollen

| Agent | Verantwortung | Skills | Schwerpunkt |
|-------|---------------|--------|------------|
| **Infrastructure Agent** | Traefik, Netzwerk, DNS | DevOps, Docker, Netzwerk | Zentraler Reverse Proxy |
| **Project Manager** | Projekte deployen, starten/stoppen | Docker Compose, YAML | Projekt-Lifecycle |
| **Security Agent** | SSL/TLS, Authentifizierung, Backups | Sicherheit, Compliance | Datenschutz & Zugriff |
| **Monitoring Agent** | Logs, Metriken, Alerting | Observability, Debugging | Fehleranalyse |
| **Dokumentation Agent** | README, Wikis, Changelogs | Technical Writing | Wissensmanagement |

---

## 🏗️ Infrastructure Agent

**Zweck**: Verwaltung der zentralen Traefik-Infrastruktur und des Docker-Netzwerks

### Verantwortungen

- ✅ Traefik Container Lifecycle (Start/Stop/Update)
- ✅ Netzwerk-Konfiguration (`docker-local-network`)
- ✅ DNS-Einstellungen (Hosts-Datei oder DNS-Server)
- ✅ Reverse Proxy Routing & Load Balancing
- ✅ SSL/TLS Certificate Management
- ✅ Traefik-Konfigurationsupdates
- ✅ Disaster Recovery & Backups

### Checklisten

#### 📌 Initiales Setup

```bash
# 1. Netzwerk erstellen
docker network create docker-local-network --driver bridge

# 2. Traefik starten
cd /path/to/docker.local-netzwerk
docker-compose up -d traefik

# 3. Traefik Status prüfen
docker ps | grep traefik
docker-compose logs traefik

# 4. Dashboard verfügbar?
curl http://traefik.docker.local:8080/dashboard/
```

#### 📊 Regelmäßige Aufgaben (täglich/wöchentlich)

```bash
# Logs prüfen
docker-compose logs --tail 100 traefik

# Netzwerk-Gesundheit prüfen
docker network inspect docker-local-network

# Router & Services Status
curl http://traefik.docker.local:8080/api/http/routers
curl http://traefik.docker.local:8080/api/http/services
```

#### 🔄 Updates & Wartung

```bash
# Traefik aktualisieren (mit Backup)
docker-compose pull traefik
docker-compose down traefik
docker-compose up -d traefik

# Netzwerk-Bereinigung
docker network prune
```

### Konfigurationsdateien

- `docker-compose.yml` - Traefik-Container Definition
- `traefik/traefik.yml` - Statische Traefik-Konfiguration
- `traefik/config/dynamic.yml` - Dynamische Konfiguration (Middleware, TLS)
- `.env` - Umgebungsvariablen

---

## 🚀 Project Manager

**Zweck**: Deployment und Lifecycle-Management der Anwendungsprojekte

### Verantwortungen

- ✅ Neue Projekte als Docker Services hinzufügen
- ✅ Projekt docker-compose Dateien erstellen/aktualisieren
- ✅ Services starten/stoppen/neustarten
- ✅ Abhängigkeiten zwischen Services managen (z.B. DB für Planka)
- ✅ Volume & Datei-Persistenz konfigurieren
- ✅ Service-Health überwachen
- ✅ Container Image Updates durchführen

### Checklisten

#### 📌 Neues Projekt deployen

```bash
# 1. Verzeichnis erstellen
mkdir -p projects/mein-neues-projekt
cd projects/mein-neues-projekt

# 2. docker-compose.yml von Template kopieren & anpassen
# - Image korrekt?
# - Port korrekt?
# - Labels mit Subdomain?
# - Netzwerk: docker-local-network?

# 3. Abhängigkeiten checken
# - Datenbaken? (separate Services)
# - Config-Files?
# - Volumes?

# 4. Starten & testen
docker-compose up -d
docker-compose logs -f

# 5. Von Host testen
curl http://mein-projekt.docker.local

# 6. In Dokumentation eintragen
# - README.md aktualisieren
# - Hosts-Datei aktualisieren (falls nötig)
```

#### 📋 Projekt-Struktur Template

```
projects/mein-projekt/
├── docker-compose.yml          # Service Definition
├── .env.project                # Projekt-spezifische Vars
├── config/                     # Konfigurationsdateien
│   └── app.conf
├── data/                       # Persistente Daten (Volume-Mount)
├── README.md                   # Projekt-Dokumentation
└── DEPLOY.md                   # Deployment-Anleitung
```

#### 🔄 Projekt aktualisieren

```bash
# 1. Image-Version prüfen
docker-compose config | grep image

# 2. Neues Image pullen
docker-compose pull

# 3. Backup erstellen (wenn Daten wichtig)
docker-compose exec service-name sh -c "tar czf /backup/backup.tar.gz /app/data"

# 4. Neu starten
docker-compose down
docker-compose up -d

# 5. Logs prüfen
docker-compose logs -f service-name
```

### Projektmuster

- `projects/dashy/docker-compose.yml`
- `projects/it-tools/docker-compose.yml`
- `projects/planka/docker-compose.yml`
- `projects/private-project-1/docker-compose.yml`
- `projects/private-project-2/docker-compose.yml`
- `projects/private-project-3/docker-compose.yml`

---

## 🔐 Security Agent

**Zweck**: Sicherheit, Authentifizierung, Verschlüsselung und Datenschutz

### Verantwortungen

- ✅ SSL/TLS Certificates verwalten
- ✅ Traefik BasicAuth / OAuth2 Middleware konfigurieren
- ✅ Secrets & Passwörter (nicht in Git!)
- ✅ Netzwerk-Isolation & Firewall Rules
- ✅ Container Security Updates
- ✅ Backup-Strategie implementieren
- ✅ Vulnerability Scanning
- ✅ Access Control & IP-Whitelisting

### Checklisten

#### 🔒 Sicherheits-Audit

```bash
# 1. Container-Images scannen auf Vulnerabilities
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image lissy93/dashy:latest

# 2. Laufende Container inspizieren
docker ps
docker inspect container-name

# 3. Netzwerk-Isolation prüfen
docker network inspect docker-local-network

# 4. Passwörter & Secrets prüfen
grep -r "password\|secret\|token" projects/
```

#### 🔑 Passwort-Management

**WICHTIG**: Keine Passwörter in Git!

`.env` sollte **nicht** in Git committed werden:

```bash
# .gitignore
.env
.env.local
secrets/
```

Stattdessen nutzen:

```bash
# .env.example (Template ohne Secrets)
TRAEFIK_DASHBOARD_PASSWORD=CHANGE_ME
DB_PASSWORD=CHANGE_ME

# Lokal: .env (ignoriert von Git)
TRAEFIK_DASHBOARD_PASSWORD=mein-sicheres-passwort
DB_PASSWORD=db-passwort-123
```

#### 🛡️ SSL/TLS Aktivieren (Production)

```yaml
# traefik/traefik.yml

entryPoints:
  web:
    address: ":80"
    http:
      redirections:
        entrypoint:
          to: websecure
          scheme: https

  websecure:
    address: ":443"
    tls:
      certResolver: letsencrypt

certificateResolvers:
  letsencrypt:
    acme:
      email: your-email@example.com
      storage: /acme.json
      httpChallenge:
        entryPoint: web
```

#### 🔐 BasicAuth hinzufügen

```bash
# Apache2 Utils installieren (am Host)
# apt-get install apache2-utils

# Passwort hashen
htpasswd -c auth.txt admin

# In traefik/config/dynamic.yml:
middlewares:
  auth:
    basicAuth:
      usersFile: /config/auth.txt

# In docker-compose Labels:
- "traefik.http.routers.dashy.middlewares=auth"
```

#### 📦 Backup-Strategie

```bash
# Tägliches Backup aller Projekt-Daten
#!/bin/bash
BACKUP_DIR="/backups/docker-local-network"
DATE=$(date +%Y%m%d_%H%M%S)

# Docker Volumes sichern
docker run --rm \
  -v docker-local_data:/data \
  -v "$BACKUP_DIR":/backup \
  alpine tar czf /backup/volumes_$DATE.tar.gz /data

# Konfigurationen sichern
tar czf "$BACKUP_DIR/config_$DATE.tar.gz" \
  traefik/ projects/ .env

# Alte Backups löschen (älter als 30 Tage)
find "$BACKUP_DIR" -type f -mtime +30 -delete
```

---

## 📊 Monitoring Agent

**Zweck**: Überwachung, Logging und Fehlerbehebung

### Verantwortungen

- ✅ Container Logs analysieren
- ✅ Performance Metriken überwachen
- ✅ Health Checks implementieren
- ✅ Alert-Systeme konfigurieren
- ✅ Fehler diagnostizieren & fixen
- ✅ Request-Tracing
- ✅ Capacity Planning

### Checklisten

#### 📋 Tägliche Überwachung

```bash
# 1. Alle Container Status
docker ps
docker ps -a  # auch gestoppte

# 2. Traefik Logs prüfen
docker-compose logs --tail 50 traefik

# 3. Fehler-Services prüfen
for dir in projects/*/; do
  echo "=== $(basename $dir) ==="
  docker-compose -f "$dir/docker-compose.yml" logs --tail 10
done

# 4. Netzwerk-Probleme?
docker network inspect docker-local-network
```

#### 🐛 Debugging: Service antwortet nicht

```bash
# 1. Läuft der Container?
docker ps | grep service-name

# 2. Container-Status
docker inspect service-name

# 3. Logs ansehen
docker logs -f service-name

# 4. In Container gehen
docker exec -it service-name sh

# 5. Von innerhalb des Containers Traefik pingen?
docker exec -it service-name curl -i http://traefik:8080/api/version

# 6. Port korrekt?
docker port service-name
```

#### 📈 Monitoring Setup (advanced)

Traefik mit Prometheus & Grafana:

```yaml
# traefik/traefik.yml
metrics:
  prometheus:
    addEntryPointsLabels: true
    addServicesLabels: true
    entryPoint: metrics

# docker-compose.yml
prometheus:
  image: prom/prometheus:latest
  volumes:
    - ./monitoring/prometheus.yml:/etc/prometheus/prometheus.yml
  ports:
    - "9090:9090"
  networks:
    - docker-local-network

grafana:
  image: grafana/grafana:latest
  ports:
    - "3000:3000"
  networks:
    - docker-local-network
```

---

## 📚 Documentation Agent

**Zweck**: Dokumentation, Wikis und Wissensmanagement

### Verantwortungen

- ✅ README.md aktualisieren
- ✅ Projekt-Dokumentation schreiben
- ✅ Deployment-Guides erstellen
- ✅ Troubleshooting-Docs führen
- ✅ Changelog & Release Notes
- ✅ Diagramme & Visualisierungen
- ✅ AGENTS.md & Rollen-Docs

### Template für neue Projekte

```markdown
# Project: [Name]

## Beschreibung
Kurze Beschreibung der Anwendung

## Links
- **Domain**: `http://[name].docker.local`
- **Image**: `image-registry/image:tag`
- **GitHub**: [URL]

## Umgebungsvariablen
| Variable | Beispiel | Beschreibung |
|----------|----------|-------------|
| DB_HOST | planka-db | Datenbankhost |

## Volumes
| Mount | Pfad | Zweck |
|-------|------|-------|
| data | /app/data | Persistente Daten |

## Abhängigkeiten
- PostgreSQL (wenn DB nötig)
- [andere Services]

## Setup
```bash
cd projects/[name]
docker-compose up -d
```

## Logs
```bash
docker-compose logs -f [service-name]
```

## Problembehebung
- Fehler X: Lösungsansatz
```

### Checkliste: Neue Dokumentation

- [ ] Projekt in README.md hinzufügt?
- [ ] Hosts-Datei aktualisiert?
- [ ] Projekt-README vorhanden?
- [ ] Diagramme/Screenshots?
- [ ] Links gültig?
- [ ] Spellings & Grammatik?

---

## 📅 Aufgaben nach Zeitrahmen

### ⏰ Täglich
- Monitoring Agent: Container & Traefik Logs prüfen
- Project Manager: Health Checks durchführen

### 📆 Wöchentlich
- Infrastructure Agent: Traefik Logs analysieren
- Security Agent: Update-Verfügbarkeit prüfen
- Documentation Agent: Änderungen dokumentieren

### 🗓️ Monatlich
- Security Agent: Sicherheits-Audit durchführen
- Infrastructure Agent: Backups verifizieren
- Project Manager: Image-Updates durchführen
- Monitoring Agent: Performance-Report erstellen

### 📅 Vierteljährlich
- Infrastructure Agent: Disaster Recovery Test
- Security Agent: Vulnerability Scan
- Alle Agents: Planning für nächstes Quartal

---

## 🚨 Eskalations-Prozess

**Kritische Fehler** (Services down):
1. Monitoring Agent: Fehler identifizieren
2. Infrastructure Agent: Traefik prüfen
3. Project Manager: Betroffene Services neustarten
4. Security Agent: Sicherheitslücken ausschließen

**Mittlere Fehler** (langsam, unstabil):
1. Monitoring Agent: Performance-Issue isolieren
2. Relevant Agent: Debugging durchführen
3. Repository: Lösung dokumentieren

**Niedrige Fehler** (Warnungen, Info):
1. Monitoring Agent: Notieren
2. Documentation Agent: Log/Changelog aktualisieren
3. Relevanter Agent: Für nächsten Sprint planen

---

## 🔗 Kontakt & Eskalation

- **Infrastructure Issues**: Infrastructure Agent
- **Application Issues**: Project Manager
- **Security Concerns**: Security Agent
- **Monitoring Alerts**: Monitoring Agent
- **Documentation**: Documentation Agent

---

## 📚 Weitere Ressourcen

- [README.md](./README.md) - Setup-Anleitung
- [Traefik Docs](https://doc.traefik.io/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Docker Security](https://docs.docker.com/engine/security/)

---

**Version**: 1.0  
**Zuletzt aktualisiert**: 2024-07-26  
**Nächste Überprüfung**: 2024-08-26

