#!/usr/bin/env bash
set -e

# ==============================================================================
# Entrypoint per Gitea Act Runner (Self-Hosted)
# ==============================================================================

echo "========================================================"
echo "🚀 Avvio Gitea Actions AI Issue Runner..."
echo "========================================================"

if [ -z "$GITEA_INSTANCE_URL" ] || [ -z "$GITEA_RUNNER_REGISTRATION_TOKEN" ]; then
    echo "❌ ERRORE: GITEA_INSTANCE_URL e GITEA_RUNNER_REGISTRATION_TOKEN sono obbligatori!"
    exit 1
fi

GITEA_RUNNER_NAME="${GITEA_RUNNER_NAME:-$(hostname)-gitea-runner}"
GITEA_RUNNER_LABELS="${GITEA_RUNNER_LABELS:-self-hosted:host,issue-runner:host,antigravity:host,agy:host,claude:host,opencode:host,pi-agent:host}"

CONFIG_FILE="/data/.runner"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "⚙️ Registrazione del runner su Gitea ($GITEA_INSTANCE_URL)..."
    act_runner register \
        --no-interactive \
        --instance "${GITEA_INSTANCE_URL}" \
        --token "${GITEA_RUNNER_REGISTRATION_TOKEN}" \
        --name "${GITEA_RUNNER_NAME}" \
        --labels "${GITEA_RUNNER_LABELS}" \
        --config /data/config.yaml || true
    echo "✅ Runner registrato con successo su Gitea."
else
    echo "ℹ️ Runner già registrato in precedenza (riutilizzo di $CONFIG_FILE)."
fi

echo "📡 Avvio demone act_runner..."
exec act_runner daemon --config /data/config.yaml
