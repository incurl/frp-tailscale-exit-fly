ARG TS_VERSION=1.48.0
ARG TS_FILE=tailscale_${TS_VERSION}_amd64.tgz

FROM alpine:latest as tailscale
ARG TS_FILE
WORKDIR /app

RUN wget https://pkgs.tailscale.com/stable/${TS_FILE} && \
  tar xzf ${TS_FILE} --strip-components=1
COPY . ./


FROM alpine:latest
ENV FRP_VERSION 0.51.3
WORKDIR /app

RUN apk update && apk add ca-certificates iptables ip6tables iproute2 && rm -rf /var/cache/apk/*

# creating directories for tailscale
RUN mkdir -p /var/run/tailscale
RUN mkdir -p /var/cache/tailscale
RUN mkdir -p /var/lib/tailscale

# Copy binary to production image
COPY --from=tailscale /app/tailscaled /app/tailscaled
COPY --from=tailscale /app/tailscale /app/tailscale
COPY --from=tailscale /app/start.sh /app/start.sh

RUN wget https://github.com/fatedier/frp/releases/download/v${FRP_VERSION}/frp_${FRP_VERSION}_linux_amd64.tar.gz && \
    tar -xf frp_${FRP_VERSION}_linux_amd64.tar.gz --strip-components 1 frp_${FRP_VERSION}_linux_amd64/frps && \
    rm frp_${FRP_VERSION}_linux_amd64.tar.gz
COPY frps.ini .

# Run on container startup.
USER root
CMD ["/app/start.sh"]
