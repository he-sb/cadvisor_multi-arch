FROM golang:1.22 AS build

ARG CADVISOR_VERSION='master'

RUN apt update && \
  apt install -y git dmsetup make gcc && \
  git clone https://github.com/google/cadvisor.git /go/src/github.com/google/cadvisor
WORKDIR /go/src/github.com/google/cadvisor
RUN git fetch --tags && \
  git checkout ${CADVISOR_VERSION} && \
  go env -w GO111MODULE=auto && \
  make build && \
  [ -f "./cadvisor" ] || \
  mv ./_output/cadvisor ./cadvisor

FROM alpine:latest

RUN apk --no-cache add libc6-compat device-mapper findutils ndctl zfs && \
  apk --no-cache add thin-provisioning-tools --repository http://dl-3.alpinelinux.org/alpine/edge/main/ && \
  echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf && \
  rm -rf /var/cache/apk/*

COPY --from=build /go/src/github.com/google/cadvisor/cadvisor /usr/bin/cadvisor

EXPOSE 8080

ENV CADVISOR_HEALTHCHECK_URL=http://localhost:8080/healthz

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider $CADVISOR_HEALTHCHECK_URL || exit 1

ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]
