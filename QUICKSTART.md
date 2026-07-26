# 🚀 QuickStart Guide

Dieses Dokument hilft dir, die Docker Local Network Umgebung in 5 Minuten zum Laufen zu bringen.

## 📋 Voraussetzungen

- ✅ Docker & Docker Compose auf VM (192.168.178.6) installiert
- ✅ SSH-Zugang zur VM
- ✅ Admin-Zugriff auf Windows Host
- ✅ Dieses Repository geklont/ausgepackt

## ⚡ 5 Schritte zum Start

### 1️⃣ DNS konfigurieren (2 Min)

**Auf deinem Windows Host:**

1. Öffne `C:\Windows\System32\drivers\etc\hosts` als Administrator
2. Trage am Ende folgende Zeilen ein:
```
192.168.178.6  docker.local
192.168.178.6  dashy.docker.local
192.168.178.6  it-tools.docker.local
192.168.178.6  planka.docker.local
192.168.178.6  portainer.docker.local
192.168.178.6  traefik.docker.local
```
3. Speichern (Strg+S)
4. PowerShell als Administrator öffnen:
```powershell
ipconfig /flushdns
```

### 2️⃣ SSH zur VM verbinden (0,5 Min)

```bash
# Linux/Mac/PowerShell
ssh user@192.168.178.6

# Windows (wenn SSH nicht installiert)
# Nutze PuTTY oder WSL2
```

### 3️⃣ Docker Network erstellen (0,5 Min)

```bash
docker network create docker-local-network --driver bridge
```

### 4️⃣ Traefik starten (1 Min)

```bash
cd /pfad/zu/docker.local-netzwerk
docker-compose up -d traefik

# Überprüfe Traefik läuft
docker ps | grep traefik
```

### 5️⃣ Projekte starten (1 Min)

```bash
# Option A: Manuell alle starten
cd projects/dashy && docker-compose up -d && cd ../..
cd projects/it-tools && docker-compose up -d && cd ../..
cd projects/planka && docker-compose up -d && cd ../..

# Option B: Shell-Script (einfacher)
bash scripts/start-all.sh
```

## ✅ Überprüfung

Öffne in deinem Browser:

| Service | URL |
|---------|-----|
| Dashboard | `http://traefik.docker.local:8080` |
| Dashy | `http://dashy.docker.local` |
| IT-Tools | `http://it-tools.docker.local` |
| Planka | `http://planka.docker.local` |
| Portainer | `http://portainer.docker.local` |

**Fertig! 🎉** Alle Services sollten jetzt erreichbar sein.

---

## 🆘 Wenn etwas nicht funktioniert

### ❌ "Kann Host nicht auflösen"
```powershell
# Auf Windows Host
ipconfig /flushdns
nslookup dashy.docker.local
```

### ❌ "Connection refused"
```bash
# Auf VM
docker ps              # Läuft Traefik?
docker-compose logs traefik  # Was sagt das Log?
```

### ❌ "Weiße Seite / 404"
```bash
# Auf VM
curl http://dashy.docker.local  # Funktioniert lokal?
docker exec traefik curl http://dashy:80  # Kann Traefik den Container erreichen?
```

---

## 📚 Weitere Schritte

Nach dem erfolgreichen Start:

- [ ] Lies [README.md](./README.md) für detaillierte Dokumentation
- [ ] Schau dir [AGENTS.md](./AGENTS.md) für Rollen an
- [ ] Konfiguriere [DNS_SETUP.md](./DNS_SETUP.md) (falls nötig)
- [ ] Füge deine privaten Projekte in `projects/` hinzu
- [ ] Aktiviere SSL/TLS für Production (siehe README)

---

## 🎯 Nächste Projekte hinzufügen

Für jedes neue Projekt:

```bash
# 1. Verzeichnis erstellen
mkdir projects/mein-projekt
cd projects/mein-projekt

# 2. docker-compose.yml erstellen
# (Kopiere Template aus README oder existing projects)

# 3. Starten
docker-compose up -d

# 4. In Hosts-Datei hinzufügen
# 192.168.178.6  mein-projekt.docker.local

# 5. Testen
# Öffne http://mein-projekt.docker.local
```

---

## 💡 Tipps

- **Logs anschauen**: `docker-compose logs -f [service]`
- **In Container gehen**: `docker exec -it [container] sh`
- **Alle stoppen**: `bash scripts/stop-all.sh`
- **Status prüfen**: `bash scripts/status.sh`
- **Traefik Dashboard**: Sehr hilfreich für Debugging!

---

## 📞 Hilfe & Support

- [README.md](./README.md) - Vollständige Dokumentation
- [AGENTS.md](./AGENTS.md) - Troubleshooting & Rollen
- [DNS_SETUP.md](./DNS_SETUP.md) - DNS-Probleme
- [Traefik Docs](https://doc.traefik.io/) - Offizielle Docs

---

**Happy Dockering! 🐳** ✨

