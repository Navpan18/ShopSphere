# ShopSphere Service Startup Guide

This document explains the startup sequence and timing for all ShopSphere services including Jenkins CI/CD.

## 🚀 Service Startup Sequence

The `start-services.sh` script starts services in the following order with appropriate wait times:

### Step 1: Infrastructure Services (~15 seconds)

- **PostgreSQL** - Database server

  - Startup time: ~10 seconds
  - Health check: `pg_isready` command
  - Port: 5432

- **Redis** - Cache and session store

  - Startup time: ~5 seconds
  - Health check: `PING` command
  - Port: 6379

- **Zookeeper & Kafka** - Message broker
  - Startup time: ~20 seconds
  - Health check: Port accessibility
  - Ports: 2181 (Zookeeper), 9092 (Kafka)

### Step 2: Jenkins CI/CD & ngrok (~60-90 seconds)

- **Jenkins** - Continuous Integration/Deployment

  - Startup time: 60-90 seconds (longest startup)
  - Health check: HTTP status on port 9040
  - Includes plugin installation and initialization
  - Port: 9040

- **ngrok** - Public tunnel for Jenkins
  - Startup time: ~5 seconds (after Jenkins is ready)
  - Creates public HTTPS URL for Jenkins
  - Enables GitHub webhook integration
  - Web interface: http://localhost:4040

### Step 3: Application Services (~25 seconds)

- **Backend API** - Main application backend

  - Startup time: ~25 seconds
  - Health check: `/health` endpoint
  - Port: 8001

- **Analytics Service** - Data analytics microservice

  - Startup time: ~20 seconds
  - Health check: `/health` endpoint
  - Port: 8002

- **Notifications Service** - Notification microservice
  - Startup time: ~20 seconds
  - Health check: `/health` endpoint
  - Port: 8003

### Step 4: Frontend (~20-30 seconds)

- **Frontend** - React/Next.js application
  - Startup time: 20-30 seconds
  - Health check: HTTP status on port 3000
  - Includes build and optimization
  - Port: 3000

### Step 5: Monitoring Services (~15 seconds)

- **Prometheus** - Metrics collection

  - Startup time: ~10 seconds
  - Port: 9090

- **Grafana** - Metrics visualization

  - Startup time: ~15 seconds
  - Default login: admin/admin
  - Port: 3001

- **Kafka UI** - Kafka management interface
  - Startup time: ~15 seconds
  - Port: 8080

## ⏱️ Total Startup Time

**Complete stack startup: ~2-3 minutes**

- Infrastructure: 15 seconds
- Jenkins + ngrok: 60-95 seconds
- Applications: 25 seconds
- Frontend: 20-30 seconds
- Monitoring: 15 seconds

## 🔍 Health Check Strategy

Each service uses appropriate health check methods:

1. **HTTP Services**: GET request to `/health` endpoint or base URL
2. **Database**: `pg_isready -U user -d shopdb`
3. **Redis**: `redis-cli ping`
4. **Kafka**: Port accessibility check with `nc -z`

## 🛠️ Usage Commands

### Start All Services

```bash
./start-services.sh
```

### Quick Health Check

```bash
./quick-health-check.sh
```

### Stop All Services

```bash
./stop-services.sh
```

### Comprehensive Testing

```bash
./scripts/test-all-services.sh
```

### ngrok Management

```bash
# Start ngrok tunnel for Jenkins
./start-ngrok.sh

# Check ngrok status
./check-ngrok.sh

# Stop ngrok
pkill -f ngrok
```

## 🔧 Troubleshooting

### Service Names Reference

- **Service names (docker-compose)**: postgres, redis, backend, frontend, analytics, notifications, jenkins
- **Container names (docker exec)**: shopsphere_postgres, shopsphere_redis, shopsphere_backend, etc.
- **Network name**: shopsphere-network
- **Reference script**: `./service-names-reference.sh` (shows all names and examples)

### If Services Fail to Start

1. **Check Docker Resources**

   ```bash
   docker system df
   docker system prune -f  # Clean up if needed
   ```

2. **View Service Logs**

   ```bash
   docker-compose logs [service-name]
   docker-compose logs -f [service-name]  # Follow logs
   ```

3. **Manual Health Checks**

   ```bash
   # Check PostgreSQL directly
   docker exec shopsphere_postgres pg_isready -U user -d shopdb

   # Check Redis directly
   docker exec shopsphere_redis redis-cli ping
   ```

4. **Restart Individual Service**

   ```bash
   docker-compose restart [service-name]
   ```

5. **Manual Service Start**
   ```bash
   docker-compose up -d [service-name]
   ```

### Common Issues

- **Jenkins takes long**: Normal, wait 90 seconds
- **Frontend build fails**: Check node/npm versions
- **Database connection fails**: Ensure PostgreSQL is fully ready
- **Kafka not accessible**: Wait for Zookeeper to start first

## 📊 Service Dependencies

```
Infrastructure Layer:
├── PostgreSQL (database)
├── Redis (cache)
└── Kafka + Zookeeper (messaging)
    │
Application Layer:
├── Backend API (depends on: PostgreSQL, Redis)
├── Analytics Service (depends on: Kafka, PostgreSQL)
└── Notifications Service (depends on: Kafka, Redis)
    │
Presentation Layer:
└── Frontend (depends on: Backend API)
    │
DevOps Layer:
├── Jenkins (independent, for CI/CD)
└── Monitoring (Prometheus, Grafana, Kafka UI)
```

## 🌐 GitHub Webhook Integration

- Jenkins is configured to receive GitHub webhooks
- ngrok automatically creates a public HTTPS URL for Jenkins
- The public URL is displayed when services start
- Webhook URL format: `https://your-ngrok-url.ngrok.io/github-webhook/`

### Automatic Setup

1. Run `./start-services.sh` - ngrok starts automatically
2. Copy the displayed webhook URL
3. Add it to your GitHub repository webhook settings

### Manual ngrok Control

- Start only ngrok: `./start-ngrok.sh`
- Check ngrok status: `./check-ngrok.sh`
- Stop ngrok: `pkill -f ngrok`

## 📝 Notes

- Services with health checks have retry logic (30-60 attempts)
- Sleep times are optimized based on typical startup patterns
- Infrastructure services start first to ensure dependencies are ready
- Jenkins startup is isolated due to its longer initialization time
- All services support graceful shutdown via `stop-services.sh`
