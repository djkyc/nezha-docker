# -------- Builder --------
FROM golang:1.22-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

RUN apk add --no-cache git ca-certificates

# 固定到可构建的稳定版本（关键）
RUN git clone --branch v0.20.6 --depth=1 https://github.com/nezhahq/nezha.git .

# 下载依赖
RUN go mod download

# 构建 agent
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build -trimpath -ldflags="-s -w" -o nezha-agent ./cmd/agent

# -------- Runtime --------
FROM busybox:stable-musl

WORKDIR /app

COPY --from=builder /app/nezha-agent /app/nezha-agent
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

ENV TZ=UTC
EXPOSE 5555

ENTRYPOINT ["/app/nezha-agent"]
