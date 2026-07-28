# Ordner-Struktur & Dateiübersicht

## 📁 Gesamte Struktur

```
docker.lan-netzwerk/
├── 📄 README.md                    # Hauptdokumentation
├── 📄 QUICKSTART.md                # 5-Minuten Quick-Start
├── 📄 FAQ.md                       # Häufig gestellte Fragen
├── 📄 DNS_SETUP.md                 # DNS-Konfigurationsanleitung
├── 📄 AGENTS.md                    # Rollen & Verantwortlichkeiten
├── 📄 STRUCTURE.md                 # Diese Datei
├── 📄 .env                         # Umgebungsvariablen
├── 📄 .env.example                 # Template für .env (ohne Secrets)
├── 📄 .gitignore                   # Git-Ignore-Regeln
├── 📄 docker-compose.yml           # Traefik Service
│
├── 📁 traefik/                     # Traefik Reverse Proxy
│   ├── 📄 traefik.yml              # Statische Traefik-Konfiguration
│   ├── 📄 acme.json                # Let's Encrypt Zertifikate
│   └── 📁 config/
│       └── 📄 dynamic.yml          # Dynamische Konfiguration
│
├── 📁 projects/                    # Alle Anwendungen
│   ├── 📁 dashy/
│   │   ├── 📄 docker-compose.yml
│   │   ├── 📄 conf.yml             # Dashy-Konfiguration
│   │   └── 📄 README.md            # Projekt-Dokumentation
│   │
│   ├── 📁 it-tools/
│   │   ├── 📄 docker-compose.yml
│   │   └── 📄 README.md
│   │
│   └── 📁 planka/
│   │   ├── 📄 docker-compose.yml
│   │   ├── 📄 .env.example
│   │   └── 📄 README.md
│
└── 📁 scripts/                     # Hilfsskripte
    ├── 🔧 start-all.sh             # Startet alle Services
    ├── 🔧 stop-all.sh              # Stoppt alle Services
    └── 🔧 status.sh                # Zeigt Status aller Services
```

---

## 📄 Dateibeschreibungen

### 🔝 Root-Ebene Dateien

| Datei | Zweck |
|-------|-------|
| **README.md** | Hauptdokumentation - Setup, Architektur, Verwendung |
| **QUICKSTART.md** | 5-Minuten-Guide zum schnellen Starten |
| **FAQ.md** | Häufig gestellte Fragen & Antworten |
| **DNS_SETUP.md** | Anleitung für DNS-Konfiguration (.docker.lan) |
| **AGENTS.md** | Rollen, Verantwortlichkeiten, Checklisten |
| **STRUCTURE.md** | Diese Datei - Ordnerstruktur-Übersicht |
| **.env** | Umgebungsvariablen (NICHT in Git!) |
| **.env.example** | Template für .env |
| **.gitignore** | Welche Dateien Git ignoriert |
| **docker-compose.yml** | Traefik Service Definition |

### 🏗️ traefik/ Verzeichnis

| Datei | Zweck |
|-------|-------|
| **traefik.yml** | Traefik Konfiguration (EntryPoints, Provider, API, Logging) |
| **acme.json** | Let's Encrypt Zertifikate (wird auto-generiert) |
| **config/dynamic.yml** | Dynamische Konfiguration (Middleware, TLS, Routing) |

### 📦 projects/ Verzeichnis

Jedes Projekt-Verzeichnis (`dashy/`, `it-tools/`, `planka/`, etc.):

