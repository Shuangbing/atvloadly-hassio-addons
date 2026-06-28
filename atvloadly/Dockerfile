ARG BUILD_FROM=ghcr.io/home-assistant/amd64-base-debian:bookworm
FROM ${BUILD_FROM}

ENV LANG=C.UTF-8
ENV DEBIAN_FRONTEND=noninteractive
ENV ATVLOADLY_VERSION=v0.4.5
ENV ATVLOADLY_BIN_NAME=atvloadly-linux-amd64
ENV APP_HOME=/opt/atvloadly

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        avahi-daemon \
        ca-certificates \
        curl \
        dbus \
        iproute2 \
        libavahi-compat-libdnssd-dev \
        libnss-mdns \
        nginx \
        procps \
        tzdata \
        unzip \
        wget \
    && rm -rf /var/lib/apt/lists/*

RUN cd /tmp \
    && wget -q https://github.com/bitxeno/usbmuxd2/releases/download/v0.0.4/usbmuxd2-ubuntu-x86_64.tar.gz \
    && tar zxf usbmuxd2-ubuntu-x86_64.tar.gz \
    && dpkg -i ./libusb_1.0.26-1_x86_64.deb \
    && dpkg -i ./libgeneral_1.0.0-1_x86_64.deb \
    && dpkg -i ./libplist_2.6.0-1_x86_64.deb \
    && dpkg -i ./libtatsu_1.0.3-1_x86_64.deb \
    && dpkg -i ./libimobiledevice-glue_1.3.0-1_x86_64.deb \
    && dpkg -i ./libusbmuxd_2.3.0-1_x86_64.deb \
    && dpkg -i ./libimobiledevice_1.3.1-1_x86_64.deb \
    && dpkg -i ./usbmuxd2_1.0.0-1_x86_64.deb \
    && rm -f /tmp/*.deb /tmp/*.tar.gz

RUN cd /tmp \
    && wget -q https://github.com/bitxeno/PlumeImpactor/releases/download/v2.2.3-patch.4/plumesign-linux-x86_64.tar.gz \
    && tar zxf plumesign-linux-x86_64.tar.gz \
    && install -m 0755 plumesign-linux-x86_64 /usr/bin/plumesign \
    && rm -f /tmp/*.tar.gz /tmp/plumesign-linux-x86_64

RUN mkdir -p /keep /tmp/adi \
    && cd /tmp/adi \
    && wget -q -O applemusic.apk https://apps.mzstatic.com/content/android-apple-music-apk/applemusic.apk \
    && unzip -q applemusic.apk lib/x86_64/libstoreservicescore.so lib/x86_64/libCoreADI.so \
    && mkdir -p /keep/lib/x86_64 \
    && cp -f lib/x86_64/libstoreservicescore.so /keep/lib/x86_64/ \
    && cp -f lib/x86_64/libCoreADI.so /keep/lib/x86_64/ \
    && rm -rf /tmp/adi

RUN cd /tmp \
    && wget -q -O DeveloperDiskImages.zip https://github.com/bitxeno/DeveloperDiskImages/archive/refs/heads/main.zip \
    && unzip -q DeveloperDiskImages.zip \
    && mv DeveloperDiskImages-main /keep/DeveloperDiskImages \
    && rm -rf /keep/DeveloperDiskImages/iOS_DDI \
    && rm -rf /keep/DeveloperDiskImages/.gitignore \
    && rm -f /tmp/DeveloperDiskImages.zip

RUN mkdir -p ${APP_HOME} /data /var/lib/lockdown \
    && cd /tmp \
    && wget -q -O atvloadly.tar.gz https://github.com/bitxeno/atvloadly/releases/download/${ATVLOADLY_VERSION}/${ATVLOADLY_BIN_NAME}.tar.gz \
    && tar zxf atvloadly.tar.gz \
    && install -m 0755 ${ATVLOADLY_BIN_NAME} /usr/bin/atvloadly \
    && rm -f /tmp/atvloadly.tar.gz /tmp/${ATVLOADLY_BIN_NAME}

RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/conf.d/default.conf

COPY rootfs /

RUN chmod +x /run.sh /etc/init.d/usbmuxd

CMD ["/run.sh"]
