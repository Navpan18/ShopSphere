# ShopSphere/frontend/Dockerfile - Optimized for faster builds
FROM node:18-alpine

WORKDIR /app

# Install dependencies for faster builds
RUN apk add --no-cache git

# Copy package files
COPY package*.json ./

# Install dependencies with optimizations
RUN npm ci --only=production --silent --no-audit --no-fund \
    && npm cache clean --force

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:3000/ || exit 1

# Run in production mode
CMD ["npm", "start"]