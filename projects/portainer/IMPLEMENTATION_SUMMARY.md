# 🐋 Portainer Update/Rollback - Implementation Summary

## 📋 Überblick

Das Update-System für Portainer bietet sichere und einfache Möglichkeiten zum Aktualisieren und Zurückrollen von Portainer-Versionen mit integrierten Backup- und Fehlerbehandlungsmechanismen.

---

## 📦 Neue Dateien

### 1. **update.sh** - Hauptes Update-Script
**Pfad**: `projects/portainer/update.sh`

**Features**:
- ✅ Neueste Version installieren (`./update.sh`)
- ✅ Spezifische Version installieren (`./update.sh 2.18.3`)
- ✅ Optionales Backup vor Update (`./update.sh --backup`)
- ✅ Kombinierbar (`./update.sh 2.18.3 --backup`)
- ✅ Interaktive Bestätigung
- ✅ Farbliche Ausgabe mit Fortschrittsanzeige
- ✅ Fehlerbehandlung (`set -e`)
- ✅ Automatische Logs nach Update

**Verwendung**:
```bash
cd projects/portainer
chmod +x update.sh
./update.sh                  # Neueste Version
./update.sh 2.18.3          # Spezifische Version
./update.sh --backup        # Mit Backup
./update.sh --help          # Hilfe anzeigen
```

---

### 2. **rollback.sh** - Rollback/Wiederherstellung-Script
**Pfad**: `projects/portainer/rollback.sh`

**Features**:
- ✅ Neuestes Backup automatisch verwenden (`./rollback.sh --latest`)
- ✅ Spezifisches Backup wählen (`./rollback.sh backup-name`)
- ✅ Verfügbare Backups auflisten (`./rollback.sh --list`)
- ✅ Flexible Eingabe (mit/ohne .tar.gz, mit/ohne Pfad)
- ✅ Interaktive Bestätigung vor Restore
- ✅ Automatischer Container-Neustart

**Verwendung**:
```bash
cd projects/portainer
chmod +x rollback.sh
./rollback.sh --latest                                  # Neuestes Backup
./rollback.sh --list                                    # Backups anzeigen
./rollback.sh portainer-backup-20240726_143022         # Spezifisches Backup
./rollback.sh portainer-backup-20240726_143022.tar.gz  # Mit Dateityp
```

---

### 3. **.gitignore** - Git-Ignore für Backups
**Pfad**: `projects/portainer/.gitignore`

**Inhalt**:
```
backups/
*.tar.gz
.env.local
```

**Zweck**:
- Verhindert, dass Backup-Dateien ins Repository gepusht werden
- Hält das Repository schlank
- Schützt möglicherweise sensitive Daten

---

### 4. **UPDATE-GUIDE.md** - Dokumentation & Schnellreferenz
**Pfad**: `projects/portainer/UPDATE-GUIDE.md`

**Inhalte**:
- 📖 Schnellstart
- 🎯 4 Häufige Update-Szenarien mit Beispielen
- 🐛 Troubleshooting-Lösungen
- ✅ Best Practices
- 🔗 Versionsquellen
- 💬 Support-Links

---

## 📝 Aktualisierte Dateien

### 1. **README.md** - Portainer Dokumentation
**Änderungen**:

#### 🔄 Update-Abschnitt
- Neu: Empfehlung für `update.sh` (primär)
- Manuelles Update als Alternative
- Links zu verfügbaren Versionen

#### 🔄 Backup & Restore-Abschnitt (erweitert)
- Mit Update-Script (neu)
- Manuelles Backup
- Restore-Optionen (mit Rollback-Script)
- Automatische Backups via Cron-Job (neu)
- Automatische Bereinigung alter Backups (neu)

#### 🐛 Troubleshooting-Abschnitt (ergänzt)
- Rollback-Hinweis bei Container-Crashes (neu)

---

## 🎯 Funktionalität

### Update-Flow

```
┌─────────────────────────────────────────────┐
│ 1. Argument-Verarbeitung                    │
│    (Version, --backup, --help)              │
└────────────────┬────────────────────────────┘
                 │
┌────────────────▼────────────────────────────┐
│ 2. Bestätigung & Info-Anzeige               │
│    (Benutzer bestätigt Aktion)              │
└────────────────┬────────────────────────────┘
                 │
        ┌────────┴────────┐
        │                 │
   Backup=true       Backup=false
        │                 │
┌───────▼──────────┐  ┌────▼──────────────┐
│ Backup erstellen │  │ Überspringe       │
│ (Volume export)  │  │ Backup            │
└────────┬─────────┘  └────────┬──────────┘
         │                     │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ Image pullen        │
         │ (docker pull)       │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ Container stoppen   │
         │ (docker-compose     │
         │  down)              │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ Container starten   │
         │ (docker-compose     │
         │  up -d)             │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ Logs anzeigen       │
         │ (30 Sekunden)       │
         └──────────┬──────────┘
                    │
         ┌──────────▼──────────┐
         │ ✓ Fertig            │
         └─────────────────────┘
```

### Backup-Speicherort

