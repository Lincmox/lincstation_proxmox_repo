# ---------- STAGE 1 : build + signature ----------
FROM debian:trixie AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Installer reprepro + GPG
RUN apt update && apt install -y \
    reprepro \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
COPY conf/ /repo/conf/

# Injecter le Key ID dans distributions (via ARG sécurisé)
ARG GPG_KEY_ID
RUN sed -i "s/^SignWith:.*$/SignWith: $GPG_KEY_ID/" /repo/conf/distributions

# Créer dossier GNUPG sécurisé
RUN mkdir -p /root/.gnupg && chmod 700 /root/.gnupg

# Importer la clé privée sans passphrase via BuildKit secret
RUN --mount=type=secret,id=gpg_private \
    gpg --batch --yes \
        --import /run/secrets/gpg_private

# Copier la clé publique pour distribution
COPY public.key /repo/public.key

# Copier les paquets Debian
COPY packages/ /tmp/packages/

# Variables GPG pour reprepro (mode batch)
ENV GNUPGHOME=/root/.gnupg
ENV REPREPRO_GPG_OPTIONS="--batch"

# Ajouter les paquets et exporter l'index
RUN reprepro includedeb trixie /tmp/packages/*.deb
RUN reprepro export

# ---------- STAGE 2 : nginx ----------
FROM nginx:alpine

# Nettoyer configuration par défaut
RUN rm -f /etc/nginx/conf.d/default.conf \
    && rm -f /usr/share/nginx/html/index.html

# Copier le dépôt depuis le builder
COPY --from=builder /repo /usr/share/nginx/html

# Configuration Nginx pour autoindex
RUN echo 'server { \
    listen 80 default_server; \
    server_name _; \
    root /usr/share/nginx/html; \
    autoindex on; \
    location / { \
        try_files $uri $uri/ =404; \
    } \
}' > /etc/nginx/conf.d/repo.conf

EXPOSE 80