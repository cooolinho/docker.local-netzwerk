# 🐋 Portainer - Docker Management UI

Portainer ist ein leichtgewichtiges Docker-Management-Interface mit Web-Zugriff für die Verwaltung aller Docker-Ressourcen.

## 🔗 Links

- **Domain**: `http://portainer.docker.lan`
- **Image**: `portainer/portainer-ce`
- **GitHub**: https://github.com/portainer/portainer
- **Docs**: https://docs.portainer.io

## ✨ Features

- ✅ Docker Container Management
- ✅ Image Management
- ✅ Network & Volume Management
- ✅ Logs & Events Monitoring
- ✅ Docker Stats & Ressourcen-Überwachung
- ✅ App Templates
- ✅ Benutzer & Team Management
- ✅ Stack Deployment
- ✅ Registry Management

## 🚀 Starten

```bash
cd projects/portainer
docker-compose up -d

# Logs anschauen (Initalisierung dauert ~5 Sekunden)
docker-compose logs -f portainer
```

## 📖 Erstes Login

1. Öffne `http://portainer.docker.lan`
2. Erstelle Admin-Benutzer (Benutzername & Passwort)
3. Wähle "Docker" als Environment (lokaler Docker-Daemon)
4. Fertig! 🎉

## 🛠️ Verwendung

### Container verwalten

**Gehe zu**: **Containers**

- Sieh alle laufenden & gestoppten Container
- Starten/Stoppen/Pausieren/Neu starten
- Logs ansehen
- Terminal-Zugriff (exec)
- Port-Mappings verwalten

### Images verwalten

**Gehe zu**: **Images**

- Alle lokalen Images sehen
- Neue Images pullen
- Tags erstellen
- Images löschen
- Image Layers inspizieren

### Logs & Monitoring

**Gehe zu**: **Containers** → Container auswählen → **Logs**

Oder nutze den **Stats Tab** für Echtzeit-Monitoring:
- CPU-Auslastung
- Speicherverbrauch
- Netzwerk I/O
- Block I/O

### Networks verwalten

**Gehe zu**: **Networks**

- Docker Networks übersehen
- Neue Networks erstellen
- Container verbinden/trennen
- Netzwerk-Konfiguration inspizieren

### Volumes verwalten

**Gehe zu**: **Volumes**

- Alle Volumes sehen
- Volume Details anschauen
- Volumes erstellen/löschen

### Stacks deployen

**Gehe zu**: **Stacks** → **Add Stack**

- Docker Compose YAML hochladen
- Stack schnell deployen
- Environment variables setzen

## 📦 Storage

| Volume | Inhalt | Wichtig |
|--------|--------|---------|
| `portainer-data` | Portainer-Konfiguration, Benutzer, Settings | ✅ JA - Backup! |

## ⚠️ Docker Socket

Portainer benötigt Zugriff auf `/var/run/docker.sock`:

```yaml
volumes:
  - /var/run/docker.sock:/var/run/docker.sock:ro  # Read-Only aus Sicherheit
```

Dies erlaubt Portainer:
- Alle Container zu sehen
- Images zu verwalten
- Networks zu managen
- Logs zu lesen
- Stats zu erfassen

## 🔐 Sicherheit

⚠️ **Diese Konfiguration ist nur für lokales Netzwerk gedacht!**

### Für Production / Remote-Zugriff:

1. **SSL/TLS aktivieren**
   ```yaml
   - "traefik.http.routers.portainer.tls=true"
   ```

2. **BasicAuth hinzufügen**
   ```bash
   htpasswd -c auth.txt admin
   ```

3. **IP-Whitelisting in Traefik**
   ```yaml
   - "traefik.http.middlewares.portainer-auth.basicauth.usersFile=/config/auth.txt"
   - "traefik.http.routers.portainer.middlewares=portainer-auth"
   ```

4. **Starke Passwörter** setzen
5. **Docker Socket Read-Only** halten

## 🔄 Backup & Restore

### Backup

```bash
# Portainer-Daten sichern
docker run --rm -v portainer-data:/data -v "$PWD":/backup \
  alpine tar czf /backup/portainer-backup.tar.gz /data

# Mit Datumstempel
docker run --rm -v portainer-data:/data -v "$PWD":/backup \
  alpine tar czf /backup/portainer-backup-$(date +%Y%m%d).tar.gz /data
```

### Restore

```bash
# Backup einspielen
docker run --rm -v portainer-data:/data -v "$PWD":/backup \
  alpine tar xzf /backup/portainer-backup.tar.gz -C /

# Container neustarten
docker-compose restart portainer
```

## 🐛 Troubleshooting

### ❌ Portainer zeigt "Cannot connect to Docker daemon"

```bash
# 1. Docker Socket existiert?
ls -la /var/run/docker.sock

# 2. Container-Logs prüfen
docker-compose logs portainer

# 3. Docker läuft?
docker ps

# 4. Docker Socket bereitstellung prüfen
docker exec -it portainer ls -la /var/run/docker.sock
```

### ❌ Portainer sehr langsam

- Zu viele Container?
- Check: **Stats** Tab für Portainer-Ressourcen
- Container neustarten:
  ```bash
  docker-compose restart portainer
  ```

### ❌ Passwort vergessen

```bash
# Einzige Lösung: Daten löschen & neu starten
docker-compose down -v
docker-compose up -d

# Neuer Admin-Benutzer wird benötigt
```

### ❌ Portainer Container crasht

```bash
# 1. Logs anschauen
docker-compose logs portainer

# 2. Konfiguration prüfen
docker-compose config

# 3. Volume-Berechtigungen prüfen
docker volume ls | grep portainer
docker volume inspect portainer-data
```

### ❌ Verbindung von außerhalb funktioniert nicht

1. Traefik läuft? `docker ps | grep traefik`
2. DNS funktioniert? `nslookup portainer.docker.lan`
3. Labels korrekt? `docker-compose config | grep traefik`

## 🔄 Update

```bash
# Neuestes Image pullen
docker-compose pull portainer

# Container neustarten
docker-compose down
docker-compose up -d

# Logs anschauen
docker-compose logs -f portainer
```

## 📊 Tipps & Best Practices

### 1. **Regelmäßig Backups machen**
```bash
# Wöchentlich automatisch
0 2 * * 0 docker run --rm -v portainer-data:/data -v /backups:/backup \
  alpine tar czf /backup/portainer-$(date +\%Y\%m\%d).tar.gz /data
```

### 2. **Monitoring einrichten**
- Nutze Portainer's **Stats** für Überblick
- Überprüfe regelmäßig Logs
- Container Health Checks nutzen

### 3. **Cleanup regelmäßig durchführen**
```bash
# Im Portainer Dashboard
# Gehe zu: Containers → Filters → "Exited"
# Lösche alle gestoppten Container
```

### 4. **Teams & Benutzer verwenden**
- Für mehrere Administratoren
- Feinere Zugriffskontrolle
- In Settings konfigurierbar

## 🎓 Häufige Aufgaben

### Container schnell neustarten
**Containers** → Wähle Container → **Restart**

### Neue Umgebungsvariable setzen
**Containers** → Container → **Inspect** → Environment ansehen

### In Container gehen (Shell)
**Containers** → Container → **Exec Console** → `/bin/sh` oder `/bin/bash`

### Image inspizieren
**Images** → Wähle Image → **Inspect** → Konfiguration ansehen

---

Zuletzt aktualisiert: 2024-07-26

