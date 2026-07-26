# DNS-Konfiguration für .docker.local
# ==================================

## Option 1: Windows Hosts-Datei (Recommended für Anfang)

### Schritt-für-Schritt:

1. **Öffne Editor als Administrator**
   - Rechtsklick auf Editor (oder Notepad) → "Als Administrator ausführen"

2. **Öffne die Hosts-Datei**
   - Datei → Öffnen
   - Navigiere zu: `C:\Windows\System32\drivers\etc\hosts`
   - (Wenn Hosts-Datei nicht sichtbar: Dateityp auf "Alle Dateien (*.*)" ändern)

3. **Trage folgende Einträge am Ende der Datei ein**:

```
# ============================================
# Docker Local Network
# ============================================
192.168.178.6  docker.local
192.168.178.6  dashy.docker.local
192.168.178.6  it-tools.docker.local
192.168.178.6  planka.docker.local
192.168.178.6  portainer.docker.local
192.168.178.6  private-project-1.docker.local
192.168.178.6  private-project-2.docker.local
192.168.178.6  private-project-3.docker.local
192.168.178.6  traefik.docker.local
```

4. **Speichern** (Ctrl+S)

5. **DNS Cache leeren** (PowerShell oder CMD als Administrator):
```powershell
ipconfig /flushdns
```

6. **Testen**:
```
ping dashy.docker.local
nslookup dashy.docker.local
```

---

## Option 2: Wildcard DNS (Advanced)

Wenn du viele neue Subdomains hinzufügst, verwende stattdessen einen Wildcard-Eintrag:

```hosts
192.168.178.6  docker.local
192.168.178.6  *.docker.local
```

Das macht alle Subdomains automatisch verfügbar ohne einzelne Einträge.

---

## Option 3: Lokaler DNS-Server (Production)

Für eine productionartige Umgebung können Sie einen lokalen DNS-Server verwenden:

### Mit Unbound (auf Linux/WSL2):

```bash
apt-get install unbound

# /etc/unbound/unbound.conf
server:
    local-data: "docker.local. IN A 192.168.178.6"
    local-data: "*.docker.local. IN A 192.168.178.6"

systemctl restart unbound
```

### Mit CoreDNS (in Docker):

```yaml
# docker-compose.yml (zusätzlicher Service)
coredns:
  image: coredns/coredns:latest
  ports:
    - "53:53/udp"
    - "53:53/tcp"
  volumes:
    - ./dns/Corefile:/Corefile:ro
  networks:
    - docker-local-network
```

Datei `dns/Corefile`:
```
. {
    log
    errors
    
    # Lokale Domain
    file /etc/coredns/docker.local.zone docker.local
    
    # Fallback auf öffentliche DNS
    forward . 8.8.8.8 8.8.4.4
}
```

---

## Troubleshooting

### "Konnte Host nicht auflösen"

1. **Hosts-Datei nochmal speichern?** (Admin-Rechte?)
2. **DNS Cache leeren**:
   ```powershell
   ipconfig /flushdns
   ipconfig /all  # Überprüfe, welche DNS dein Computer nutzt
   ```
3. **Teste direkt mit IP**:
   ```
   curl http://192.168.178.6
   ```

### "Ping funktioniert, aber Browser zeigt Fehler"

1. **Überprüfe Traefik läuft**:
   ```bash
   docker ps | grep traefik
   ```
2. **Traefik Logs**:
   ```bash
   docker-compose logs traefik
   ```
3. **Teste direkt am Host**:
   ```bash
   curl http://traefik.docker.local:8080/dashboard/
   ```

### "Neue Subdomains funktionieren nicht"

1. **Hosts-Datei aktualisiert?**
2. **DNS Cache geleert?**
3. **Browser Cache geleert?** (Ctrl+Shift+Delete)
4. **Container/Traefik neustarten**:
   ```bash
   docker-compose restart traefik
   ```

---

## Überprüfungs-Checkliste

- [ ] Hosts-Datei als Admin bearbeitet?
- [ ] Einträge korrekt eingegeben?
- [ ] DNS Cache geleert?
- [ ] `ping dashy.docker.local` erfolgreich?
- [ ] `curl http://dashy.docker.local` funktioniert?
- [ ] Traefik Container läuft? (`docker ps | grep traefik`)
- [ ] Zielcontainer läuft? (`docker ps | grep dashy`)

---

## Firewall / Port-Blockierung

Falls du hinter einer Firewall sitzt:

- **HTTP (Port 80)**: Sollte offen sein
- **HTTPS (Port 443)**: Für SSL (später)
- **DNS (Port 53)**: Nur wenn lokaler DNS-Server

Prüfe mit:
```bash
Test-NetConnection -ComputerName 192.168.178.6 -Port 80
```

---

**Zuletzt aktualisiert**: 2024-07-26

