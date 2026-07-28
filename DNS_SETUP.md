# 🌐 DNS-Konfiguration für .docker.lan
# =====================================

## ✅ Empfohlen: AdGuard Home (Wildcard DNS)

Da **AdGuard Home** (192.168.178.3) bereits im Netzwerk läuft, ist dies die bevorzugte Methode.
Ein einziger Wildcard-Eintrag macht **alle** Subdomains automatisch verfügbar — kein manuelles
Nachtragen bei neuen Projekten erforderlich.

---

## 🔧 Schritt-für-Schritt: AdGuard Home einrichten

### 1️⃣ AdGuard Home öffnen

Öffne im Browser:

```
http://192.168.178.3
```

Melde dich mit deinen AdGuard Home Zugangsdaten an.

---

### 2️⃣ DNS-Rewrites öffnen

Navigiere zu:

> **Einstellungen** → **DNS-Einstellungen** → Abschnitt **DNS-Rewrites**
> (oder direkt: `http://192.168.178.3/#dns-rewrites`)

Klicke auf **"DNS-Rewrite hinzufügen"**.

---

### 3️⃣ Wildcard-Eintrag für *.docker.lan hinzufügen

Füge folgenden Eintrag hinzu:

| Feld | Wert |
|------|------|
| **Domain** | `*.docker.lan` |
| **Antwort** | `192.168.178.6` |

➡️ Klicke **"Speichern"**.

> 💡 **Tipp**: Der Wildcard `*.docker.lan` deckt **alle** Subdomains ab (dashy, it-tools, traefik, etc.)
> — neue Projekte werden automatisch aufgelöst, ohne weitere DNS-Einträge!

---

### 4️⃣ Eintrag für die Root-Domain hinzufügen

Füge einen zweiten Eintrag für die Root-Domain hinzu:

| Feld | Wert |
|------|------|
| **Domain** | `docker.lan` |
| **Antwort** | `192.168.178.6` |

➡️ Klicke **"Speichern"**.

---

### 5️⃣ AdGuard Home als DNS-Server setzen

Damit alle Geräte im Netzwerk die Einträge nutzen, muss AdGuard Home als DNS-Server genutzt werden.

**Option A: Im Router (FritzBox)**

1. FritzBox-Oberfläche öffnen: `http://192.168.178.1`
2. **Heimnetz** → **Netzwerk** → Reiter **IPv4-Einstellungen**
   - Lokaler DNS-Server: `192.168.178.3` (AdGuard Home)
3. Speichern & Router neu starten

> ⚠️ Falls der FritzBox-DNS-Rebind-Schutz aktiv ist:
> **Heimnetz** → **Netzwerk** → **DNS-Rebind-Schutz** → `docker.lan` als Ausnahme eintragen.

**Option B: Nur auf deinem Windows-PC**

1. `Systemsteuerung` → `Netzwerk und Internet` → `Netzwerkverbindungen`
2. Adapter Rechtsklick → **Eigenschaften**
3. **Internetprotokoll Version 4 (TCP/IPv4)** → **Eigenschaften**
4. **Folgende DNS-Serveradressen verwenden:**
   - Bevorzugter DNS: `192.168.178.3`
   - Alternativer DNS: `192.168.178.1` (Router als Fallback)
5. **OK** → **OK**

---

### 6️⃣ DNS-Cache leeren & testen

```powershell
# DNS Cache leeren
ipconfig /flushdns

# Testen
nslookup dashy.docker.lan 192.168.178.3
nslookup traefik.docker.lan 192.168.178.3
nslookup it-tools.docker.lan 192.168.178.3
```

Erwartete Ausgabe:
```
Name:    dashy.docker.lan
Address: 192.168.178.6
```

---

### 7️⃣ Im Browser testen

Öffne folgende URLs:

| Service | URL |
|---------|-----|
| **Traefik Dashboard** | http://traefik.docker.lan |
| **Dashy** | http://dashy.docker.lan |
| **IT-Tools** | http://it-tools.docker.lan |
| **Planka** | http://planka.docker.lan |
| **Portainer** | http://portainer.docker.lan |

---

## 📋 Übersicht der DNS-Rewrites in AdGuard Home

So sieht die fertige Konfiguration in AdGuard Home aus:

| Domain | Antwort (IP) | Zweck |
|--------|-------------|-------|
| `docker.lan` | `192.168.178.6` | Root-Domain |
| `*.docker.lan` | `192.168.178.6` | Alle Subdomains (Wildcard) |

> ⚠️ Wenn sowohl `*.docker.lan` als auch spezifische Einträge vorhanden sind,
> hat der spezifische Eintrag Vorrang.

