FROM rockylinux:9

WORKDIR /workspace

ENV GOSU_VERSION=1.19
ENV GOSU_URL=https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu
ENV HOME=/home/codex
ENV PATH=$HOME/bin:$PATH

RUN dnf -y update && \
    dnf -y install \
      ca-certificates \
      curl-minimal \
      wget \
      git \
      less \
      openssh-clients \
      procps-ng \
      which \
      findutils \
      tar \
      gzip \
      shadow-utils \
      dnf-plugins-core && \
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
      emacs-nox && \
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

COPY runcodex.sh $HOME/bin/
RUN chmod +x $HOME/bin/runcodex.sh

COPY entrypoint.sh /
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ["runcodex.sh"]
