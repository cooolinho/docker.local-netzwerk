# 🔀 OmniRoute - Universal AI Gateway & LLM Proxy

OmniRoute ist ein universelles, selbstgehostetes AI Gateway und Proxy für Large Language Models (LLMs). Es bietet standardisierte Schnittstellen für Anthropic-, OpenAI- und viele weitere AI-Provider (OpenRouter, DeepSeek, Ollama, Google Gemini, Groq, Mistral etc.).

In dieser Docker-Umgebung läuft OmniRoute integriert im lokalen Netzwerk (`docker.lan`) hinter Traefik als Reverse Proxy.

---

## 📋 Inhalt

- [Überblick & Features](#-überblick--features)
- [Links & Endpunkte](#-links--endpunkte)
- [Architektur & Traefik-Integration](#-architektur--traefik-integration)
- [Schritt-für-Schritt Ersteinrichtung](#-schritt-für-schritt-ersteinrichtung)
- [Konfiguration für Claude](#-konfiguration-für-claude)
  - [Claude Code CLI](#claude-code-cli)
  - [Anthropic Python SDK](#anthropic-python-sdk)
  - [Anthropic TypeScript / Node.js SDK](#anthropic-typescript--nodejs-sdk)
- [Konfiguration für Codex & OpenAI-kompatible Tools](#-konfiguration-für-codex--openai-kompatible-tools)
  - [Codex CLI & Umgebungsvariablen](#codex-cli--umgebungsvariablen)
  - [OpenAI Python SDK](#openai-python-sdk)
  - [OpenAI Node.js / TypeScript SDK](#openai-nodejs--typescript-sdk)
  - [IDE-Plugins (Continue.dev, Cursor, Cline, Aider)](#ide-plugins-continuedev-cursor-cline-aider)
- [Testaufrufe mit cURL](#-testaufrufe-mit-curl)
- [Troubleshooting & Wartung](#-troubleshooting--wartung)

---

## 🎯 Überblick & Features

- **Multi-Provider Routing**: Verbindet Anthropic, OpenAI, DeepSeek, OpenRouter, Google, Groq und lokale LLMs (z. B. Ollama).
- **Einheitliche APIs**:
  - Anthropic-kompatibel: `/v1/messages`
  - OpenAI-kompatibel: `/v1/chat/completions`, `/v1/models`, `/v1/embeddings`
- **Fallback & Load Balancing**: Automatisches Umschalten auf Backup-Provider bei Rate Limits oder API-Ausfällen.
- **Token- & Kosten-Tracking**: Echtzeit-Überwachung von Token-Verbrauch und Kosten je API-Key und Modell.
- **Caching & Rate Limiting**: Reduziert Latenzen und verhindert unerwartete Kostenexplosionen.
- **Web Dashboard**: Verwaltung von Providern, Routing-Regeln und Keys über eine moderne Oberfläche.

---

## 🔗 Links & Endpunkte

| Dienst / Schnittstelle | URL / Endpunkt | Beschreibung |
|------------------------|----------------|--------------|
| **Web Dashboard** | `http://omniroute.docker.lan` | Management UI (Provider, Keys, Logs) |
| **Direktzugriff (Port)** | `http://<host-ip>:20128` | Direkter Host-Port (Fallback/Debugging) |
| **OpenAI Base URL** | `http://omniroute.docker.lan/v1` | Endpunkt für OpenAI-kompatible Clients |
| **Anthropic Base URL** | `http://omniroute.docker.lan/v1` | Endpunkt für Anthropic SDKs & Claude Code |
| **Live WebSocket** | `ws://omniroute.docker.lan/live-ws` | Dashboard Echtzeit-Events |

---

## 🏗️ Architektur & Traefik-Integration

OmniRoute ist an das zentrale externe Docker-Netzwerk `docker_lan_network` angebunden und wird über Traefik dynamisch geroutet:

```text
┌────────────────────────────────────────────────────────┐
│ Client (Claude Code, Codex, Cursor, Python SDK, etc.)   │
└───────────────────────────┬────────────────────────────┘
                            │ HTTP / WebSocket
                            ▼
┌────────────────────────────────────────────────────────┐
│ Traefik Reverse Proxy (http://omniroute.docker.lan:80) │
└───────────────────────────┬────────────────────────────┘
                            │ docker_lan_network
                            ▼
┌────────────────────────────────────────────────────────┐
│ OmniRoute Container (:20128)                           │
│  ├─ Web Dashboard & Key Management                     │
│  ├─ OpenAI / Anthropic API Translation Layer           │
│  └─ Persistentes Volume: omniroute-data (/app/data)    │
└───────────────┬────────────────────────┬───────────────┘
                │                        │
     ┌──────────▼──────────┐   ┌─────────▼─────────┐
     │ Upstream Cloud APIs │   │ Lokales Ollama    │
     │ (Anthropic, OpenAI) │   │ (http://ollama)   │
     └─────────────────────┘   └───────────────────┘
```

---

## 🚀 Schritt-für-Schritt Ersteinrichtung

### 1. In das Projektverzeichnis wechseln

```bash
cd projects/omni-route
```

### 2. `.env` aus der Vorlage erstellen

```bash
cp .env.example .env
```

### 3. Sicherheits-Schlüssel generieren und in `.env` eintragen

Generiere sichere Zufallsschlüssel:

```bash
# JWT Secret (Authentifizierung)
openssl rand -base64 48

# API Key Secret (Verschlüsselung der Provider-Keys)
openssl rand -hex 32

# Initiales Admin-Passwort
openssl rand -base64 16
```

Öffne die `.env` Datei und trage die erzeugten Werte ein:

```env
JWT_SECRET=dein_generiertes_jwt_secret
API_KEY_SECRET=dein_generiertes_api_key_secret
INITIAL_PASSWORD=dein_sicheres_admin_passwort

# Domain-Konfiguration (bereits vorkonfiguriert)
BASE_URL=http://omniroute.docker.lan
NEXT_PUBLIC_BASE_URL=http://omniroute.docker.lan
LIVE_WS_ALLOWED_ORIGINS=http://omniroute.docker.lan,http://localhost:20128
```

### 4. Container starten

```bash
docker compose up -d
```

Überprüfe den Status des Containers:

```bash
docker compose ps
docker compose logs -f omniroute
```

### 5. Web-Dashboard aufrufen & einloggen

1. Öffne im Browser: **`http://omniroute.docker.lan`**
2. Melde dich mit deinem `INITIAL_PASSWORD` an.
3. Ändere im Profil bei Bedarf direkt dein Passwort.

### 6. AI-Provider hinzufügen

Navigiere im Dashboard zu **Providers** und hinterlege deine Upstream-Zugangsdaten:
- **Anthropic**: Trage deinen offiziellen Anthropic API-Key (`sk-ant-...`) ein.
- **OpenAI**: Trage deinen OpenAI API-Key (`sk-...`) ein.
- **OpenRouter / DeepSeek / Groq**: API-Keys für alternative Anbieter.
- **Lokale Modelle (Ollama)**: Trage `http://<ollama-ip>:11434` als Custom Provider ein.

### 7. OmniRoute API-Key für Clients erstellen

1. Gehe im Dashboard auf **API Keys** -> **Create New Key**.
2. Vergib einen Namen (z. B. `claude-code-dev` oder `codex-cli`).
3. Kopiere den generierten Schlüssel (z. B. `sk-omniroute-abc123xyz...`). Dieser Schlüssel wird für alle lokalen Tools genutzt.

---

## 🤖 Konfiguration für Claude

OmniRoute stellt einen vollständig Anthropic-kompatiblen Endpunkt bereit. Alle Anfragen an `/v1/messages` werden transparent weitergeleitet und verarbeitet.

### Claude Code CLI

Für das offizielle **Claude Code CLI** genügen zwei Umgebungsvariablen:

#### Einmalig / In der aktuellen Terminal-Sitzung:

```bash
export ANTHROPIC_BASE_URL="http://omniroute.docker.lan/v1"
export ANTHROPIC_API_KEY="sk-omniroute-DEIN_KEY"
```

#### Dauerhaft in der Shell (`~/.bashrc` oder `~/.zshrc`):

```bash
echo 'export ANTHROPIC_BASE_URL="http://omniroute.docker.lan/v1"' >> ~/.bashrc
echo 'export ANTHROPIC_API_KEY="sk-omniroute-DEIN_KEY"' >> ~/.bashrc
source ~/.bashrc
```

#### In `~/.claude/settings.json`:

Falls du Claude Code über eine zentrale Konfigurationsdatei steuern möchtest:

```json
{
  "env": {
    "ANTHROPIC_BASE_URL": "http://omniroute.docker.lan/v1",
    "ANTHROPIC_API_KEY": "sk-omniroute-DEIN_KEY"
  }
}
```

---

### Anthropic Python SDK

```python
from anthropic import Anthropic

client = Anthropic(
    base_url="http://omniroute.docker.lan/v1",
    api_key="sk-omniroute-DEIN_KEY",
)

response = client.messages.create(
    model="claude-3-7-sonnet-20250219",  # oder konfiguriertes Modell / Alias in OmniRoute
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Hallo! Antworte kurz: Funktioniert OmniRoute?"}
    ],
)

print(response.content[0].text)
```

---

### Anthropic TypeScript / Node.js SDK

```typescript
import Anthropic from '@anthropic-ai/sdk';

const anthropic = new Anthropic({
  baseURL: 'http://omniroute.docker.lan/v1',
  apiKey: 'sk-omniroute-DEIN_KEY',
});

async function main() {
  const message = await anthropic.messages.create({
    model: 'claude-3-7-sonnet-20250219',
    max_tokens: 1024,
    messages: [
      { role: 'user', content: 'Hallo via TypeScript SDK und OmniRoute!' }
    ],
  });

  console.log(message.content[0].text);
}

main();
```

---

## ⚡ Konfiguration für Codex & OpenAI-kompatible Tools

OmniRoute stellt Standard-Endpunkte (`/v1/chat/completions`, `/v1/models`, `/v1/embeddings`) für das OpenAI-Protokoll bereit. Dadurch lassen sich fast alle modernen Developer-Tools problemlos anbinden.

### Codex CLI & Umgebungsvariablen

Für CLI-Tools, Scripts oder das Codex-Ökosystem setzt du standardmäßig:

```bash
export OPENAI_BASE_URL="http://omniroute.docker.lan/v1"
export OPENAI_API_KEY="sk-omniroute-DEIN_KEY"
```

Dauerhaft in `~/.bashrc`:

```bash
echo 'export OPENAI_BASE_URL="http://omniroute.docker.lan/v1"' >> ~/.bashrc
echo 'export OPENAI_API_KEY="sk-omniroute-DEIN_KEY"' >> ~/.bashrc
source ~/.bashrc
```

---

### OpenAI Python SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://omniroute.docker.lan/v1",
    api_key="sk-omniroute-DEIN_KEY",
)

response = client.chat.completions.create(
    model="gpt-4o",  # Unterstützt auch 'claude-3-7-sonnet' oder gemappte Aliase
    messages=[
        {"role": "system", "content": "Du bist ein hilfreicher Assistent."},
        {"role": "user", "content": "Erkläre kurz, was ein AI Gateway macht."},
    ],
)

print(response.choices[0].message.content)
```

---

### OpenAI Node.js / TypeScript SDK

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({
  baseURL: 'http://omniroute.docker.lan/v1',
  apiKey: 'sk-omniroute-DEIN_KEY',
});

async function main() {
  const completion = await openai.chat.completions.create({
    model: 'gpt-4o',
    messages: [{ role: 'user', content: 'Testnachricht an OmniRoute' }],
  });

  console.log(completion.choices[0].message.content);
}

main();
```

---

### IDE-Plugins (Continue.dev, Cursor, Cline, Aider)

#### 1. Continue.dev (`~/.continue/config.json`)

```json
{
  "models": [
    {
      "title": "Claude 3.7 Sonnet (OmniRoute)",
      "provider": "openai",
      "model": "claude-3-7-sonnet",
      "apiBase": "http://omniroute.docker.lan/v1",
      "apiKey": "sk-omniroute-DEIN_KEY"
    },
    {
      "title": "GPT-4o (OmniRoute)",
      "provider": "openai",
      "model": "gpt-4o",
      "apiBase": "http://omniroute.docker.lan/v1",
      "apiKey": "sk-omniroute-DEIN_KEY"
    }
  ]
}
```

#### 2. Aider CLI

```bash
export OPENAI_API_BASE="http://omniroute.docker.lan/v1"
export OPENAI_API_KEY="sk-omniroute-DEIN_KEY"

# Starten mit beliebigem in OmniRoute definiertem Modell
aider --model openai/claude-3-7-sonnet
```

#### 3. Cursor & Cline / Roo Code

- **Provider**: `OpenAI Compatible`
- **Base URL**: `http://omniroute.docker.lan/v1`
- **API Key**: `sk-omniroute-DEIN_KEY`
- **Model ID**: Modellname entsprechend deiner OmniRoute-Konfiguration (z. B. `gpt-4o`, `claude-3-7-sonnet`, `deepseek-chat`).

---

## 🧪 Testaufrufe mit cURL

Teste deine Verbindung und Konfiguration direkt über das Terminal:

### 1. Verfügbare Modelle auflisten

```bash
curl -s http://omniroute.docker.lan/v1/models \
  -H "Authorization: Bearer sk-omniroute-DEIN_KEY" | jq .
```

### 2. OpenAI Chat-Completion Test

```bash
curl -s http://omniroute.docker.lan/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer sk-omniroute-DEIN_KEY" \
  -d '{
    "model": "gpt-4o",
    "messages": [
      {"role": "user", "content": "Antworte mit 'OK', wenn du erreichbar bist."}
    ]
  }' | jq .
```

### 3. Anthropic Messages Test

```bash
curl -s http://omniroute.docker.lan/v1/messages \
  -H "Content-Type: application/json" \
  -H "x-api-key: sk-omniroute-DEIN_KEY" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-7-sonnet",
    "max_tokens": 50,
    "messages": [
      {"role": "user", "content": "Antworte mit 'OK', wenn du erreichbar bist."}
    ]
  }' | jq .
```

---

## 🔧 Troubleshooting & Wartung

### Container-Logs prüfen

```bash
cd projects/omni-route
docker compose logs -f omniroute
```
Oder direkt im Browser über Dozzle: `http://dozzle.docker.lan`.

### DNS & Traefik-Prüfung

Sollte `omniroute.docker.lan` nicht auflösen:
1. **DNS prüfen**: `nslookup omniroute.docker.lan 192.168.178.6` (oder deine DNS-Server IP).
2. **Traefik Dashboard**: Öffne `http://traefik.docker.lan` und prüfe unter *HTTP Routers*, ob `omniroute@docker` als aktiv und grün gelistet ist.
3. **Direktzugriff testen**: Falls Traefik blockiert, teste den Direktport `http://<docker-host-ip>:20128`.

### Daten-Backup

Alle Konfigurationen, Keys und Logs liegen im Docker-Volume `omniroute-data` (`/app/data`).
Zum Sichern des Volumes kann das zentrale Backup-System (`projects/db-backup`) oder ein Dateibackup genutzt werden.
