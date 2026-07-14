FROM jenkins/ssh-agent:8.5.0-jdk21

RUN apt-get update && apt-get install -y --no-install-recommends \
      maven \
      docker.io \
    && rm -rf /var/lib/apt/lists/*

# Docker access comes only from the host's mounted socket (docker-outside-
# of-docker) - no dockerd runs in this container, just the client talking
# to the host daemon. jenkins user needs group membership to use the socket.
RUN usermod -aG docker jenkins

# Deliberately no USER directive here: the base image's entrypoint
# (setup-sshd) needs to start as root to configure sshd, then it drops
# to the jenkins user itself for the actual SSH session / build steps.
