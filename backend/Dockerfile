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

# Install native yt-dlp, ffmpeg, AND nodejs (for the JS runtime)
RUN apk add --no-cache \
    ca-certificates \
    ffmpeg \
    yt-dlp \
    nodejs

COPY --from=builder /zxy .
COPY --from=builder /build/schema ./schema

EXPOSE 6969

ENTRYPOINT ["./zxy"]
