# ShopSphere/frontend/Dockerfile - Build Only (No Testing)
FROM node:18-alpine

WORKDIR /app

# Install basic dependencies
RUN apk add --no-cache curl

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps --no-audit --no-fund \
    && npm cache clean --force

# Copy source code
COPY . .

# Build the application
ENV NODE_OPTIONS="--max-old-space-size=2048"
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# Expose port
EXPOSE 3000

# Simple health check (no timeout issues)
HEALTHCHECK --interval=60s --timeout=30s --start-period=30s --retries=2 \
    CMD curl -f http://localhost:3000/ || exit 1

# Run in production mode
CMD ["npm", "start"]