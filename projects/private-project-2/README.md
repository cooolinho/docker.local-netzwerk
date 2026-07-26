# 🔧 Private Projekt 2

Beschreibung deines Projekts.

## 🔗 Links

- **Domain**: `http://private-project-2.docker.local`
- **Port**: `3000` (intern)
- **Repository**: [Link zum Repo]
- **Dokumentation**: [Link zur Doku]

## ⚙️ Konfiguration

### Umgebungsvariablen

Bearbeite `docker-compose.yml` und füge folgende Variablen hinzu:

```yaml
environment:
  - VAR_NAME=value
  - DEBUG=false
```

### Abhängigkeiten

- Docker
- Optional: [andere Services]

## 🚀 Starten

```bash
cd projects/private-project-2
docker-compose up -d

# Logs
docker-compose logs -f
```

## 📖 Verwenden

1. Öffne `http://private-project-2.docker.local`
2. [Deine Verwendungsanleitung hier]

## 📦 Storage

| Typ | Mount | Zweck |
|-----|-------|-------|
| Volume | `./data` | Persistente Daten |
| Config | `./config` | Konfigurationsdateien |

## 🐛 Troubleshooting

### Problem: Container startet nicht

```bash
docker-compose logs
```

### Problem: Verbindung verweigert

```bash
# Traefik Logs prüfen
docker-compose -f ../../docker-compose.yml logs traefik

# Port korrekt in Labels?
docker-compose config | grep loadbalancer.server.port
```

## 🔄 Updates

```bash
# Image updaten
docker-compose pull

# Neu starten
docker-compose down
docker-compose up -d
```

## 📝 Notizen

- [Notizen zu diesem Projekt]

---

Zuletzt aktualisiert: 2024-07-26

