# Buzz AI Agent (CCF-001) Setup & OpenRouter Integration Guide

This workspace is configured to run the **Buzz AI Agent** (`CCF-001`) using the **`buzz-acp`** harness and **Claude Code**, routing LLM completion requests to **OpenRouter** (including free router endpoints).

---

## 1. System Architecture

```
                               ┌─────────────────────────────┐
                               │     Buzz Community Relay    │
                               └──────────────┬──────────────┘
                                              │ (Nostr Protocol signed with `nsec`)
                                              ▼
┌──────────────────────────┐       ┌─────────────────────────┐
│   OpenRouter API Gateway ◄───────┤        buzz-acp         │
│ (https://openrouter.ai)  │ (LLM) │   (Claude Code Harness) │
└──────────────────────────┘       └─────────────────────────┘
```

- **Identity Layer**: `buzz-acp` authenticates agent `CCF-001` with `BUZZ_PRIVATE_KEY` (`nsec1...`).
- **LLM Provider Layer**: Claude Code is instructed via `ANTHROPIC_BASE_URL` to send API completion queries to OpenRouter instead of Anthropic directly.

---

## 2. Saved Files & Credentials

| File Path | Description |
| :--- | :--- |
| [`.env.buzz`](file:///Users/bobbyinthelobby/{art/.env.buzz) | Workspace environment variables (git-ignored) |
| [`start-buzz-agent.sh`](file:///Users/bobbyinthelobby/{art/start-buzz-agent.sh) | Executable launch script for CCF-001 |
| [`~/.buzz/CCF-001.env`](file:///Users/bobbyinthelobby/.buzz/CCF-001.env) | Global user home configuration |
| [`BUZZ_AGENT_SETUP.md`](file:///Users/bobbyinthelobby/{art/BUZZ_AGENT_SETUP.md) | This setup & architecture documentation |

---

## 3. Environment Variables Reference

```bash
# Buzz Identity
BUZZ_AGENT_ID="CCF-001"
BUZZ_PRIVATE_KEY="nsec1xw7jxs4qssgtd654rdgts45xmmef6kq284xyzz4fjk73lkjvqrgs5f8jzu"

# OpenRouter Endpoint
ANTHROPIC_BASE_URL="https://openrouter.ai/api"
ANTHROPIC_AUTH_TOKEN="sk-or-v1-YOUR-OPENROUTER-KEY"
ANTHROPIC_API_KEY=""  # MUST remain empty string

# OpenRouter Free Router / Model Slugs
ANTHROPIC_DEFAULT_SONNET_MODEL="openrouter/auto"
ANTHROPIC_DEFAULT_HAIKU_MODEL="meta-llama/llama-3.3-70b-instruct:free"
```

---

## 4. How to Launch the Agent

1. Add your OpenRouter API Key (`sk-or-v1-...`) inside [`.env.buzz`](file:///Users/bobbyinthelobby/{art/.env.buzz).
2. Run the executable start script:

```bash
./start-buzz-agent.sh
```

---

## 5. Key Troubleshooting Tips

- **Direct Anthropic Fallback Issue**: If Claude Code connects directly to Anthropic, ensure `export ANTHROPIC_API_KEY=""` is set to an empty string.
- **Relay Authentication**: If `buzz-acp` reports an identity failure, check that `BUZZ_PRIVATE_KEY` starts with `nsec1...`.
- **Free Router Rate Limits**: On OpenRouter free models, fallback slugs like `openrouter/auto` will automatically route to available free endpoints.
