# Lincmox - LincStation Proxmox Repo

## Setup

gpg --full-generate-key
gpg --export-secret-keys GPG_KEY_ID > gpg/private.key
chmod 600 gpg/private.key
gpg --export GPG_KEY_ID > gpg/public.key
echo "GPG_PASSPHRASE" > gpg/gpg_passphrase.txt
chmod 600 gpg/gpg_passphrase.txt
export DOCKER_BUILDKIT=1
chmod +x deploy.sh
./deploy.sh

## Installation

curl -fsSL https://lincmox.coolify.stela.ovh/public.key | sudo gpg --dearmor -o /usr/share/keyrings/lincmox.gpg
echo "deb [signed-by=/usr/share/keyrings/lincmox.gpg] https://lincmox.coolify.stela.ovh bookworm main" | sudo tee /etc/apt/sources.list.d/lincmox.list