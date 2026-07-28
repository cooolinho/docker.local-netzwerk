# 📚 INDEX - Docker Local Network Projektübersicht

Diese Datei gibt dir einen Überblick über alle verfügbaren Dokumentationen und ihre Zwecke.

## 🎯 Nach Anwendungsfall

### 🚀 "Ich möchte schnell starten"
1. Lies: [QUICKSTART.md](./QUICKSTART.md) (5 Min)
2. Folge der Anleitung
3. Öffne http://traefik.docker.lan

### 📖 "Ich möchte alles verstehen"
1. Lies: [README.md](./README.md) (20-30 Min)
2. Schau: [STRUCTURE.md](./STRUCTURE.md) (5 Min)
3. Nutze: [AGENTS.md](./AGENTS.md) als Referenz

### 🌐 "DNS funktioniert nicht"
1. Lies: [DNS_SETUP.md](./DNS_SETUP.md)
2. Wende die Schritte an
3. Teste: `ping dashy.docker.lan`

### ❓ "Ich habe eine Frage"
1. Suche: [FAQ.md](./FAQ.md)
2. Wenn nicht gefunden, siehe [README.md](./README.md#-fehlerbehebung)

### 🔧 "Ich muss etwas verwalten/debuggen"
1. Lies: [AGENTS.md](./AGENTS.md) für Checklisten
2. Nutze: `bash scripts/status.sh` für Überblick
3. Siehe: [FAQ.md](./FAQ.md) für spezifische Probleme

---

## 📑 Alle Dokumentationen

### Hauptdokumentationen

| Datei | Länge | Für Wen | Inhalt |
|-------|-------|--------|--------|
| **[README.md](./README.md)** | 30 Min | Alle | Vollständige Dokumentation, Setup, Architektur, Troubleshooting |
| **[QUICKSTART.md](./QUICKSTART.md)** | 5 Min | Anfänger | Schnelle 5-Schritte-Anleitung |
| **[AGENTS.md](./AGENTS.md)** | 20 Min | Administratoren | Rollen, Checklisten, Wartungspläne |
| **[FAQ.md](./FAQ.md)** | 15 Min | Alle | Häufige Fragen & Lösungen |
| **[DNS_SETUP.md](./DNS_SETUP.md)** | 10 Min | Anfänger | DNS-Konfiguration für .docker.lan |
| **[STRUCTURE.md](./STRUCTURE.md)** | 10 Min | Entwickler | Ordnerstruktur & Dateiübersicht |
| **[INDEX.md](./INDEX.md)** | 5 Min | Alle | Diese Datei |

### Projekt-READMEs

| Projekt | Beschreibung | Status |
|---------|------------|--------|
| [projects/dashy/README.md](./projects/dashy/README.md) | Personal Dashboard | ✅ Ready |
| [projects/it-tools/README.md](./projects/it-tools/README.md) | IT-Tools Sammlung | ✅ Ready |
| [projects/planka/README.md](./projects/planka/README.md) | Kanban Board | ✅ Ready |
| [projects/portainer/README.md](./projects/portainer/README.md) | Docker Management | ✅ Ready |
| [projects/dozzle/README.md](./projects/dozzle/README.md) | Echtzeit Log-Viewer | ✅ Ready |
| [projects/logging/README.md](./projects/logging/README.md) | Loki + Promtail + Grafana (persistente Logs) | ✅ Ready |
| [projects/mailserver/README.md](./projects/mailserver/README.md) | Mailserver-Stack mit Roundcube + MariaDB | ✅ Ready |
| [projects/cloudbeaver/README.md](./projects/cloudbeaver/README.md) | Datenbank-Webclient (JDBC) | ✅ Ready |

### Projekt-Quickstarts

| Projekt | Quickstart |
|---------|------------|
| Mailserver | [projects/mailserver/QUICKSTART.md](./projects/mailserver/QUICKSTART.md) |

---

## 🗂️ Konfigurationsdateien

### Root-Level

| Datei | Zweck |
|-------|-------|
| `.env` | Umgebungsvariablen (NICHT in Git!) |
| `.env.example` | Template für .env |
| `.gitignore` | Git-Ignore-Regeln |
| `.dockerignore` | Docker-Build-Ignore-Regeln |
| `docker-compose.yml` | Traefik Service |

### traefik/

| Datei | Zweck |
|-------|-------|
| `traefik.yml` | Statische Traefik-Konfiguration |
| `config/dynamic.yml` | Dynamische Traefik-Konfiguration |
| `acme.json` | SSL-Zertifikate (auto) |

### projects/

Jedes Projekt hat:

```
projects/[name]/
├── docker-compose.yml     # Service Definition
├── README.md              # Projekt-Dokumentation
├── conf.yml               # Projekt-Konfiguration (optional)
└── data/                  # Persistente Daten (Volume)
```

### scripts/

| Skript | Zweck |
|--------|-------|
| `start-all.sh` | Startet alle Services |
| `stop-all.sh` | Stoppt alle Services |
| `status.sh` | Zeigt Service-Status |
| `create-private-symlink.sh` | Erstellt/loescht interaktiv Symlinks in `projects/private` |

---

## 🚀 Schnelle Kommandos

```bash
# Starten
bash scripts/start-all.sh

# Stoppen
bash scripts/stop-all.sh

# Status prüfen
bash scripts/status.sh

# Private Symlinks verwalten
bash scripts/create-private-symlink.sh

# Logs anschauen
docker-compose logs -f traefik
docker-compose -f projects/dashy/docker-compose.yml logs -f
docker-compose -f projects/mailserver/docker-compose.yml logs -f roundcube

 Logs im Browser (Echtzeit)
# http://dozzle.docker.lan

# Logs im Browser (Persistenz & Suche)
# http://grafana.docker.lan  → Dashboards → Docker Container Logs

# In Container gehen
docker exec -it [container-name] sh

# Traefik Dashboard
http://traefik.docker.lan

# Roundcube Webmail
http://mail.docker.lan

# CloudBeaver
http://cloudbeaver.docker.lan
```

---

## 📊 Service-Übersicht

| Service | URL | Image | Status |
|---------|-----|-------|--------|
| Traefik | http://traefik.docker.lan | traefik:v2.10 | ✅ Setup Ready |
| Dashy | http://dashy.docker.lan | lissy93/dashy | ✅ Setup Ready |
| IT-Tools | http://it-tools.docker.lan | corentinth/it-tools | ✅ Setup Ready |
| Planka | http://planka.docker.lan | ghcr.io/plankanban/planka | ✅ Setup Ready |
| Portainer | http://portainer.docker.lan | portainer/portainer-ce | ✅ Setup Ready |
| Dozzle | http://dozzle.docker.lan | amir20/dozzle | ✅ Setup Ready |
| Grafana | http://grafana.docker.lan | grafana/grafana | ✅ Setup Ready |
| Roundcube | http://mail.docker.lan | roundcube/roundcubemail | ✅ Setup Ready |
| CloudBeaver | http://cloudbeaver.docker.lan | dbeaver/cloudbeaver | ✅ Setup Ready |

---

## ✅ Checkliste für Neulinge

- [ ] **QUICKSTART.md** gelesen? (5 Min)
- [ ] **DNS konfiguriert**? (AdGuard Home → DNS-Rewrites: `*.docker.lan` → `192.168.178.6`)
- [ ] **Docker Network erstellt**? (`docker network create docker_lan_network`)
- [ ] **Traefik gestartet**? (`docker-compose up -d`)
- [ ] **Erstes Projekt funktioniert**? (http://dashy.docker.lan)
- [ ] **README.md durchgelesen**? (für tieferes Verständnis)
- [ ] **AGENTS.md studiert**? (für Verwaltungsaufgaben)

---

## 🎓 Lernpfad

### Level 1: Anfänger
1. QUICKSTART.md
2. STRUCTURE.md
3. Ein Projekt starten
4. DNS testen

### Level 2: Benutzer
1. README.md lesen
2. Mehrere Projekte deployen
3. Traefik Dashboard erkunden
4. DNS_SETUP.md (wenn Probleme)

### Level 3: Administrator
1. AGENTS.md lesen
2. Checklisten durcharbeiten
3. Backup/Restore lernen
4. Monitoring aufsetzen

### Level 4: Experte
1. Traefik erweiterte Konfiguration
2. SSL/TLS aktivieren
3. Performance Tuning
4. High Availability

---

## 🔗 Externe Ressourcen

- [Traefik Dokumentation](https://doc.traefik.io/)
- [Docker Compose Docs](https://docs.docker.com/compose/)
- [Docker Networking](https://docs.docker.com/network/)
- [Lissy93/Dashy](https://dashy.to/)
- [CorentinTh/IT-Tools](https://it-tools.tech/)
- [PlanKanban/Planka](https://planka.app/)
- [Roundcube](https://github.com/roundcube/roundcubemail)

---

## 🆘 Hilfe & Support

1. **Schnelle Antwort?** → [FAQ.md](./FAQ.md)
2. **Konzept nicht verstanden?** → [README.md](./README.md)
3. **Administrationsaufgaben?** → [AGENTS.md](./AGENTS.md)
4. **Projekt-spezifisch?** → `projects/[name]/README.md`
5. **DNS-Probleme?** → [DNS_SETUP.md](./DNS_SETUP.md)

---

## 📞 Kontakt & Unterstützung

Wenn du Fragen hast, versuche:

1. **Dokumentation durchsuchen** (Strg+F)
2. **FAQ.md konsultieren**
3. **README.md Troubleshooting-Sektion**
4. **Logs prüfen** (`docker-compose logs`)
5. **Script nutzen** (`bash scripts/status.sh`)

---

## 🎉 Willkommen!

Herzlich willkommen in deiner Docker Local Network Umgebung! 🐳

Diese Dokumentation sollte dir alles bieten, was du brauchst. Viel Erfolg bei der Verwaltung deiner lokalen Services!

---

**Zuletzt aktualisiert**: 2026-07-28  
**Version**: 1.0  
**Status**: ✅ Production Ready

