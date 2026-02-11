FROM rockylinux:9

ARG UID=1000
ARG GID=1000

RUN dnf -y update && \
    dnf -y install \
      ca-certificates \
      curl-minimal \
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

RUN npm i -g @openai/codex && npm cache clean --force

RUN groupadd -g ${GID} codex && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash codex

USER codex
WORKDIR /workspace
ENV PAGER=less
CMD ["/bin/bash"]
