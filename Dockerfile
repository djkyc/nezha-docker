# -------- Builder --------
FROM golang:1.22-alpine AS builder

ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# 安装依赖
RUN apk add --no-cache git ca-certificates

# 复制 go.mod 和 go.sum
COPY go.mod go.sum ./

# 下载依赖
RUN go mod download

# 复制整个项目
COPY . .

# 构建 nezha agent
RUN CGO_ENABLED=0 \
    GOOS=${TARGETOS} \
    GOARCH=${TARGETARCH} \
    go build -ldflags="-s -w" -o nezha-agent ./cmd/agent

# -------- Runtime --------
FROM busybox:stable-musl

WORKDIR /app

# 拷贝可执行文件和证书
COPY --from=builder /app/nezha-agent /app/nezha-agent
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

ENV TZ=UTC

EXPOSE 5555

ENTRYPOINT ["/app/nezha-agent"]
