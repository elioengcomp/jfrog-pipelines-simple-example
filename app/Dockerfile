# Builder image
FROM golang:latest

# Set workspace
WORKDIR /app
# Copy source
COPY ./ /app/

# Build
RUN cd /app; go build -o app main.go

# Runnable image
FROM mcr.microsoft.com/windows/nanoserver:1809-amd64

ARG APP_VERSION
ARG APP_PORT=8080

# Set workspace
WORKDIR /app

ENV APP_VERSION=$APP_VERSION
ENV APP_PORT=$APP_PORT

# Copy microservice executable from builder image
COPY --from=0 /app/app /app/app

EXPOSE $APP_PORT/tcp

## Set Entrypoint
CMD ["/app/app"]

