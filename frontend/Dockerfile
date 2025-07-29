# ShopSphere/frontend/Dockerfile - Optimized for faster builds
FROM node:18-alpine

WORKDIR /app

# Install dependencies for faster builds
RUN apk add --no-cache git curl

# Copy package files
COPY package*.json ./

# Install dependencies with optimizations
RUN npm install --legacy-peer-deps --no-audit --no-fund --verbose \
    && npm cache clean --force

# Copy source code
COPY . .

# Build the application with verbose logging and memory optimization
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV NEXT_TELEMETRY_DISABLED=1
RUN echo "=== Starting Next.js build ===" && \
    npm run build --verbose && \
    echo "=== Build completed successfully ==="

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=60s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Run in production mode
CMD ["npm", "start"]