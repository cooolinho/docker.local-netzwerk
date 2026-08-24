# 📦 Database Backup Strategy & Guide

Dieses Dokument beschreibt die automatisierte Datenbank-Backup-Lösung für die Docker Local Network Infrastruktur.

## 🎯 Überblick

Die Backup-Lösung bietet:

- ✅ **Interaktive Bedienung** - Schritt-für-Schritt Credential-Eingabe
- ✅ **Multi-Database Support** - PostgreSQL, MySQL, MariaDB
- ✅ **Automatische Kompression** - ZIP-Archivierung mit Zeitstempel
- ✅ **Cron-Integration** - Planbare automatische Backups
- ✅ **Automatische Bereinigung** - Alte Backups nach konfigurierbarem Zeitraum löschen
- ✅ **Audit-Logging** - Alle Backup-Operationen werden geloggt

## 📂 Verzeichnisstruktur

```
backups/
├── .gitignore                  # Backups aus Git ausgeschlossen
├── backup.log                  # Audit-Log aller Operationen
├── backup_planka_20260816_120000.zip
├── backup_roundcube_20260816_020000.zip
└── ...
```

## 🚀 Schnelleinstieg

### 1. Interaktives Backup erstellen

```bash
cd /home/cooolinho/docker.local-netzwerk/projects/db-backup
docker-compose up -d --build
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh"
```

Das Script listet laufende PostgreSQL-/MySQL-/MariaDB-Container und liest die zugehörigen Projekt-`.env`-Dateien. Fehlende Werte können manuell ergänzt werden.

**Beispiel-Output:**
```
╔════════════════════════════════════════╗
║   Database Backup Tool - Main Menu      ║
╚════════════════════════════════════════╝
1) Create Backup
2) Setup Cron Job
3) Remove Cron Job
4) List Cron Jobs
5) Cleanup Old Backups
6) View Backup Log
7) List Backups
8) Exit
Choose [1-8]: 1

=== Running Database Containers ===
1) personal-home-portal-db [mysql] (project: personal-home-portal, .env: ...)
m) Manual database input
Choose container [1-1 or m]: 1

=== Database Connection Details ===
Database Host (default: personal-home-portal-db): 
Database Port (default: 3306): 
Database Name (default: ...): 
Database User (default: ...): 
Database Password: 
✅ MySQL connection test passed
✅ Backup created: backup_personal-home-portal_20260816_120000.zip
ℹ️  Backup size: 2.3M
```

## ⏰ Automatische Backups mit Cron

### Setup (einmalig)

```bash
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --setup-cron"
```

Das Script wird dann:
1. Einen laufenden DB-Container auswählen
2. Fehlende Credentials interaktiv abfragen
3. Die vollständige Konfiguration vor dem Cron-Setup persistent speichern
4. Eine Cron-Zeile mit `--auto --config` registrieren

Die Configs liegen im Runner unter `/var/lib/db-backup/config` und auf dem Host unter `projects/db-backup/config/`. Jede Datei hat Permissions `600`; das Verzeichnis hat Permissions `700`. Die Legacy-Datei `.backup-config` bleibt als Fallback für `--auto` lesbar.

Der Runner startet den Cron-Daemon automatisch. Ein weiterer Cron-Lauf fragt keine Credentials ab, sondern verwendet die gespeicherte Config-Datei.

### Cron-Schedule anpassen

Im `.env` File:

```bash
# Täglich um 02:00 Uhr (Default)
BACKUP_SCHEDULE=0 2 * * *

# Täglich um 03:00 Uhr
BACKUP_SCHEDULE=0 3 * * *

# Jeden Sonntag um 04:00 Uhr
BACKUP_SCHEDULE=0 4 * * 0

# Mehrmals täglich (02:00 und 14:00 Uhr)
BACKUP_SCHEDULE=0 2,14 * * *
```

Cron-Format: `minute hour day month weekday`

### Cron-Jobs verwalten

```bash
# Cron-Jobs anzeigen
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --list-cron"

# Cron-Job entfernen
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --remove-cron"
```

## 🧹 Automatische Bereinigung

### Konfiguration

Im `.env` File:

```bash
# Backups älter als 30 Tage löschen (Default)
BACKUP_RETENTION_DAYS=30

# Backups älter als 7 Tage löschen
BACKUP_RETENTION_DAYS=7

# Backups 90 Tage behalten
BACKUP_RETENTION_DAYS=90
```

