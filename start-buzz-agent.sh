#!/usr/bin/env bash
# ==============================================================================
# Buzz AI Agent Launcher (CCF-001)
# ==============================================================================
# Harness: buzz-acp + Claude Code
# LLM Endpoint: OpenRouter (Free Router Models)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="${SCRIPT_DIR}/.env.buzz"

if [ -f "$ENV_FILE" ]; then
    echo "Loading environment from .env.buzz..."
    set -a
    source "$ENV_FILE"
    set +a
else
    echo "Error: .env.buzz file not found at ${ENV_FILE}"
    exit 1
fi

echo "--------------------------------------------------------"
echo "Initializing Buzz AI Agent CCF-001..."
echo "Identity (Nostr): ${BUZZ_AGENT_ID}"
echo "LLM Base URL:    ${ANTHROPIC_BASE_URL:-http://localhost:20128/v1}"
echo "Model Override:  ${ANTHROPIC_DEFAULT_SONNET_MODEL:-auto/best-free}"
echo "--------------------------------------------------------"

# Ensure OmniRoute server daemon is running
if ! lsof -i:20128 &> /dev/null; then
    echo "Starting local OmniRoute proxy daemon..."
    if command -v omniroute &> /dev/null; then
        omniroute serve --daemon
    elif [ -f "/Users/bobbyinthelobby/.hermes/node/bin/omniroute" ]; then
        /Users/bobbyinthelobby/.hermes/node/bin/omniroute serve --daemon
    fi
fi

# Validation
if [ -z "$BUZZ_PRIVATE_KEY" ]; then
    echo "Error: BUZZ_PRIVATE_KEY is not set in .env.buzz!"
    exit 1
fi

if [ -z "$ANTHROPIC_API_KEY" ]; then
    echo "Warning: ANTHROPIC_API_KEY is not set in .env.buzz."
    echo "Please set your OpenRouter API key (sk-or-v1-...) in .env.buzz for OpenRouter access."
fi

# Ensure ANTHROPIC_API_KEY is exported and ANTHROPIC_AUTH_TOKEN is unset to avoid duplicate auth warnings
export ANTHROPIC_API_KEY="${ANTHROPIC_API_KEY}"
unset ANTHROPIC_AUTH_TOKEN

echo "Starting buzz-acp harness with Claude Code..."
if command -v buzz-acp &> /dev/null; then
    exec buzz-acp --harness claude-code "$@"
elif command -v npx &> /dev/null; then
    exec npx -y @block/buzz-acp --harness claude-code "$@"
else
    echo "Error: Neither buzz-acp nor npx is installed on PATH."
    exit 1
fi
