# ShopSphere/backend/Dockerfile (Ultra Fast - Minimal Base)
FROM python:3.11-alpine

# Set environment variables for maximum performance
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_DEFAULT_TIMEOUT=300 \
    PYTHONPATH=/app \
    MAKEFLAGS="-j$(nproc)" \
    PIP_PREFER_BINARY=1

# Install system dependencies optimized for Alpine
RUN apk add --no-cache --virtual .build-deps \
    gcc \
    g++ \
    make \
    musl-dev \
    postgresql-dev \
    libffi-dev \
    && apk add --no-cache \
    postgresql-client \
    curl \
    ca-certificates

# Create app directory
WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python packages with binary wheels and optimized settings
RUN pip install --upgrade pip setuptools wheel && \
    pip install --only-binary=all --prefer-binary --no-compile --retries 3 --timeout 300 -r requirements.txt || \
    pip install --retries 3 --timeout 300 -r requirements.txt

# Copy application code
COPY . .

# Set proper permissions (faster than creating user)
RUN chmod -R 755 /app

# Expose port
EXPOSE 8001

# Add health check (commented out until health endpoint exists)
# HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
#     CMD curl -f http://localhost:8001/health || exit 1

# Run the application
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8001"]