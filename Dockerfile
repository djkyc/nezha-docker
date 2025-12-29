FROM golang:1.22-alpine AS builder
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

RUN apk add --no-cache git ca-certificates

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 \
  GOOS=${TARGETOS} \
  GOARCH=${TARGETARCH} \
  go build -ldflags="-s -w" -o nezha-agent ./cmd/agent
  FROM busybox:stable-musl

WORKDIR /app

COPY --from=builder /app/nezha-agent /app/nezha-agent
COPY --from=builder /etc/ssl/certs /etc/ssl/certs

ENV TZ=UTC
EXPOSE 5555

ENTRYPOINT ["/app/nezha-agent"]
