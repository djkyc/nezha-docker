# -------- depend: 证书和时区 --------
FROM alpine:3.20 AS depend
RUN apk add --no-cache ca-certificates tzdata

# -------- downloader: 下载官方 release 的 agent --------
FROM alpine:3.20 AS downloader

ARG TARGETARCH
ARG AGENT_VERSION=v1.14.1

WORKDIR /tmp
RUN apk add --no-cache ca-certificates wget unzip

# nezhahq/agent 的资产命名：nezha-agent_linux_amd64.zip / nezha-agent_linux_arm64.zip
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        AGENT_ARCH="amd64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        AGENT_ARCH="arm64"; \
    else \
        echo "Unsupported arch: $TARGETARCH" && exit 1; \
    fi && \
    wget -O nezha-agent.zip \
      https://github.com/nezhahq/agent/releases/download/${AGENT_VERSION}/nezha-agent_linux_${AGENT_ARCH}.zip && \
    unzip -o nezha-agent.zip && \
    chmod +x nezha-agent

# -------- runtime: busybox 运行 --------
FROM busybox:stable-musl

# busybox 里没有证书/时区，按官方做法从 depend 拷
COPY --from=depend /etc/ssl/certs /etc/ssl/certs
COPY --from=depend /usr/share/zoneinfo /usr/share/zoneinfo

WORKDIR /app
COPY --from=downloader /tmp/nezha-agent /app/nezha-agent

ARG TZ=UTC
ENV TZ=$TZ

EXPOSE 5555
ENTRYPOINT ["/app/nezha-agent"]