```
projects/portainer/
├── docker-compose.yml
├── update.sh
├── rollback.sh
├── README.md
├── UPDATE-GUIDE.md
├── .gitignore
└── backups/                    # Neu!
    ├── portainer-backup-20240726_143022.tar.gz
    ├── portainer-backup-20240726_150045.tar.gz
    └── portainer-backup-20240727_120000.tar.gz
```

---

## 🚀 Verwendungsbeispiele

### Einfaches Update
```bash
cd projects/portainer
./update.sh
# Folge den Anweisungen
```

### Update mit Backup für Production
```bash
cd projects/portainer
./update.sh --backup
# Backup wird automatisch erstellt
```

### Update zu spezifischer Version
```bash
cd projects/portainer
./update.sh 2.17.1 --backup
```

### Schneller Rollback nach Fehler
```bash
cd projects/portainer
./rollback.sh --latest
# Stellt letztes Backup wieder her
```

### Automatische täglich Updates via Cron
```bash
# Crontab öffnen
crontab -e

# Hinzufügen (tägliches Update um 2:00 Uhr)
0 2 * * * cd /path/to/projects/portainer && ./update.sh --backup > /var/log/portainer-update.log 2>&1
```

---

## ✅ Überprüfung & Tests

### Script-Syntax ✓
- `bash -n update.sh` → OK
- `bash -n rollback.sh` → OK

### Help-Funktionen ✓
- `./update.sh --help` → Zeigt Hilfe
- `./rollback.sh --help` → Zeigt Hilfe

### Fehlerbehandlung ✓
- `set -e` in beiden Scripts
- Interaktive Bestätigung
- Klare Fehlermeldungen

---

## 🔒 Sicherheit & Best Practices

### ✅ Implementiert
1. **Backup vor Update** - Optional mit `--backup`
2. **Versionskontrolle** - Kann zu beliebiger Version aktualisieren
3. **Fehlerbehandlung** - Script bricht bei Fehlern ab (`set -e`)
4. **Rollback-Mechanismus** - Schnelle Wiederherstellung möglich
5. **.gitignore** - Backups/Archives nicht im Git
6. **Interaktive Bestätigung** - Benutzer must Aktion bestätigen
7. **Klare Logging** - Farbige Ausgabe mit Fortschritt

### 📋 Empfehlungen
- Regelmäßig Backups mit `--backup` erstellen
- Alte Backups >30 Tage löschen (Script vorhanden)
- Version vor Major-Updates testen
- Updates zu off-peak-Zeiten durchführen
- Nach Update Web-UI überprüfen

---

## 📚 Dokumentation

### Verfügbare Dokumentation
1. **README.md** - Hauptdokumentation (aktualisiert)
2. **UPDATE-GUIDE.md** - Schnellreferenz & Szenarien
3. **update.sh --help** - Script-Hilfe
4. **rollback.sh --help** - Rollback-Hilfe

### Externe Links
- Docker Hub Versionen: https://hub.docker.com/r/portainer/portainer-ce/tags
- Portainer Docs: https://docs.portainer.io

---

## 🎓 Integrations-Tipps

### Mit anderen Infrastruktur-Scripts
Das Update-System lässt sich einfach in bestehende Skripte integrieren:

```bash
# In start-all.sh oder monitoring-scripts aufrufen:
if [ "$AUTO_UPDATE" = "true" ]; then
    projects/portainer/update.sh --backup
fi
```

### Mit Monitoring-Systemen
Status-Monitoring möglich:

```bash
# Aktuelle Portainer-Version abrufen
docker ps --filter "name=portainer" \
  --format "{{.Image}}"

# Logs für externe Monitoring-Tools
docker-compose -f projects/portainer/docker-compose.yml logs | tail -100
```

---

## 🐛 Häufige Fehler & Lösungen

| Fehler | Lösung |
|--------|---------|
| `permission denied` | `chmod +x update.sh rollback.sh` |
| `docker: command not found` | Docker im PATH installieren/hinzufügen |
| `Cannot connect to Docker daemon` | Docker-Daemon starten |
| Backup zu groß | Alte Backups mit `find ... -delete` löschen |
| Restore schlägt fehl | Mit `rollback.sh --list` verfügbare Backups prüfen |

---

## 📊 Größenangaben

| Item | Größe | Hinweis |
|------|-------|---------|
| Portainer Image | ~500MB | Variiert je nach Version |
| Backup (typisch) | ~50-200MB | Abhängig von Portainer-Daten |
| update.sh Script | ~6KB | Kompakt |
| rollback.sh Script | ~5KB | Kompakt |

---

## 🔄 Versionsverlauf

| Version | Datum | Änderungen |
|---------|-------|-----------|
| 1.0 | 2026-08-16 | Initial Implementation |

---

## 👥 Support & Rollen

Nach **AGENTS.md**:
- **Project Manager**: Verantwortlich für Updates
- **Infrastructure Agent**: Supports Updates bei Infrastruktur-Issues
- **Backup-Verwaltung**: Security Agent

---

**Zuletzt aktualisiert**: 2026-08-16  
**Status**: ✅ Vollständig implementiert  
**Getestet**: Bash-Syntax ✓, Help-Funktionen ✓

