# ❓ FAQ - Häufig gestellte Fragen

## Allgemeine Fragen

### F: Warum brauche ich einen Reverse Proxy wie Traefik?

**A:** Mit Traefik kannst du statt einzelne Container mit Ports aufzurufen (z.B. `docker.lan:3000`, `docker.lan:3001`), alle Services über aussagekräftige Subdomains erreichen (`dashy.docker.lan`, `it-tools.docker.lan`). Das ist:
- 👍 Benutzerfreundlicher
- 👍 Professioneller
- 👍 Leichter zu merken
- 👍 Skalierbar

---

### F: Kann ich Traefik auch für Production nutzen?

**A:** Ja, aber mit zusätzlichen Sicherheitsmaßnahmen:
- ✅ SSL/TLS mit Let's Encrypt aktivieren
- ✅ BasicAuth oder OAuth2 hinzufügen
- ✅ Firewall Rules aufsetzen
- ✅ Rate Limiting konfigurieren
- ✅ Security Headers hinzufügen

Siehe [README.md - Sicherheit](./README.md#-sicherheit) für Details.

---

### F: Was ist das "docker_lan_network"?

**A:** Ein Docker Bridge-Netzwerk, das alle Container verbindet:
- Alle Container können sich untereinander über Containernamen erreichen
- Traefik kann alle Container sehen
- Isoliert vom Host-Netzwerk (für Sicherheit)

---

## Häufige Probleme

### F: "Verbindung verweigert" wenn ich http://dashy.docker.lan aufrufe

**A:** Überprüfe in dieser Reihenfolge:

1. **Läuft Traefik?**
   ```bash
   docker ps | grep traefik
   docker-compose logs traefik
   ```

2. **Existiert das Netzwerk?**
   ```bash
   docker network ls | grep docker_lan_network
   ```

3. **DNS funktioniert?**
   ```powershell
   nslookup dashy.docker.lan
   ```

4. **Firewall blockt?**
   ```powershell
   Test-NetConnection -ComputerName 192.168.178.6 -Port 80
   ```

---

### F: DNS sagt "Unknown host" / "nslookup funktioniert nicht"

**A:** 

1. **Hosts-Datei korrekt konfiguriert?**
   ```
   192.168.178.6  dashy.docker.lan
   ```

2. **Als Administrator gespeichert?**

3. **DNS Cache geleert?**
   ```powershell
   ipconfig /flushdns
   ```

4. **Browser Cache geleert?** (Strg+Shift+Entf)

5. **Lokal auf VM getestet?**
   ```bash
   curl http://dashy:80  # oder die korrekte Port
   curl http://traefik.docker.lan/dashboard/
   ```

---

### F: Traefik sieht meine Container nicht

**A:** Das Traefik-Container-Label ist wahrscheinlich falsch:

❌ **Falsch:**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.dashy.rule=Host(`dashy.${TRAEFIK_DOMAIN}`)"
  # Fehlt: die Service-Port-Definition!
```

✅ **Richtig:**
```yaml
labels:
  - "traefik.enable=true"
  - "traefik.http.routers.dashy.rule=Host(`dashy.${TRAEFIK_DOMAIN}`)"
  - "traefik.http.routers.dashy.entrypoints=web"
  - "traefik.http.services.dashy.loadbalancer.server.port=80"
```

---

### F: Container ist in einem anderen Netzwerk

**A:** Alle Services müssen im `docker_lan_network` sein:

```yaml
networks:
  docker_lan_network:
    external: true
```

Überprüfe:
```bash
docker inspect dashy | grep -A 5 Networks
```

---

### F: "Port bereits in Verwendung"

**A:** Wenn Port 80 schon belegt:

1. **Was benutzt den Port?**
   ```bash
   netstat -ano | findstr :80  # Windows
   ```

2. **Alternative Port nutzen:**
   ```yaml
   ports:
     - "8000:80"  # Extern 8000 → Intern 80
   ```

---

## Konfiguration & Anpassung

### F: Wie ändere ich die Traefik Dashboard-Passwort?

**A:** In `.env`:
```env
TRAEFIK_DASHBOARD_USER=admin
TRAEFIK_DASHBOARD_PASSWORD=mein-neues-passwort
```

Dann Traefik neustarten:
```bash
docker-compose down traefik
docker-compose up -d traefik
```

⚠️ **Hinweis**: Das aktuelle Passwort ist in `docker-compose.yml` gehashed. Bei Änderung musst du das neue Passwort auch dort aktualisieren.

---

### F: Wie nutze ich ein anderes Domain-Suffix statt ".docker.lan"?

**A:** In `.env` ändern:
```env
DOMAIN=mein.local  # statt docker.lan
```

Dann in `docker-compose.yml` der Projekte anpassen:
```yaml
- "traefik.http.routers.dashy.rule=Host(`dashy.${TRAEFIK_DOMAIN}`)"
```

Und Hosts-Datei aktualisieren:
```
192.168.178.6  mein.local
192.168.178.6  dashy.mein.local
```

---

### F: Kann ich HTTP → HTTPS Auto-Redirect?

**A:** Ja, in `traefik/traefik.yml`:

```yaml
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
```

---

### F: Wie aktiviere ich BasicAuth?

**A:** 

1. **Passwort hashen** (auf Linux/WSL):
   ```bash
   htpasswd -c auth.txt admin
   ```

2. **Datei speichern** in `traefik/auth.txt`

3. **In `traefik/config/dynamic.yml` hinzufügen:**
   ```yaml
   middlewares:
     auth:
       basicAuth:
         usersFile: /config/auth.txt
   ```

4. **In Labels nutzen:**
   ```yaml
   - "traefik.http.routers.dashy.middlewares=auth"
   ```

---

## Wartung & Betrieb

### F: Wie mache ich ein Backup?

**A:** 

```bash
# Alle Projekt-Daten sichern
tar czf backup_$(date +%Y%m%d).tar.gz traefik/ projects/

# Spezifische Volumes
docker run --rm -v dashy-data:/data -v "$PWD":/backup \
  alpine tar czf /backup/dashy-backup.tar.gz /data
```

---

### F: Wie update ich die Container-Images?

**A:**

```bash
# Alle Images pullen
docker-compose pull

# Dann Container neustarten
docker-compose down
docker-compose up -d
```

---

### F: Wie lösche ich einen Container komplett?

**A:**

```bash
# Container stoppen
docker-compose down

# Volumes auch löschen (⚠️ Daten gehen verloren!)
docker-compose down -v

# Images löschen
docker rmi image-name:tag
```

---

### F: Kann ich Container im Hintergrund laufen lassen ohne Logs zu sehen?

**A:** Ja, nutze `-d`:
```bash
docker-compose up -d
```

Logs später anschauen:
```bash
docker-compose logs -f service-name
```

---

## Erweiterte Fragen

### F: Kann ich mehrere Traefik Instanzen nutzen?

**A:** Nicht empfohlen. Für Hochverfügbarkeit:
- Nutze Traefik Clustering
- Oder setze einen Load Balancer (z.B. HAProxy) davor

---

### F: Wie nutze ich Traefik mit Kubernetes?

**A:** Das ist hier nicht relevant, da wir Docker Compose nutzen. Traefik funktioniert aber auch mit Kubernetes als Ingress Controller.

---

### F: Kann ich private Docker Registries nutzen?

**A:** Ja, mit Credentials:

```bash
docker login -u username registry.example.com
```

Dann in `docker-compose.yml`:
```yaml
image: registry.example.com/mein-image:latest
```

---

### F: Wie nutze ich Umgebungsvariablen aus .env?

**A:** Mit `${VAR_NAME}` in `docker-compose.yml`:

```yaml
environment:
  - DB_PASSWORD=${DB_PASSWORD}
  - API_URL=http://api.${DOMAIN}
```

Die `.env` wird automatisch von `docker-compose` gelesen.

---

## Performance & Optimierung

### F: Wie verbessere ich die Performance?

**A:**

1. **Container-Ressourcen limitieren** (in docker-compose):
   ```yaml
   resources:
     limits:
       cpus: '1'
       memory: 512M
     reservations:
       cpus: '0.5'
       memory: 256M
   ```

2. **Logging-Volume begrenzen**:
   ```yaml
   logging:
     driver: "json-file"
     options:
       max-size: "10m"
       max-file: "3"
   ```

3. **Traefik Log-Level reduzieren** (nur INFO):
   ```env
   TRAEFIK_LOG_LEVEL=INFO
   ```

---

### F: Wie reduziere ich die Disk-Nutzung?

**A:**

```bash
# Ungenutzte Images löschen
docker image prune -a

# Ungenutzte Volumes löschen
docker volume prune

# Ungenutzte Networks löschen
docker network prune

# Build Cache löschen
docker builder prune
```

---

## Sicherheit

### F: Ist diese Konfiguration sicher für Production?

**A:** Nein, nicht direkt. Du musst:
- ✅ SSL/TLS aktivieren
- ✅ Starke Passwörter setzen
- ✅ Firewall Rules aufsetzen
- ✅ Rate Limiting konfigurieren
- ✅ Secrets nicht in `.env` hardcoden
- ✅ Regelmäßige Updates durchführen

Siehe [README.md - Sicherheit](./README.md#-sicherheit).

---

### F: Wie verstecke ich Container vor dem Internet?

**A:** 

1. **Nur lokal exponieren** (keine Port-Bindung):
   ```yaml
   # ❌ Nicht machen
   ports:
     - "3000:3000"
   
   # ✅ Machen (über Traefik im Netzwerk)
   # Keine ports-Sektion
   ```

2. **Firewall-Rules**:
   ```bash
   # Nur lokales Netzwerk erlauben
   iptables -A INPUT -p tcp --dport 80 -s 192.168.178.0/24 -j ACCEPT
   iptables -A INPUT -p tcp --dport 80 -j DROP
   ```

---

## Noch Fragen?

- Liest [README.md](./README.md) für komplette Dokumentation
- Schau [AGENTS.md](./AGENTS.md) für detaillierte Troubleshooting
- [Traefik Docs](https://doc.traefik.io/) für Traefik-spezifische Fragen
- [Docker Docs](https://docs.docker.com/) für Docker Basics

---

**Zuletzt aktualisiert**: 2024-07-26

