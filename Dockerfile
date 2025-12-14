# ---------- STAGE 1 : build + signature ----------
FROM debian:bookworm AS builder

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    reprepro \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /repo
COPY conf/ /repo/conf/

# Remplacer SignWith par le key ID
ARG GPG_KEY_ID
RUN sed -i "s/^SignWith:.*$/SignWith: $GPG_KEY_ID/" /repo/conf/distributions

# Créer dossier GNUPG
RUN mkdir -p /root/.gnupg && chmod 700 /root/.gnupg

# Importer clé privée en batch, loopback
RUN --mount=type=secret,id=gpg_private \
    --mount=type=secret,id=gpg_pass \
    gpg --batch --yes \
        --pinentry-mode loopback \
        --passphrase-file /run/secrets/gpg_pass \
        --import /run/secrets/gpg_private

# Copier clé publique
COPY public.key /repo/public.key

# Copier paquets
COPY packages/ /tmp/packages/

# Forcer reprepro à utiliser GPG en mode loopback
ENV GNUPGHOME=/root/.gnupg
ENV GPG_TTY=/dev/console
ENV REPREPRO_GPG_OPTIONS="--pinentry-mode loopback"

RUN reprepro -V includedeb bookworm /tmp/packages/*.deb
RUN reprepro export

# ---------- STAGE 2 : nginx ----------
FROM nginx:alpine

RUN rm -f /etc/nginx/conf.d/default.conf \
    && rm -f /usr/share/nginx/html/index.html

COPY --from=builder /repo /usr/share/nginx/html

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