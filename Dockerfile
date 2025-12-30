# -------- Downloader --------
FROM alpine:3.20 AS downloader

ARG TARGETARCH
ENV NEZHA_VERSION=v0.20.6

WORKDIR /tmp

RUN apk add --no-cache ca-certificates wget tar

# 根据架构下载官方 agent
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

# -------- Runtime --------
FROM alpine:3.20

WORKDIR /app

# runtime 安装 CA 证书（关键：不要 COPY /etc/ssl/certs）
RUN apk add --no-cache ca-certificates tzdata

COPY --from=downloader /tmp/nezha-agent /app/nezha-agent

ENV TZ=UTC
EXPOSE 5555

ENTRYPOINT ["/app/nezha-agent"]
