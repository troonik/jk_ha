ARG BUILD_FROM=alpine:3.19
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Install s6-overlay (vajalik Hassio addonidele)
ARG S6_OVERLAY_VERSION=3.1.6.2
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp/
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp/
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz && \
    tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz && \
    rm /tmp/s6-overlay-*.tar.xz

# Copy package.json
COPY package.json /opt/

WORKDIR /opt

# Setup base
RUN \
    apk add --no-cache \
        nodejs \
        npm \
        git \
        icu-data-full \
        nginx \
        openssh-client \
        patch \
        can-utils \
        iproute2 \
        bash \
        mosquitto-clients \
        python3 \
        make \
        g++ \
    && npm install \
        --no-audit \
        --no-fund \
        --no-update-notifier \
        --omit=dev \
        --unsafe-perm \
    && npm rebuild --build-from-source @serialport/bindings-cpp \
    && npm cache clear --force \
    && apk del --no-cache \
        python3 \
        make \
        g++ \
    && rm -fr \
        /etc/nginx \
        /root/.cache \
        /root/.npm

# Copy root filesystem
COPY rootfs /

# Health check
HEALTHCHECK --start-period=10m \
    CMD curl --fail http://127.0.0.1:1891 || exit 1

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# hadolint ignore=DL3045
ENV VERSION=${BUILD_VERSION}

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION}
