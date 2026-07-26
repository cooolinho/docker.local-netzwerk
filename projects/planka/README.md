# 📋 Planka - Kanban Board

Planka ist ein self-hosted Kanban-Board ähnlich Trello, perfekt für Team-Zusammenarbeit und Task-Management.

## 🔗 Links

- **Domain**: `http://planka.docker.local`
- **Image**: `ghcr.io/plankanban/planka`
- **GitHub**: https://github.com/plankanban/planka
- **Docs**: https://planka.app

## 📊 Features

- ✅ Kanban Boards mit Spalten und Cards
- ✅ Benutzer & Teams
- ✅ Labels & Zuordnungen
- ✅ Attachments
- ✅ Aktivitäts-Logs
- ✅ PostgreSQL Datenbankverbindung

## ⚙️ Konfiguration

### Umgebungsvariablen

**Wichtige Variablen in `docker-compose.yml`:**

| Variable | Standard | Beschreibung |
|----------|----------|-------------|
| `BASE_URL` | `http://planka.docker.local` | Externe URL |
| `DATABASE_URL` | `postgresql://planka:...` | Datenbankverbindung |
| `SECRET_KEY` | `planka-secret-key-...` | Session Secret |

### Initialisierung

1. Starte den Container
2. Öffne `http://planka.docker.local`
3. Registriere einen Admin-Benutzer (erster Benutzer ist Admin)
4. Erstelle Boards & Listen

## 🚀 Starten

```bash
cd projects/planka
docker-compose up -d

# Logs (besonders erste Starten wichtig)
docker-compose logs -f

# Nach ~10 Sekunden sollte es laufen
docker-compose ps
```

## 📖 Verwenden

1. Öffne `http://planka.docker.local`
2. Melde dich an (erste Benutzer = Admin)
3. Erstelle Workspace → Board → Lists → Cards
4. Lade Teamkollegen ein

## 🗄️ Datenbankverbindung

Planka nutzt PostgreSQL. Die DB läuft als separater Container `planka-db`:

```bash
# In Container gehen
docker exec -it planka-db psql -U planka -d planka

# Tabellen anschauen
\dt
```

## 🔄 Backup

```bash
# Datenbankbackup
docker exec planka-db pg_dump -U planka planka > backup.sql

# Volumes sichern
docker run --rm -v planka-db-data:/data -v "$PWD":/backup \
  alpine tar czf /backup/planka-db-backup.tar.gz /data
```

## 🔑 Sicherheit

⚠️ **Ändere diese Werte in docker-compose.yml:**

```yaml
environment:
  SECRET_KEY: CHANGE_ME              # Session Secret
  POSTGRES_PASSWORD: CHANGE_ME        # DB Password
```

Verwende starke, zufällige Strings:
```bash
openssl rand -base64 32
```

## 🐛 Troubleshooting

**Planka zeigt Fehler beim Start?**
```bash
docker-compose logs planka
docker-compose logs planka-db
```

**Kann keine neue Cards erstellen?**
- Überprüfe DB-Verbindung: `docker exec -it planka-db psql -U planka`
- DB muss laufen: `docker-compose ps`

**Login funktioniert nicht?**
- Überprüfe SECRET_KEY gesetzt?
- DB-Logs anschauen

**Planka ist sehr langsam?**
- Überprüfe DB-Performance
- Container-Ressourcen erhöhen

## 📦 Storage

| Volume | Inhalt | Wichtig |
|--------|--------|---------|
| `planka-db-data` | PostgreSQL Daten | ✅ JA - Backup! |
| `planka-user-avatars` | Benutzer-Avatare | Optional |
| `planka-project-background-images` | Board-Hintergründe | Optional |

## 🔄 Migration

Wenn Planka auf einen anderen Host umzieht:

```bash
# 1. DB exportieren
docker exec planka-db pg_dump -U planka planka > planka-export.sql

# 2. Auf neuem Host importieren
docker exec planka-db psql -U planka planka < planka-export.sql

# 3. Volumes kopieren
# ...
```

---

Zuletzt aktualisiert: 2024-07-26

