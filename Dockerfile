ARG BUILD_FROM=ghcr.io/hassio-addons/base:18.1.0
# hadolint ignore=DL3006
FROM ${BUILD_FROM} AS builder

# Copy package.json
COPY package.json /opt/

WORKDIR /opt

RUN \
    apk add --no-cache \
        nodejs \
        npm \
        python3 \
        make \
        g++ \
    && npm install \
        --no-audit \
        --no-fund \
        --no-update-notifier \
        --omit=dev \
        --unsafe-perm \
    && npm cache clear --force \
    && rm -rf /root/.npm

# Final stage
FROM ${BUILD_FROM}

# Copy Node-RED from builder
COPY --from=builder /opt/node_modules /opt/node_modules
COPY package.json /opt/

WORKDIR /opt

RUN \
    apk add --no-cache \
        git \
        icu-data-full \
        nginx \
        nodejs \
        npm \
        openssh-client \
        patch \
        can-utils \
        iproute2 \
        bash \
        mosquitto-clients \
    && echo -e "StrictHostKeyChecking no" >> /etc/ssh/ssh_config \
    && rm -fr \
        /etc/nginx

# Copy root filesystem
COPY rootfs /

# Garantir les droits dans l'image Docker
RUN chmod +x \
    /etc/s6-overlay/s6-rc.d/init-customizations/run \
    /etc/s6-overlay/s6-rc.d/init-customizations/up \
    /etc/s6-overlay/s6-rc.d/init-customizations/type

HEALTHCHECK --start-period=10m \
    CMD curl --fail http://127.0.0.1:1891 || exit 1

ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# hadolint ignore=DL3045
ENV VERSION=${BUILD_VERSION}

LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Franck Nijhof <frenck@addons.community>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
