FROM ubuntu:21.04

LABEL maintainer="koba1014@gmail.com"

ENV TL_VERSION      2021
ENV TL_PATH         /usr/local/texlive
ENV PATH            ${TL_PATH}/bin/x86_64-linux:${TL_PATH}/bin/aarch64-linux:/bin:${PATH}

WORKDIR /tmp

# Install required packages
RUN apt update && \
    apt upgrade -y && \
    apt install -y \
    # Basic tools
    wget unzip ghostscript \
    # for tlmgr
    perl-modules-5.32 \
    # for XeTeX
    fontconfig && \
    # Clean caches
    apt autoremove -y && \
    apt clean && \
    rm -rf /var/cache/apt/archives/* /var/lib/apt/lists/*

# Install TeX Live
RUN mkdir install-tl-unx && \
    wget -qO- http://mirror.ctan.org/systems/texlive/tlnet/install-tl-unx.tar.gz | \
      tar -xz -C ./install-tl-unx --strip-components=1 && \
    printf "%s\n" \
      "TEXDIR ${TL_PATH}" \
      "selected_scheme scheme-full" \
      "option_doc 0" \
      "option_src 0" \
      > ./install-tl-unx/texlive.profile && \
    ./install-tl-unx/install-tl \
      -profile ./install-tl-unx/texlive.profile \
      #-repository http://ftp.jaist.ac.jp/pub/CTAN/systems/texlive/tlnet/ && \
      -repository https://ctan.math.washington.edu/tex-archive/systems/texlive/tlnet/ && \
    rm -rf *

# Set up fonts and llmk
RUN \
    # Run cjk-gs-integrate
      cjk-gs-integrate --cleanup --force && \
      cjk-gs-integrate --force && \
    # Copy CMap: 2004-{H,V}
    # cp ${TL_PATH}/texmf-dist/fonts/cmap/ptex-fontmaps/2004-* /var/lib/ghostscript/CMap/ && \
      kanji-config-updmap-sys --jis2004 haranoaji && \
    # Re-index LuaTeX font database
      luaotfload-tool -u -f && \
    # Install llmk
      wget -q -O /usr/local/bin/llmk https://raw.githubusercontent.com/wtsnjp/llmk/master/llmk.lua && \
      chmod +x /usr/local/bin/llmk

RUN tlmgr repository add http://contrib.texlive.info/current tlcontrib
RUN tlmgr pinning add tlcontrib '*'
RUN tlmgr install \
   japanese-otf-nonfree \
   japanese-otf-uptex-nonfree \
   ptex-fontmaps-macos \
   cjk-gs-integrate-macos
RUN cjk-gs-integrate --link-texmf --force \
  --fontdef-add=$(kpsewhich -var-value=TEXMFDIST)/fonts/misc/cjk-gs-integrate-macos/cjkgs-macos-highsierra.dat
RUN kanji-config-updmap-sys --jis2004 hiragino-highsierra-pron
RUN luaotfload-tool -u -f
#RUN fc-cache -r
RUN kanji-config-updmap-sys status

# Set default LANG=ja_JP.UTF-8. Without locale settings hiragino fonts cannot be found. Its file name is Japanese.
RUN apt-get update && \
    apt-get install -y locales && \
    # Clean caches
    apt-get autoremove -y && \
    apt-get clean
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "ja_JP.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    /usr/sbin/update-locale LANG=ja_JP.UTF-8
ENV lang=ja_JP.UTF-8

# Set up hiragino fonts link.
WORKDIR /usr/share/fonts/SystemLibraryFonts
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ明朝 ProN.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSerif.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ丸ゴ ProN W4.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSansR-W4.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W0.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W0.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W1.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W1.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W2.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W2.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W3.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W3.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W4.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W4.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W5.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W5.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W6.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W6.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W7.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W7.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W8.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W8.ttc
RUN ln -s /usr/share/fonts/SystemLibraryFonts/"ヒラギノ角ゴシック W9.ttc" /usr/local/texlive/texmf-local/fonts/opentype/cjk-gs-integrate/HiraginoSans-W9.ttc
RUN mktexlsr

VOLUME ["/usr/local/texlive/${TL_VERSION}/texmf-var/luatex-cache"]

WORKDIR /workdir

CMD ["sh"]
