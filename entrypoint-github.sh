#!/usr/bin/env bash
set -e

# ==============================================================================
# Entrypoint per GitHub Actions Self-Hosted Runner
# Supporta registrazione automatica via PAT o tramite token temporaneo
# ==============================================================================

echo "========================================================"
echo "🚀 Avvio GitHub Actions AI Issue Runner..."
echo "========================================================"

if [ -z "$GITHUB_URL" ]; then
    echo "❌ ERRORE: GITHUB_URL non è impostato! Specifica l'URL del repo o dell'organizzazione."
    exit 1
fi

RUNNER_NAME="${RUNNER_NAME:-$(hostname)-runner}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,x64,issue-runner,antigravity,agy,claude,opencode,pi-agent,codex}"
RUNNER_WORKDIR="${RUNNER_WORKDIR:-_work}"

# Pulizia URL
GITHUB_URL="${GITHUB_URL%/}"

# Determina se l'URL è un'organizzazione o un repository
# Formato Repo: https://github.com/OWNER/REPO
# Formato Org:  https://github.com/ORG oppure https://github.com/orgs/ORG
PATH_PART="${GITHUB_URL#*github.com/}"
PATH_PART="${PATH_PART#orgs/}"

IFS='/' read -r -a PARTS <<< "$PATH_PART"
if [ ${#PARTS[@]} -eq 1 ]; then
    IS_ORG=true
    ORG_NAME="${PARTS[0]}"
    API_REG_URL="https://api.github.com/orgs/${ORG_NAME}/actions/runners/registration-token"
    API_REM_URL="https://api.github.com/orgs/${ORG_NAME}/actions/runners/remove-token"
    echo "ℹ️ Configurazione target: ORGANIZZAZIONE ($ORG_NAME)"
elif [ ${#PARTS[@]} -eq 2 ]; then
    IS_ORG=false
    OWNER_NAME="${PARTS[0]}"
    REPO_NAME="${PARTS[1]}"
    API_REG_URL="https://api.github.com/repos/${OWNER_NAME}/${REPO_NAME}/actions/runners/registration-token"
    API_REM_URL="https://api.github.com/repos/${OWNER_NAME}/${REPO_NAME}/actions/runners/remove-token"
    echo "ℹ️ Configurazione target: REPOSITORY ($OWNER_NAME/$REPO_NAME)"
else
    echo "❌ Formato GITHUB_URL non riconosciuto: $GITHUB_URL"
    exit 1
fi

# Ottenimento token di registrazione
if [ -n "$GITHUB_PAT" ]; then
    echo "🔑 Recupero del registration token tramite GitHub PAT..."
    RESPONSE=$(curl -s -X POST -H "Authorization: token ${GITHUB_PAT}" -H "Accept: application/vnd.github+json" "${API_REG_URL}")
    REG_TOKEN=$(echo "$RESPONSE" | jq -r '.token // empty')
    
    if [ -z "$REG_TOKEN" ] || [ "$REG_TOKEN" = "null" ]; then
        echo "❌ Errore durante il recupero del token con il PAT. Risposta API:"
        echo "$RESPONSE"
        exit 1
    fi
    echo "✅ Registration token ottenuto con successo."
elif [ -n "$RUNNER_TOKEN" ]; then
    echo "🔑 Utilizzo del RUNNER_TOKEN fornito manualmente."
    REG_TOKEN="$RUNNER_TOKEN"
else
    echo "❌ ERRORE: Devi fornire GITHUB_PAT o RUNNER_TOKEN!"
    exit 1
fi

# Configurazione del Runner
echo "⚙️ Configurazione del runner con GitHub..."
./config.sh \
    --url "${GITHUB_URL}" \
    --token "${REG_TOKEN}" \
    --name "${RUNNER_NAME}" \
    --labels "${RUNNER_LABELS}" \
    --work "${RUNNER_WORKDIR}" \
    --unattended \
    --replace

# Trap per rimozione pulita allo shutdown
cleanup() {
    echo "🛑 Segnale di arresto ricevuto. Deregistrazione del runner da GitHub..."
    if [ -n "$GITHUB_PAT" ]; then
        REM_RESP=$(curl -s -X POST -H "Authorization: token ${GITHUB_PAT}" -H "Accept: application/vnd.github+json" "${API_REM_URL}")
        REM_TOKEN=$(echo "$REM_RESP" | jq -r '.token // empty')
        if [ -n "$REM_TOKEN" ] && [ "$REM_TOKEN" != "null" ]; then
            ./config.sh remove --token "${REM_TOKEN}" || true
        fi
    elif [ -n "$REG_TOKEN" ]; then
        ./config.sh remove --token "${REG_TOKEN}" || true
    fi
    echo "👋 Deregistrazione completata."
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "✅ Runner configurato con successo!"
echo "🏷️ Etichette registrate: ${RUNNER_LABELS}"
echo "📡 In ascolto per job GitHub Actions..."

./run.sh &
RUN_PID=$!
wait "$RUN_PID"
