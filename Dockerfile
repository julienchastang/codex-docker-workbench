FROM rockylinux:9

WORKDIR /workspace

ENV GOSU_VERSION=1.19
ENV GOSU_URL=https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu
ARG EMACS_VERSION=31.1
ARG DIRENV_VERSION=2.37.1
ENV HOME=/home/codex
ENV PATH=$HOME/bin:$PATH

RUN dnf -y update && \
    dnf -y install \
      ca-certificates \
      curl-minimal \
      nmap \
      nmap-ncat \
      iproute \
      iputils \
      openssl \
      tcpdump \
      bind-utils \
      grep \
      sed \
      gawk \
      wget \
      git \
      less \
      make \
      openssh-clients \
      procps-ng \
      which \
      findutils \
      tar \
      gzip \
      bubblewrap \
      python3 \
      python3-pip \
      shadow-utils \
      dnf-plugins-core && \
    dnf -y clean all && rm -rf /var/cache/dnf

RUN dnf -y module reset ruby && \
    dnf -y module enable ruby:3.3 && \
    dnf -y install ruby ruby-devel && \
    gem install --no-document bundler && \
    dnf -y clean all && rm -rf /var/cache/dnf

RUN dnf -y config-manager --set-enabled crb && \
    dnf -y install epel-release && \
    dnf -y update && \
    dnf -y clean all && rm -rf /var/cache/dnf

RUN dnf -y install \
      ripgrep \
      fd-find \
      tree \
      jq \
      patch \
      diffutils \
      zip \
      unzip \
      texinfo \
      vim-common && \
    dnf -y clean all && rm -rf /var/cache/dnf

RUN set -eu; \
    case "$(uname -m)" in \
      x86_64) direnv_arch=amd64 ;; \
      aarch64) direnv_arch=arm64 ;; \
      armv[67]*) direnv_arch=arm ;; \
      i[3456]86) direnv_arch=386 ;; \
      *) direnv_arch="$(uname -m)" ;; \
    esac; \
    curl -fsSL -o /usr/local/bin/direnv \
      "https://github.com/direnv/direnv/releases/download/v${DIRENV_VERSION}/direnv.linux-${direnv_arch}"; \
    chmod +x /usr/local/bin/direnv; \
    direnv version

RUN dnf -y install \
      gcc \
      ncurses-devel \
      gnutls-devel \
      libxml2-devel \
      jansson-devel \
      xz && \
    curl -fsSLO "https://ftp.gnu.org/gnu/emacs/emacs-${EMACS_VERSION}.tar.xz" && \
    tar -xf "emacs-${EMACS_VERSION}.tar.xz" && \
    cd "emacs-${EMACS_VERSION}" && \
    ./configure --without-x --without-native-compilation && \
    make -j"$(nproc)" && \
    make install && \
    cd .. && \
    rm -rf "emacs-${EMACS_VERSION}" "emacs-${EMACS_VERSION}.tar.xz" && \
    dnf -y remove gcc ncurses-devel gnutls-devel libxml2-devel jansson-devel xz && \
    dnf -y clean all && rm -rf /var/cache/dnf

RUN curl -fsSL https://rpm.nodesource.com/setup_22.x | bash - && \
    dnf -y install nodejs && \
    dnf -y clean all && rm -rf /var/cache/dnf

RUN set -eux; \
	\
	rpmArch="$(rpm --query --queryformat='%{ARCH}' rpm)"; \
	case "$rpmArch" in \
		aarch64) dpkgArch='arm64' ;; \
		armv[67]*) dpkgArch='armhf' ;; \
		i[3456]86) dpkgArch='i386' ;; \
		ppc64le) dpkgArch='ppc64el' ;; \
		riscv64 | s390x | loongarch64) dpkgArch="$rpmArch" ;; \
		x86_64) dpkgArch='amd64' ;; \
		*) echo >&2 "error: unknown/unsupported architecture '$rpmArch'"; exit 1 ;; \
	esac; \
	wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch"; \
	wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$dpkgArch.asc"; \
	\
        # verify the signature
	export GNUPGHOME="$(mktemp -d)"; \
	gpg --batch --keyserver hkps://keys.openpgp.org --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4; \
	gpg --batch --verify /usr/local/bin/gosu.asc /usr/local/bin/gosu; \
	gpgconf --kill all; \
	rm -rf "$GNUPGHOME" /usr/local/bin/gosu.asc; \
	\
	chmod +x /usr/local/bin/gosu; \
        # verify that the binary works
	gosu --version; \
	gosu nobody true

RUN npm i -g @openai/codex && npm cache clean --force

RUN python3 -m pip install --no-cache-dir \
      basedpyright \
      pytest \
      fastapi \
      uvicorn \
      httpx \
      pytest-cov \
      ruff \
      mypy

RUN ln -sf /usr/bin/python3 /usr/local/bin/python

RUN mkdir -p "$HOME" && cat > "$HOME/.bashrc" <<'EOF'
if [ -f /etc/bashrc ]; then
  . /etc/bashrc
fi

# Show active user clearly with a modern, readable prompt.
if (( EUID == 0 )); then
  PS1='\[\e[1;97;41m\]\u@\h \w\n\$\[\e[0m\] '
else
  PS1='\[\e[1;36m\]\u\[\e[0m\]@\[\e[1;34m\]\h\[\e[0m\] \[\e[1;33m\]\w\[\e[0m\]\n\[\e[1;32m\]\$\[\e[0m\] '
fi

eval "$(direnv hook bash)"
EOF

COPY runcodex.sh $HOME/bin/
RUN chmod +x $HOME/bin/runcodex.sh && \
    mkdir -p $HOME/.emacs.d

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["runcodex.sh"]
