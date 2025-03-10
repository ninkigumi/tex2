# Copyright (c) 2021 Shigemi ISHIDA
# Released under the MIT license
# https://opensource.org/licenses/MIT

FROM alpine:3.13

ARG GLIBC_VER=2.34
ARG TEXLIVE_VER=2021

ENV LANG=C.UTF-8
ENV GLIBC_URL_BASE=https://github.com/sgerrand/docker-glibc-builder/releases/download
ENV PATH=/usr/local/texlive/bin/x86_64-linuxmusl:/usr/local/texlive/${TEXLIVE_VER}/bin/x86_64-linux:/usr/local/texlive/${TEXLIVE_VER}/bin/aarch64-linux:$PATH

ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib64

RUN set -x && \
    cd / && \
    apk update && \
    apk add --no-cache --virtual .fetch-deps curl xz libc6-compat && \
    apk add --no-cache --virtual .glibc-bin-deps libgcc && \
    apk add --no-cache perl fontconfig-dev freetype-dev ghostscript && \
    curl -L ${GLIBC_URL_BASE}/${GLIBC_VER}/glibc-bin-${GLIBC_VER}-$(arch).tar.gz | \
      tar zx -C / && \
    mkdir -p /lib64 /usr/glibc-compat/lib/locale /usr/glibc-compat/lib64 && \
    #cp /tmp/files/ld.so.conf /usr/glibc-compat/etc/ && \
    #cp /tmp/files/nsswitch.conf /etc/ && \
    { \
      echo '/usr/local/lib'; \
      echo '/usr/glibc-compat/lib'; \
      echo '/usr/lib'; \
      echo '/lib'; \
     } | tee /usr/glibc-compat/etc/files/ld.so.conf && \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' > /etc/nsswitch.conf && \
    rm -rf /usr/glibc-compat/etc/rpc && \
    rm -rf /usr/glibc-compat/lib/gconv && \
    rm -rf /usr/glibc-compat/lib/getconf && \
    rm -rf /usr/glibc-compat/lib/audit && \
    rm -rf /usr/glibc-compat/var && \
    for l in /usr/glibc-compat/lib/ld-linux-*; do \
      ln -s $l /lib/$(basename $l); \
      ln -s $l /usr/glibc-compat/lib64/$(basename $l); \
      ln -s $l /lib64/$(basename $l); \
    done && \
    if [ -f /etc/ld.so.cache ]; then \
      rm -f /etc/ld.so.cache; \
    fi && \
    ln -s /usr/glibc-compat/etc/ld.so.cache /etc/ld.so.cache && \
    /usr/glibc-compat/sbin/ldconfig && \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "${LANG}" || true && \
    echo "export LANG=${LANG}" > /etc/profile.d/locale.sh && \
    rm -rf /usr/glibc-compat/share && \
    rm -rf /usr/glibc-compat/bin && \
    rm -rf /usr/glibc-compat/sbin && \
    mkdir /tmp/install-tl-unx && \
    curl -L https://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet/install-tl-unx.tar.gz | \
      tar zx -C /tmp/install-tl-unx --strip-components=1 && \
    { \
      echo "selected_scheme scheme-basic"; \
      echo "tlpdbopt_install_docfiles 0"; \
      echo "tlpdbopt_install_srcfiles 0"; \
      echo "binary_$(arch)-linuxmusl 0"; \
      echo "binary_$(arch)-linux 1"; \
     } | tee /tmp/install-tl-unx/texlive.profile && \
    /tmp/install-tl-unx/install-tl \
      --profile=/tmp/install-tl-unx/texlive.profile && \
      #-repository https://ctan.math.utah.edu/ctan/tex-archive/systems/texlive/tlnet/ && \
    ls -al /usr/local/texlive && \
    tlmgr install \
      collection-latexextra \
      collection-fontsrecommended \
      collection-langjapanese \
      epstopdf \
      latexmk && \
    apk del --purge .fetch-deps && \
    apk del --purge .glibc-bin-deps && \
    rm -rf /tmp/files && \
    rm -rf /tmp/install-tl-unx && \
    rm -rf /var/cache/apk && \
    mkdir /var/cache/apk

WORKDIR /app
CMD ["sh"]
