# ShopSphere/frontend/Dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies with timeout and optimization
RUN npm ci --only=production --silent --no-audit --no-fund || \
    npm install --silent --no-audit --no-fund --production

# Copy source code
COPY . .

# Build the application
RUN npm run build

# Expose port
EXPOSE 3000

# Run in production mode
CMD ["npm", "start"]