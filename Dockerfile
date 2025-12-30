# -------- Builder --------
FROM golang:1.22-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# 安装依赖
RUN apk add --no-cache git ca-certificates

# 先下载依赖（利用缓存）
COPY go.mod go.sum ./
RUN go mod download

# 拷贝源码
COPY . .

# 构建二进制
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o nezha-agent ./cmd/agent

# -------- Runtime --------
FROM busybox:stable-musl

WORKDIR /app

# 拷贝程序和证书
COPY --from=builder /app/nezha-agent /app/nezha-agent
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

ENV TZ=UTC

EXPOSE 5555

ENTRYPOINT ["/app/nezha-agent"]
