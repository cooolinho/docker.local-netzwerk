# 🏠 Dashy - Personal Dashboard

Lissy93's Dashy ist ein customisierbares, modernes Personal Dashboard für Bookmarks und Quick-Zugriffe.

## 🔗 Links

- **Domain**: `http://dashy.docker.local`
- **Image**: `lissy93/dashy`
- **GitHub**: https://github.com/lissy93/dashy
- **Docs**: https://dashy.to/docs

## ⚙️ Konfiguration

### Umgebungsvariablen

Alle wichtigen Variablen sind in `docker-compose.yml` gesetzt. Keine .env Datei nötig.

### conf.yml bearbeiten

Die Konfiguration steht in `conf.yml`. Diese Datei wird in den Container gemountet und kann dort bearbeitet werden.

Beispiele:
- `pageTitle`: Titel des Dashboards
- `sections`: Kategorien von Links
- `items`: Die einzelnen Links/Shortcuts

## 🚀 Starten

```bash
cd projects/dashy
docker-compose up -d

# Logs
docker-compose logs -f dashy
```

## 📖 Verwenden

1. Öffne `http://dashy.docker.local`
2. Bearbeite `conf.yml` um Links hinzuzufügen
3. Browser neu laden oder Container neu starten

## 🎨 Customization

Siehe `conf.yml` für alle Optionen:
- Themes
- Layouts
- Icons
- Custom CSS

## 🐛 Troubleshooting

**Dashy zeigt weiße Seite?**
```bash
docker-compose logs dashy | grep -i error
```

**Änderungen in conf.yml nicht sichtbar?**
```bash
docker-compose restart dashy
```

**Container startet nicht?**
```bash
docker-compose up dashy  # Ohne -d für Live-Logs
```

## 📦 Storage

- **Volume**: `dashy-data` für Icons
- **Konfiguration**: `conf.yml` (im Repo)

Keine Datenbankabhängigkeiten.

---

Zuletzt aktualisiert: 2024-07-26