### Manuelle Bereinigung

```bash
# Mit Default-Tagen aus .env
bash scripts/backup_db.sh --cleanup

# Mit benutzerdefinierten Tagen
bash scripts/backup_db.sh --cleanup 14

# Oder via interaktives Menü
bash scripts/backup_db.sh
# Menü: Wähle "5) Cleanup Old Backups"
```

## 📋 Command-Line Interface

### Interaktive Menü

```bash
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh"
```

### Einzelne Operationen

```bash
# Backup erstellen (interaktiv)
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh"

# Automatisches Backup aus .backup-config (für Cron)
docker exec db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --auto"

# Automatisches Backup aus einer Container-spezifischen Config
docker exec db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --auto --config /var/lib/db-backup/config/personal-home-portal-db.conf"

# Cron-Job setup
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --setup-cron"

# Cron-Job entfernen
docker exec -it db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --remove-cron"

# Cron-Jobs listen
docker exec db-backup-runner bash -lc \
  "cd /workspace/docker.local-netzwerk && bash scripts/backup_db.sh --list-cron"

# Alte Backups löschen
bash scripts/backup_db.sh --cleanup 30

# Alle Backups anzeigen
bash scripts/backup_db.sh --list

# Hilfe anzeigen
bash scripts/backup_db.sh --help
```

## 📊 Backup-Log prüfen

```bash
# Letzten 50 Log-Einträge
tail -50 backups/backup.log

# Nur Fehler
grep ERROR backups/backup.log

# Backups der letzten 24 Stunden
grep "$(date +%Y-%m-%d)" backups/backup.log

# Im Script-Menü
bash scripts/backup_db.sh
# Menü: Wähle "6) View Backup Log"
```

## 🗂️ Backup-Dateien

### Dateinamenformat

```
backup_[DATENBANKNAME]_[YYYYMMDD]_[HHMMSS].zip
```

### Beispiele

```
backup_planka_20260816_120000.zip        # Planka-Datenbank am 16.08.2026 12:00:00
backup_roundcube_20260816_020000.zip     # Roundcube-Datenbank am 16.08.2026 02:00:00
backup_mydb_20260815_180030.zip          # Eigene DB am 15.08.2026 18:00:30
```

### Backup-Inhalt

Jedes ZIP-Archiv enthält ein SQL-Dump der Datenbank:
- Vollständiger SQL-Dump (alle Tabellen, Daten, Indizes)
- Komprimiert mit ZIP (platzsparend)
- Selbständig erstellbar mit Standard-Tools (`pg_dump`, `mysqldump`, `unzip`)

### Backup wiederherstellen

#### PostgreSQL

```bash
# ZIP extrahieren
unzip backup_planka_20260816_120000.zip

# Datenbank erstellen (falls noch nicht vorhanden)
docker exec -it planka-db createdb -U planka planka_restored

# Backup wiederherstellen
docker exec -it planka-db psql -U planka -d planka_restored < backup_planka_20260816_120000.sql

# Optional: Alte DB ersetzen (Vorsicht!)
docker exec -it planka-db dropdb -U planka planka
docker exec -it planka-db createdb -U planka planka
docker exec -it planka-db psql -U planka -d planka < backup_planka_20260816_120000.sql
```

#### MySQL/MariaDB

```bash
# ZIP extrahieren
unzip backup_roundcube_20260816_020000.zip

# Backup wiederherstellen
docker exec -it roundcube-db mysql -u [USER] -p[PASSWORD] [DBNAME] < backup_roundcube_20260816_020000.sql

# Beispiel:
docker exec -it roundcube-db mysql -u roundcube -proundcube-password roundcube < backup_roundcube_20260816_020000.sql
```

## 🔍 Unterstützte Datenbanken

### PostgreSQL

- **Erforderliche Tools**: `pg_dump`, `pg_isready`
- **Standard-Port**: 5432
- **Connection Test**: `pg_isready -h host -p port -U user -d dbname`
- **Dump-Befehl**: `pg_dump -h host -p port -U user -d dbname > backup.sql`

### MySQL / MariaDB

- **Erforderliche Tools**: `mysqldump`, `mysqladmin`
- **Standard-Port**: 3306
- **Connection Test**: `mysqladmin ping -h host -P port -u user -p"password"`
- **Dump-Befehl**: `mysqldump --no-tablespaces -h host -P port -u user -p"password" dbname > backup.sql`