| Datei | Zweck |
|-------|-------|
| **docker-compose.yml** | Service Definition mit Traefik Labels |
| **conf.yml** / **.env** | Projekt-spezifische Konfiguration |
| **README.md** | Projekt-Dokumentation |
| **data/** | Persistente Daten (Volume-Mount) |

### 🔧 scripts/ Verzeichnis

| Skript | Zweck |
|--------|-------|
| **start-all.sh** | Startet Traefik + alle Projekt-Services |
| **stop-all.sh** | Stoppt alle Services sauber herunter |
| **status.sh** | Zeigt Status aller Container & Links |

---

## 🚀 Workflows

### Erster Start

```
1. DNS konfigurieren (Hosts-Datei oder DNS-Server)
   └─ DNS_SETUP.md lesen
   
2. Netzwerk erstellen
   └─ docker network create docker_lan_network
   
3. Traefik starten
   └─ docker-compose up -d traefik
   
4. Projekte starten
   └─ bash scripts/start-all.sh
   
5. Testen & Logs prüfen
   └─ http://traefik.docker.lan
```

### Neues Projekt hinzufügen

```
1. Verzeichnis erstellen
   └─ mkdir projects/mein-projekt
   
2. docker-compose.yml kopieren & anpassen
   └─ Basis-Template von anderem Projekt kopieren
   
3. Starten
   └─ cd projects/mein-projekt && docker-compose up -d
   
4. DNS aktualisieren
   └─ Dank AdGuard Wildcard *.docker.lan kein Update nötig! ✅
   
5. Testen
   └─ http://mein-projekt.docker.lan
```

### Troubleshooting

```
1. Status prüfen
   └─ bash scripts/status.sh
   
2. Logs ansehen
   └─ docker-compose logs -f [service]
   
3. In Container gehen
   └─ docker exec -it [container] sh
   
4. Traefik Dashboard nutzen
   └─ http://traefik.docker.lan
   
5. DNS testen
   └─ nslookup mein-projekt.docker.lan
```

---

## 📋 Datei-Abhängigkeiten

```
docker-compose.yml
    └─ .env (Umgebungsvariablen)
    └─ traefik/traefik.yml (Traefik-Konfiguration)

traefik/traefik.yml
    └─ traefik/config/dynamic.yml (optional, dynamische Config)
    └─ traefik/acme.json (SSL-Zertifikate)

projects/*/docker-compose.yml
    └─ .env (globale Variablen)
    └─ projects/*/conf.yml oder .env (Projekt-Variablen)
    └─ traefik-Network (docker_lan_network muss existieren)
```

---

## 🔐 Sicherheit - Welche Dateien gehören in Git?

✅ **In Git committed:**
- README.md, QUICKSTART.md, FAQ.md, DNS_SETUP.md, AGENTS.md
- docker-compose.yml (Template)
- traefik/traefik.yml (Vorlage)
- projects/*/docker-compose.yml (Vorlagen)
- .env.example (ohne Secrets!)
- .gitignore

❌ **NICHT in Git committed:**
- .env (enthält Passwörter!)
- traefik/acme.json (SSL-Zertifikate)
- projects/*/.env (Projekt-Secrets)
- docker-compose.override.yml (lokale Overrides)
- traefik/auth.txt (BasicAuth-Passwörter)
- logs/, data/, volumes/ (Laufzeit-Daten)

---

## 📊 Größe & Wartung

| Bereich | Größe (approx.) | Wartung |
|---------|-----------------|---------|
| Konfiguration | ~50 KB | Monatlich |
| Logs | ~10-50 MB | Wöchentlich |
| Volumes | Variabel | Projekt-abhängig |
| Gesamt (klein) | ~500 MB | Täglich |

---

## 🔄 Versionskontrolle mit Git

**Initialisierung:**
```bash
git init
git add .
git commit -m "Initial Docker Local Network setup"
```

**Wichtige .gitignore-Regeln:**
```gitignore
.env              # Secrets
.env.local
.env.*.local

traefik/acme.json # SSL-Certs
traefik/auth.txt  # Passwörter

data/             # Projekt-Daten
volumes/
logs/
```

---

## 📚 Zusammenhang zwischen Dokumenten

```
START HERE
   │
   ├─ README.md ◄────────────────── Vollständige Doku
   │  │
   │  ├─ QUICKSTART.md ◄─────────── Schneller Einstieg
   │  │
   │  ├─ DNS_SETUP.md ◄───────────── DNS-Probleme
   │  │
   │  ├─ AGENTS.md ◄──────────────── Rollen & Troubleshooting
   │  │
   │  ├─ FAQ.md ◄────────────────── Häufige Fragen
   │  │
   │  └─ STRUCTURE.md ◄────────────── Diese Datei
   │
   └─ Konfigs
      ├─ .env
      ├─ traefik/traefik.yml
      └─ projects/*/docker-compose.yml
```

---

## 🎯 Checkliste für Neubauer

- [ ] README.md gelesen?
- [ ] QUICKSTART.md durchgearbeitet?
- [ ] DNS konfiguriert? (DNS_SETUP.md)
- [ ] Docker Network erstellt?
- [ ] Traefik startet? (docker-compose up -d)
- [ ] Erstes Projekt funktioniert?
- [ ] AGENTS.md für Rollen gelesen?
- [ ] Erste Container erreichbar?

---

**Zuletzt aktualisiert**: 2024-07-26  
**Version**: 1.0

