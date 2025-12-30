# -------- depend: 只负责证书和时区 --------
FROM alpine:3.20 AS depend
RUN apk add --no-cache ca-certificates tzdata

# -------- downloader: 下载官方 release 的 agent --------
FROM alpine:3.20 AS downloader

ARG TARGETARCH
ARG NEZHA_VERSION=v0.20.6

RUN apk add --no-cache ca-certificates wget tar

WORKDIR /tmp

RUN if [ "$TARGETARCH" = "amd64" ]; then \
        AGENT_ARCH="amd64"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        AGENT_ARCH="arm64"; \
    else \
        echo "Unsupported arch: $TARGETARCH" && exit 1; \
    fi && \
    wget -O nezha-agent.tar.gz \
      https://github.com/nezhahq/nezha/releases/download/${NEZHA_VERSION}/nezha-agent-linux-${AGENT_ARCH}.tar.gz && \
    tar -xzf nezha-agent.tar.gz && \
    chmod +x nezha-agent

# -------- runtime: busybox 运行 --------
FROM busybox:stable-musl

# 这两个 ARG 不是必须，但你 workflow 里可能会传，保留也无妨
ARG TARGETOS
ARG TARGETARCH

# 拷贝证书与时区数据（关键：不要从宿主机 COPY /etc/ssl/certs）
COPY --from=depend /etc/ssl/certs /etc/ssl/certs
COPY --from=depend /usr/share/zoneinfo /usr/share/zoneinfo

# 拷贝 agent
WORKDIR /app
COPY --from=downloader /tmp/nezha-agent /app/nezha-agent

ARG TZ=UTC
ENV TZ=$TZ

EXPOSE 5555
ENTRYPOINT ["/app/nezha-agent"]