`--no-tablespaces` verhindert, dass für Tablespace-Metadaten das globale `PROCESS`-Recht benötigt wird. Tabellen und Daten werden weiterhin vollständig gesichert.

## 🐳 Docker Integration

Die Scripts arbeiten mit Docker-Containern im `docker_lan_network`:

### PostgreSQL (z.B. Planka)

```bash
# Container identifizieren
docker ps | grep planka-db

# Direkt Backup vom Host
docker exec planka-db pg_dump -U planka planka > backup.sql
```

### MySQL/MariaDB (z.B. Roundcube)

```bash
# Container identifizieren
docker ps | grep roundcube-db

# Direkt Backup vom Host
docker exec roundcube-db mysqldump -u roundcube -p[PASS] roundcube > backup.sql
```

Das Script nutzt Netzwerk-Hostnamen, daher müssen die DB-Container erreichbar sein:
- `planka-db` → PostgreSQL Container Name
- `roundcube-db` → MariaDB Container Name

## ⚠️ Sicherheit & Best Practices

### Datenschutz

1. **Credentials schützen**
   ```bash
   # Cron-Configs haben nur 600 Permissions (nur Besitzer kann lesen)
   ls -l projects/db-backup/config/
   # -rw------- 1 user user ... personal-home-portal-db.conf
   ```

2. **Nicht in Git committen**
   ```bash
   # .gitignore schließt aus:
   .backup-config                 # Legacy-Credentials
   .backup-configs/               # Host-Credentials
   projects/db-backup/config/*    # Runner-Credentials
   backups/                       # Alle Backup-Dateien
   ```

3. **Backup-Speicherung**
   - Backups lokal in `backups/` speichern
   - Optional: Zu externem Storage kopieren (USB, NAS, Cloud)
   - Regelmäßig externe Backups testen

### Backup-Strategie (3-2-1 Rule)

1. **3 Kopien** der Daten (Original + 2 Backups)
2. **2 verschiedene Medien** (lokal + extern)
3. **1 Kopie offsite** (externes Backup-System)

**Implementierung für Docker Local Network:**

```bash
# Local Backup (Script)
bash scripts/backup_db.sh

# Zu NAS/USB kopieren
cp backups/backup_*.zip /mnt/nas/backups/

# Optional: Cloud-Backup
rclone copy backups/ gdrive:backups/
```

### Backup-Tests

Regelmäßig testen, ob Backups wiederherstellbar sind:

```bash
# Monatlicher Test-Plan
# 1. Letztes Backup auswählen
ls -lth backups/backup_*.zip | head -1

# 2. In Test-Container wiederherstellen
# 3. Datenbank prüfen
# 4. Dokumentation aktualisieren
```

## 🐛 Troubleshooting

### "Command not found: pg_dump"

```bash
# PostgreSQL Client installieren (Linux)
sudo apt-get install postgresql-client

# macOS
brew install postgresql

# Falls Docker verwendet: Über Container dumpen
docker exec planka-db pg_dump -U planka planka > backup.sql
```

### "Access denied" Fehler

```bash
# Credentials prüfen
# Sind Benutzername & Passwort korrekt?
docker exec planka-db psql -U planka -d planka -c "SELECT 1;"

# Port korrekt?
docker ps | grep planka-db
docker port planka-db
```

### "Network not found: docker_lan_network"

```bash
# Netzwerk erstellen
docker network create docker_lan_network --driver bridge

# Prüfen
docker network ls | grep docker_lan_network
```

### Cron-Job läuft nicht

```bash
# Log prüfen
grep backup_db /var/log/syslog  # Linux
log stream --predicate 'process == "cron"'  # macOS

# Cron manuell testen
bash scripts/backup_db.sh --auto

# Cron-Job prüfen
crontab -l | grep backup_db
```

## 📚 Weitere Ressourcen

- [PostgreSQL pg_dump Docs](https://www.postgresql.org/docs/current/app-pgdump.html)
- [MySQL mysqldump Docs](https://dev.mysql.com/doc/refman/8.0/en/mysqldump.html)
- [Cron Syntax](https://crontab.guru/)
- [ZIP Format](https://en.wikipedia.org/wiki/ZIP_(file_format))

---

**Version**: 1.0  
**Zuletzt aktualisiert**: 2026-08-16  
**Backup Script Version**: 1.0
