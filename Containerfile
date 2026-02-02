# Containerfile for Konflux build of dex

# Build arguments
ARG DEX_VERSION

# Build Stage
FROM registry.access.redhat.com/ubi9/go-toolset:latest AS builder

# Redeclare ARG
ARG DEX_VERSION

# Set working directory to the submodule location
WORKDIR /workspace/dex

# Copy go mod files and nested API module definitions 
COPY --chown=1001:0 dex/go.mod dex/go.sum ./
COPY --chown=1001:0 dex/api/v2/go.mod dex/api/v2/go.sum ./api/v2/

# Download dependencies
RUN go mod download

# Copy the rest of the source code
COPY --chown=1001:0 dex/ ./

# Build the binary
RUN CGO_ENABLED=1 go build -a -installsuffix cgo \
    -ldflags="-X github.com/dexidp/dex/version.Version=${DEX_VERSION}" \
    -o ./dex ./cmd/dex

# Runtime Stage
FROM registry.access.redhat.com/ubi10-micro:10.1

# Copy binary from the build stage
COPY --from=builder /workspace/dex/dex /bin/dex

# Copy Root CA Certificates
COPY --from=builder /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/certs/ca-bundle.crt

LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.description="Dex is an identity service that uses OpenID Connect to drive other authentication protocols." \
      org.opencontainers.image.documentation=https://github.com/dexidp/dex \
      org.opencontainers.image.source=https://github.com/dexidp/dex \
      org.opencontainers.image.title=dex \
      org.opencontainers.image.vendor=Konflux \
      org.opencontainers.image.version=${DEX_VERSION}

ENTRYPOINT ["/bin/dex"]
