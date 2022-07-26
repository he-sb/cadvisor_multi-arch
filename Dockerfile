FROM golang:1.18 AS build

RUN apt update && apt install -y git dmsetup
RUN git clone \
        --branch v0.44.1 \
        --depth 1 \
        https://github.com/google/cadvisor.git \
        /go/src/github.com/google/cadvisor
WORKDIR /go/src/github.com/google/cadvisor
RUN make build

FROM alpine:latest
COPY --from=build /go/src/github.com/google/cadvisor/cadvisor /usr/bin/cadvisor

EXPOSE 8080

ENV CADVISOR_HEALTHCHECK_URL=http://localhost:8080/healthz

HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget --quiet --tries=1 --spider $CADVISOR_HEALTHCHECK_URL || exit 1

ENTRYPOINT ["/usr/bin/cadvisor", "-logtostderr"]