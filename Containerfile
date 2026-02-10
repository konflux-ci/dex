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
FROM registry.access.redhat.com/ubi10-micro:10.1-1769518576

# Copy binary from the build stage
COPY --from=builder /workspace/dex/dex /bin/dex

# Copy Root CA Certificates
COPY --from=builder /etc/pki/tls/certs/ca-bundle.crt /etc/pki/tls/certs/ca-bundle.crt

# Enterprise Contract required labels (one per line for reliable application in multi-arch builds)
LABEL description="Dex is an identity service that uses OpenID Connect to drive other authentication protocols."
LABEL distribution-scope="public"
LABEL com.redhat.component="dex"
LABEL io.k8s.description="Dex is an identity service that uses OpenID Connect to drive other authentication protocols."
LABEL name="dex"
LABEL release="1"
LABEL url="https://github.com/dexidp/dex"
LABEL vendor="Red Hat\, Inc."
LABEL version="1"
LABEL org.opencontainers.image.licenses="Apache-2.0" \
      org.opencontainers.image.description="Dex is an identity service that uses OpenID Connect to drive other authentication protocols." \
      org.opencontainers.image.documentation=https://github.com/dexidp/dex \
      org.opencontainers.image.source=https://github.com/dexidp/dex \
      org.opencontainers.image.title=dex \
      org.opencontainers.image.vendor=Konflux \
      org.opencontainers.image.version=${DEX_VERSION}

ENTRYPOINT ["/bin/dex"]
