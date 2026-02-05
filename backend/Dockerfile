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

COPY --from=builder /zxy .
COPY --from=builder /build/schema ./schema
COPY --from=builder /build/aio_template.json ./aio_template.json

EXPOSE 6969

ENTRYPOINT ["./zxy"]
