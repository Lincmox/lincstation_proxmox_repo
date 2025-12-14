#!/usr/bin/env bash
set -euo pipefail

# ==============================
# Configuration
# ==============================
IMAGE_NAME="lincmox-repo"
IMAGE_TAG="latest"

# Chemins des secrets
GPG_PRIVATE_KEY="private.key"
GPG_PASSPHRASE="gpg_passphrase.txt"

# ==============================
# Vérifications
# ==============================
if [[ ! -f "$GPG_PRIVATE_KEY" ]]; then
  echo "❌ Clé privée GPG introuvable : $GPG_PRIVATE_KEY"
  exit 1
fi

if [[ ! -f "$GPG_PASSPHRASE" ]]; then
  echo "❌ Fichier passphrase introuvable : $GPG_PASSPHRASE"
  exit 1
fi

# Permissions minimales
chmod 600 "$GPG_PRIVATE_KEY" "$GPG_PASSPHRASE"

# ==============================
# Build Docker sécurisé
# ==============================
echo "🚀 Build de l'image Docker $IMAGE_NAME:$IMAGE_TAG"

export DOCKER_BUILDKIT=1

docker build \
  --progress=plain \
  --secret id=gpg_private,src="$GPG_PRIVATE_KEY" \
  --secret id=gpg_pass,src="$GPG_PASSPHRASE" \
  -t "$IMAGE_NAME:$IMAGE_TAG" \
  .

echo "✅ Build terminé avec succès"