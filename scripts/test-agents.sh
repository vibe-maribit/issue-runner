#!/usr/bin/env bash
set -e

# ==============================================================================
# Script di test diagnostico per le CLI degli Agenti AI
# ==============================================================================

echo "🔍 === DIAGNOSTICA AGENTI AI DISPONIBILI ==="
echo ""

# 1. Antigravity CLI (agy)
echo "--------------------------------------------------"
echo "1. Antigravity CLI (agy)"
if command -v agy &>/dev/null; then
    echo "✅ Binario agy trovato: $(which agy)"
    agy --version || true
    echo "🧪 Test chiamata autenticata (Google Pro)..."
    TEST_AGY=$(agy -p "Rispondi solo con: OK_AGY_PRO" 2>/dev/null || true)
    if [[ "$TEST_AGY" =~ "OK_AGY_PRO" ]]; then
        echo "🎉 Antigravity CLI con Google Pro FUNZIONANTE!"
    else
        echo "⚠️ Risposta agy: $TEST_AGY"
    fi
else
    echo "❌ agy non trovato nel PATH!"
fi
echo ""

# 2. Claude Code
echo "--------------------------------------------------"
echo "2. Anthropic Claude Code"
if command -v claude &>/dev/null; then
    echo "✅ Binario claude trovato: $(which claude)"
    claude --version || true
else
    echo "❌ claude non trovato nel PATH!"
fi
echo ""

# 3. OpenCode CLI
echo "--------------------------------------------------"
echo "3. OpenCode CLI"
if command -v opencode &>/dev/null; then
    echo "✅ Binario opencode trovato: $(which opencode)"
    opencode --version || true
else
    echo "❌ opencode non trovato nel PATH!"
fi
echo ""

# 4. Pi Coding Agent
echo "--------------------------------------------------"
echo "4. Pi Coding Agent"
if command -v pi &>/dev/null; then
    echo "✅ Binario pi trovato: $(which pi)"
    pi --version || true
else
    echo "❌ pi non trovato nel PATH!"
fi
echo ""

echo "✨ Diagnostica completata."
