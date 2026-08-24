# 🐋 Portainer Update - Schnellreferenz

## Schnellstart

```bash
cd projects/portainer

# Aktuelle Version installieren
./update.sh

# Mit Bestätigung & Backup
./update.sh --backup
```

## Szenarien

### Szenario 1: Regelmäßiges Update (Standard)
```bash
# Einfach die neueste Version installieren
cd projects/portainer
./update.sh
```
✅ Das Script wird fragen, ob fortgefahren werden soll  
✅ Schnell und sicher  
❌ Kein Backup

### Szenario 2: Wichtiges Update mit Backup (empfohlen)
```bash
# Update mit automatischem Backup
cd projects/portainer
./update.sh --backup
```
✅ Backup wird vor dem Update erstellt  
✅ Im `backups/` Ordner mit Datumsstempel  
✅ Kann jederzeit wiederhergestellt werden  
⏱️ Dauert etwas länger (Backup ist nicht klein)

### Szenario 3: Auf bestimmte Version aktualisieren
```bash
# Spezifische Version installieren
cd projects/portainer
./update.sh 2.18.3

# Mit Backup
./update.sh 2.18.3 --backup
```
✅ Kontrolliertes Upgrade zu bekannter Version  
✅ Nützlich bei Problemen mit neuer Version

### Szenario 4: Automatisches Backup vor jedem Update
```bash
# Cron-Job einrichten (täglich um 2:00 Uhr)
crontab -e

# Hinzufügen:
0 2 * * * cd /path/to/projects/portainer && ./update.sh --backup > /var/log/portainer-update.log 2>&1
```
✅ Läuft automatisch jeden Tag  
✅ Logs in `/var/log/portainer-update.log`

## Troubleshooting

### Problem: "permission denied"
```bash
# Script ausführbar machen
chmod +x projects/portainer/update.sh
```

### Problem: "docker: command not found"
```bash
# Docker ist nicht im PATH
# Entweder Docker installieren oder Pfad anpassen
which docker
export PATH=$PATH:/path/to/docker
```

### Problem: "Cannot connect to Docker daemon"
```bash
# Docker-Daemon läuft nicht
# Starten (Beispiel für Linux mit systemd):
sudo systemctl start docker

# Oder Docker Desktop öffnen (Windows/macOS)
```

### Problem: Update schlägt fehl
```bash
# Logs anschauen für Details
docker-compose -f projects/portainer/docker-compose.yml logs portainer

# Manueller Rollback auf letzte funktionierende Version
# 1. Altes Backup localisieren
ls -la projects/portainer/backups/

# 2. Backup wiederherstellen
docker run --rm -v portainer-data:/data -v "$PWD":/backup \
  alpine tar xzf /backup/portainer-backup-DATUMSTEMPEL.tar.gz -C /

# 3. Container neu starten
docker-compose -f projects/portainer/docker-compose.yml restart portainer
```

## Best Practices

1. **Immer Backup machen** für produktive Systeme
   ```bash
   ./update.sh --backup
   ```

2. **Test vor Production**
   - Neue Version erst auf Test-System prüfen
   - Dann auf Production aktualisieren

3. **Alte Backups regelmäßig löschen**
   ```bash
   # Backups älter als 30 Tage löschen
   find projects/portainer/backups -name "*.tar.gz" -mtime +30 -delete
   ```

4. **Version dokumentieren**
   ```bash
   # Aktuelle Version überprüfen
   docker ps --filter "name=portainer" --format "{{.Image}}"
   ```

5. **Nach Update testen**
   - Im Browser öffnen: `http://portainer.docker.lan`
   - Admin-Panel überprüfen
   - Container-Status prüfen

## Versionen finden

Alle verfügbaren Versionen:
https://hub.docker.com/r/portainer/portainer-ce/tags

Beispiele:
- `2.18.3` (Spezifische Release)
- `2.18` (Latest von 2.18.x)
- `latest` (Neuste Version)
- `2.17-alpine` (Mit Alpine Linux)

## Support & Hilfe

```bash
# Portainer Hilfe im Script anzeigen
./update.sh --help

# Offizielle Portainer Dokumentation
# https://docs.portainer.io

# GitHub Issues
# https://github.com/portainer/portainer/issues
```

---

**Zuletzt aktualisiert**: 2026-08-16  
**Script-Version**: 1.0  
**Portainer CE**: Alle Versionen ab 2.0

u
