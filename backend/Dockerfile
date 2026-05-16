# STAGE 1: Build the binary
FROM golang:1.24.4-alpine AS builder

WORKDIR /build

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux go build -o /zxy

# STAGE 2: Final lightweight image
FROM alpine:latest

WORKDIR /app

# Install system dependencies, python3, ffmpeg, and yt-dlp
RUN apk add --no-cache \
    ca-certificates \
    curl \
    ffmpeg \
    python3 \
    && curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp \
    && chmod a+rx /usr/local/bin/yt-dlp

COPY --from=builder /zxy .
COPY --from=builder /build/schema ./schema

EXPOSE 6969

ENTRYPOINT ["./zxy"]
