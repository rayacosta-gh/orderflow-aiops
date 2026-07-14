FROM jenkins/ssh-agent:8.5.0-jdk21

RUN apt-get update && apt-get install -y --no-install-recommends \
      maven \
      curl \
    && rm -rf /var/lib/apt/lists/*

# Debian's docker.io package on this base only ships dockerd, not the
# docker CLI - install the official static client binary instead. Only
# the client is needed: Docker access comes from the host's mounted
# socket (docker-outside-of-docker), no dockerd runs in this container.
ARG TARGETARCH
ARG DOCKER_CLI_VERSION=29.6.1
RUN set -e; \
    case "${TARGETARCH}" in \
      amd64) DOCKER_ARCH=x86_64 ;; \
      arm64) DOCKER_ARCH=aarch64 ;; \
      *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL "https://download.docker.com/linux/static/stable/${DOCKER_ARCH}/docker-${DOCKER_CLI_VERSION}.tgz" \
      | tar -xz --strip-components=1 -C /usr/local/bin docker/docker

# On Docker Desktop for Mac, the bind-mounted docker.sock is owned by
# root:root (GID 0), not a dedicated "docker" group with its own GID like
# on a real Linux docker host - group 0 already has rw on the socket, so
# adding jenkins there is what actually grants access here.
RUN usermod -aG root jenkins

# Deliberately no USER directive here: the base image's entrypoint
# (setup-sshd) needs to start as root to configure sshd, then it drops
# to the jenkins user itself for the actual SSH session / build steps.
