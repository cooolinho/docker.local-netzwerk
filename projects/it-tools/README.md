# 🛠️ IT-Tools - IT Utility Collection

IT-Tools ist eine kostenlose, open-source Sammlung von nützlichen Tools für IT-Profis.

## 🔗 Links

- **Domain**: `http://it-tools.docker.lan`
- **Image**: `corentinth/it-tools`
- **GitHub**: https://github.com/CorentinTh/it-tools
- **Docs**: https://it-tools.tech

## 📋 Enthaltene Tools

- Base64 Encoder/Decoder
- Hash Generator (MD5, SHA, etc.)
- JSON Formatter
- Regular Expression Tester
- IP Utilities
- UUID Generator
- Text Tools
- Und viele mehr...

## ⚙️ Konfiguration

Keine spezielle Konfiguration nötig. Der Container läuft mit Standard-Einstellungen.

## 🚀 Starten

```bash
cd projects/it-tools
docker-compose up -d

# Logs
docker-compose logs -f it-tools
```

## 📖 Verwenden

1. Öffne `http://it-tools.docker.lan`
2. Wähle ein Tool aus der Sidebar
3. Nutze das Tool

Alle Tools laufen clientseitig - keine Daten verlassen deinen Host.

## 🐛 Troubleshooting

**Tools laden nicht?**
```bash
docker-compose logs it-tools | grep -i error
```

**Seite lädt sehr langsam?**
- Überprüfe Browser-Cache
- Versuche Incognito-Fenster
- Container-Logs prüfen

## 📦 Storage

- **Keine Volumes**: IT-Tools speichert keine Daten persistent
- **Keine Datenbank**: Rein statische Website

---

Zuletzt aktualisiert: 2024-07-26

