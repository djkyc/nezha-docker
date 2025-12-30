# -------- Builder --------
FROM golang:1.22-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# 安装依赖
RUN apk add --no-cache git ca-certificates

# 克隆 nezha 官方仓库
RUN git clone --depth=1 https://github.com/nezhahq/nezha.git .

# 下载 Go 依赖
RUN go mod download

# 构建 agent
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o nezha-agent ./cmd/agent

# -------- Runtime --------
FROM busybox:stable-musl

WORKDIR /app

COPY --from=builder /app/nezha-agent /app/nezha-agent
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

ENV TZ=UTC
EXPOSE 5555

ENTRYPOINT ["/app/nezha-agent"]
