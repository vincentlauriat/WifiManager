#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SPARKLE_VERSION="2.9.1"
TOOLS_DIR="$ROOT/.sparkle-tools"

if [ -x "$TOOLS_DIR/bin/sign_update" ]; then
  echo "✓ Sparkle tools déjà présents ($SPARKLE_VERSION)"
  exit 0
fi

echo "→ Téléchargement Sparkle $SPARKLE_VERSION tools…"
mkdir -p "$TOOLS_DIR"
curl -fsSL "https://github.com/sparkle-project/Sparkle/releases/download/$SPARKLE_VERSION/Sparkle-$SPARKLE_VERSION.tar.xz" \
  | tar -xJ -C "$TOOLS_DIR"
echo "✅ Sparkle tools installés dans $TOOLS_DIR"
