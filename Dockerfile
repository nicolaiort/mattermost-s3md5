FROM golang:1.22-bookworm as backend_builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /build
COPY . .
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential
RUN cd server && make build-server

FROM node:20.11.1-buster as frontend_builder
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
WORKDIR /build
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y build-essential
COPY . .
RUN npm install -g npm@latest
RUN cd webapp && make package 

FROM ubuntu:jammy as runner
# Setting bash as our shell, and enabling pipefail option
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Some ENV variables
ENV PATH="/mattermost:${PATH}"
ARG PUID=2000
ARG PGID=2000

# # Install needed packages and indirect dependencies
RUN apt-get update \
  && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
  ca-certificates \
  curl \
  mime-support \
  unrtf \
  wv \
  poppler-utils \
  tidy \
  tzdata \
  && rm -rf /var/lib/apt/lists/*

# Set mattermost group/user
RUN mkdir -p /mattermost/data /mattermost/plugins /mattermost/client/plugins \
  && addgroup -gid ${PGID} mattermost \
  && adduser -q --disabled-password --uid ${PUID} --gid ${PGID} --gecos "" --home /mattermost mattermost

# unpack mattermost
COPY --from=backend_builder /build/server/mattermost /mattermost/mattermost
COPY --from=backend_builder /build/server/bin /mattermost/bin
COPY --from=backend_builder /build/server/config /mattermost/config
COPY --from=backend_builder /build/server/fonts /mattermost/fonts
COPY --from=backend_builder /build/server/i18n /mattermost/i18n
COPY --from=backend_builder /build/server/templates /mattermost/templates
COPY --from=frontend_builder /build/webapp/mattermost-webapp.tar.gz /tmp
RUN mkdir -p /tmp/webapp \
    && tar -xf /tmp/mattermost-webapp.tar.gz -C /tmp/webapp \
    && rm /tmp/mattermost-webapp.tar.gz \
    && mv /tmp/webapp/client/* /mattermost/client/ \
    && chown -R mattermost:mattermost /mattermost

# We should refrain from running as privileged user
USER mattermost

#Healthcheck to make sure container is ready
HEALTHCHECK --interval=30s --timeout=10s \
  CMD curl -f http://localhost:8065/api/v4/system/ping || exit 1

# Configure entrypoint and command
COPY --chown=mattermost:mattermost --chmod=765 ./entrypoint.sh /
ENTRYPOINT ["/entrypoint.sh"]
WORKDIR /mattermost
CMD ["mattermost"]

EXPOSE 8065 8067 8074 8075

# Declare volumes for mount point directories
VOLUME ["/mattermost/data", "/mattermost/logs", "/mattermost/config", "/mattermost/plugins", "/mattermost/client/plugins"]