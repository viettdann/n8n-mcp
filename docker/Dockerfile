# Add base image
ARG NODE_VERSION=22
FROM node:${NODE_VERSION}-alpine AS base

ARG BUILD_DATE
ARG VCS_REF
LABEL org.opencontainers.image.created=${BUILD_DATE}
LABEL org.opencontainers.image.revision=${VCS_REF}

# Copy entrypoint script
COPY ["docker/docker-entrypoint.sh", "/usr/local/bin/"]

# Install only essential runtime tools
RUN chmod +x /usr/local/bin/docker-entrypoint.sh \
    && apk add --no-cache curl \
    && rm -rf /var/cache/apk/* 

USER 1000:1000
WORKDIR /app

# Stage 1: Builder (TypeScript compilation only)
FROM base AS builder

# Copy tsconfig for TypeScript compilation
COPY ["tsconfig.json", "."]

# Create minimal package.json and install ONLY build dependencies
RUN echo '{}' > package.json && \
    yarn add --dev typescript@^5.8.3 @types/node@^22.15.30 @types/express@^5.0.3 \
        @modelcontextprotocol/sdk@^1.12.1 dotenv@^16.5.0 express@^5.1.0 axios@^1.10.0 \
        n8n-workflow@^1.96.0 uuid@^11.0.5 @types/uuid@^10.0.0

# Copy source and build
COPY ["src", "src"]
# Note: src/n8n contains TypeScript types needed for compilation
# These will be compiled but not included in runtime
RUN yarn tsc

# Stage 2: Runtime (minimal dependencies)
FROM base AS runtime

# Copy runtime-only package.json
COPY ["docker/package.json", "package.json"]

# Install runtime dependencies with cache mount
RUN --mount=type=cache,target=~/.yarn \
    yarn install --production --no-audit

# Copy built application
COPY --from=builder ["/app/dist", "dist"]

# Copy pre-built database and required files
COPY ["data/nodes.db", "data/"]
COPY ["docker/schema.sql", "src/database/schema.sql"]

# Add container labels
LABEL org.opencontainers.image.source="https://github.com/viettdann/n8n-mcp"
LABEL org.opencontainers.image.description="n8n MCP Server - Runtime Only"
LABEL org.opencontainers.image.licenses="MIT"
LABEL org.opencontainers.image.title="n8n-mcp-optimized"

# Set Docker environment flag
ENV IS_DOCKER=true
ENV MCP_MODE=http
ENV USE_FIXED_HTTP=true
ENV NODE_ENV=production
# Expose HTTP port
EXPOSE 3000

# Optimized entrypoint
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
CMD ["yarn", "start"]