---

## 🆕 Neues Projekt hinzufügen

Dank des Wildcard-Eintrags musst du bei neuen Projekten **keinen neuen DNS-Eintrag** hinzufügen!

```bash
# Neues Projekt starten
cd projects/mein-neues-projekt
docker-compose up -d

# Sofort erreichbar unter (kein DNS-Update nötig!):
# http://mein-neues-projekt.docker.lan
```

---

## 🔄 Fallback: Windows Hosts-Datei

Falls AdGuard Home nicht verfügbar ist (z.B. Wartung), kannst du temporär die Hosts-Datei nutzen:

1. **Öffne Editor als Administrator**
2. **Öffne**: `C:\Windows\System32\drivers\etc\hosts`
3. **Füge folgende Einträge hinzu**:

```
# ============================================
# Docker Local Network (Fallback ohne AdGuard)
# ============================================
192.168.178.6  docker.lan
192.168.178.6  dashy.docker.lan
192.168.178.6  it-tools.docker.lan
192.168.178.6  planka.docker.lan
192.168.178.6  portainer.docker.lan
192.168.178.6  traefik.docker.lan
192.168.178.6  private-project-1.docker.lan
192.168.178.6  private-project-2.docker.lan
192.168.178.6  private-project-3.docker.lan
```

4. **Speichern** (Ctrl+S) und **DNS Cache leeren**:
```powershell
ipconfig /flushdns
```

> ⚠️ Hosts-Datei hat **keinen Wildcard-Support** — neue Projekte müssen manuell eingetragen werden.

---

## 🐛 Troubleshooting

### "nslookup gibt falsche IP zurück"

```powershell
# Prüfe, welchen DNS-Server du nutzt
ipconfig /all | findstr "DNS-Server"

# Teste direkt gegen AdGuard Home
nslookup dashy.docker.lan 192.168.178.3

# DNS-Cache leeren
ipconfig /flushdns
```

### "Ping funktioniert, aber Browser zeigt Fehler"

```bash
# Prüfe ob Traefik läuft
docker ps | grep traefik

# Traefik Logs ansehen
docker-compose logs traefik

# Teste direkt mit IP
curl http://192.168.178.6 -H "Host: dashy.docker.lan"
```

### "AdGuard Home Rewrite wird ignoriert"

1. Prüfe ob AdGuard Home als DNS-Server konfiguriert ist:
   ```powershell
   nslookup docker.lan
   # Server sollte 192.168.178.3 sein
   ```
2. DNS Cache leeren: `ipconfig /flushdns`
3. Browser-Cache leeren: `Ctrl+Shift+Delete`
4. Prüfe ob der Eintrag in AdGuard Home korrekt gespeichert ist

### "Neue Subdomain nicht erreichbar"

1. DNS-Auflösung testen: `nslookup mein-projekt.docker.lan 192.168.178.3`
   → Sollte `192.168.178.6` zurückgeben (dank Wildcard automatisch ✅)
2. Container läuft? `docker ps | grep mein-projekt`
3. Traefik Labels korrekt? `docker inspect mein-projekt | grep traefik`

---

## ✅ Überprüfungs-Checkliste

- [ ] AdGuard Home unter `http://192.168.178.3` erreichbar?
- [ ] DNS-Rewrite `*.docker.lan` → `192.168.178.6` angelegt?
- [ ] DNS-Rewrite `docker.lan` → `192.168.178.6` angelegt?
- [ ] AdGuard Home als DNS-Server konfiguriert (Router oder PC)?
- [ ] `nslookup dashy.docker.lan 192.168.178.3` gibt `192.168.178.6` zurück?
- [ ] `http://traefik.docker.lan` im Browser erreichbar?
- [ ] `http://dashy.docker.lan` im Browser erreichbar?

---

## Firewall / Port-Blockierung

Falls du hinter einer Firewall sitzt:

- **HTTP (Port 80)**: Sollte offen sein
- **HTTPS (Port 443)**: Für SSL (später)
- **DNS (Port 53)**: AdGuard Home muss auf Port 53 erreichbar sein

Prüfe mit:
```powershell
Test-NetConnection -ComputerName 192.168.178.6 -Port 80
Test-NetConnection -ComputerName 192.168.178.3 -Port 53
```

---

**Zuletzt aktualisiert**: 2026-07-28  
**DNS-Methode**: AdGuard Home (Wildcard DNS Rewrite)  
**AdGuard Home**: `192.168.178.3`  
**Docker Host**: `192.168.178.6`
