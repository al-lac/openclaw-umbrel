# OpenClaw Docker Image for Umbrel
# Self-hosted personal AI assistant with web-based setup

FROM node:22-bookworm-slim AS builder

# Install build dependencies
RUN apt-get update && apt-get install -y \
    git \
    python3 \
    make \
    g++ \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Enable corepack for pnpm
RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

# Clone OpenClaw repository
RUN git clone --depth 1 https://github.com/openclaw/openclaw.git .

# Install dependencies
RUN pnpm install --frozen-lockfile

# Build the application
ENV OPENCLAW_A2UI_SKIP_MISSING=1
RUN pnpm build
RUN pnpm ui:build || true

# Production image
FROM node:22-bookworm-slim

# Install runtime dependencies and brew requirements
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    tini \
    git \
    build-essential \
    procps \
    file \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy built application from builder
COPY --from=builder --chown=node:node /app /app

# Enable corepack for runtime
RUN corepack enable && corepack prepare pnpm@latest --activate

# Create directories for data persistence
RUN mkdir -p /home/node/.openclaw/workspace \
    && chown -R node:node /home/node/.openclaw

# Copy setup UI server
COPY --chown=node:node setup-ui/server.cjs /app/setup-server.cjs

# Install Homebrew to custom location using git clone method
USER node
ENV HOME=/home/node
ENV HOMEBREW_PREFIX=/home/node/.linuxbrew
ENV HOMEBREW_CELLAR=/home/node/.linuxbrew/Cellar
ENV HOMEBREW_REPOSITORY=/home/node/.linuxbrew/Homebrew
ENV PATH="${HOMEBREW_PREFIX}/bin:${HOMEBREW_PREFIX}/sbin:${PATH}"

RUN mkdir -p ${HOMEBREW_PREFIX} \
    && git clone --depth=1 https://github.com/Homebrew/brew ${HOMEBREW_REPOSITORY} \
    && mkdir -p ${HOMEBREW_PREFIX}/bin \
    && ln -s ${HOMEBREW_REPOSITORY}/bin/brew ${HOMEBREW_PREFIX}/bin/ \
    && brew update --force \
    && echo 'eval "$(/home/node/.linuxbrew/bin/brew shellenv)"' >> /home/node/.bashrc

# Set environment variables
ENV NODE_ENV=production
ENV OPENCLAW_DATA_DIR=/home/node/.openclaw
ENV OPENCLAW_GATEWAY_HOST=0.0.0.0
ENV OPENCLAW_GATEWAY_PORT=18789

# Expose gateway port
EXPOSE 18789

# Use tini as init system
ENTRYPOINT ["/usr/bin/tini", "--"]

# Run the setup/proxy server
CMD ["node", "/app/setup-server.cjs"]
