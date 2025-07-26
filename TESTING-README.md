# 🧪 ShopSphere Testing Suite

Comprehensive testing scripts for the ShopSphere e-commerce platform. These scripts verify the health, performance, and functionality of all system components.

## 📋 Available Test Scripts

### 1. 🚀 Master Test Suite
**File:** `test-all.sh`
**Purpose:** Runs all test suites and provides comprehensive overview
```bash
./test-all.sh           # Run all tests
./test-all.sh --quick   # Run only quick health check
./test-all.sh --infra   # Run only infrastructure tests
./test-all.sh --services # Run only service tests
./test-all.sh --load    # Run only load tests
./test-all.sh --help    # Show help
```

### 2. ⚡ Quick Health Check
**File:** `quick-health-check.sh`
**Purpose:** Fast verification of essential services
**Duration:** ~30 seconds
```bash
./quick-health-check.sh
```
**Tests:**
- Backend API health
- Frontend availability
- Microservices health
- Jenkins accessibility
- Monitoring services

### 3. 🏗️ Infrastructure Testing
**File:** `infrastructure-test.sh`
**Purpose:** Deep testing of databases, messaging, and infrastructure
**Duration:** ~2-3 minutes
```bash
./infrastructure-test.sh
```
**Tests:**
- PostgreSQL (connection, queries, performance)
- Redis (operations, data types, performance)
- Kafka (topics, messaging)
- Docker containers health
- Network connectivity
- Storage volumes

### 4. 🔍 Comprehensive Service Testing
**File:** `comprehensive-service-test.sh`
**Purpose:** Detailed testing of all services and APIs
**Duration:** ~3-5 minutes
```bash
./comprehensive-service-test.sh
```
**Tests:**
- All HTTP endpoints
- API health checks
- Database operations
- Microservices functionality
- Monitoring systems
- CI/CD services
- Container health
- Performance samples

### 5. ⚡ Load Testing
**File:** `load-test.sh`
**Purpose:** Performance and stress testing
**Duration:** ~2-4 minutes
```bash
./load-test.sh
```
**Tests:**
- API load testing
- Stress testing with increasing load
- Response time measurement
- Endpoint performance
- Concurrent user simulation

## 🎯 Service Overview

### Core Services
| Service | Port | Health Check | Purpose |
|---------|------|--------------|---------|
| Backend API | 8001 | `/health` | Main application API |
| Frontend | 3000 | `/` | Next.js web interface |
| Analytics | 8002 | `/health` | Analytics microservice |
| Notifications | 8003 | `/health` | Notification microservice |

### Infrastructure
| Service | Port | Purpose |
|---------|------|---------|
| PostgreSQL | 5432 | Primary database |
| Redis | 6379 | Cache and sessions |
| Kafka | 9092 | Message broker |
| Zookeeper | 2181 | Kafka coordination |

### Monitoring & Management
| Service | Port | Purpose |
|---------|------|---------|
| Jenkins | 9040 | CI/CD pipeline |
| Prometheus | 9090 | Metrics collection |
| Grafana | 3001 | Dashboards (admin/admin) |
| Kafka UI | 8080 | Kafka management |

## 🚀 Quick Start

1. **Quick System Check:**
   ```bash
   ./quick-health-check.sh
   ```

2. **Full System Test:**
   ```bash
   ./test-all.sh
   ```

3. **Infrastructure Only:**
   ```bash
   ./infrastructure-test.sh
   ```

4. **Performance Testing:**
   ```bash
   ./load-test.sh
   ```

## 📊 Understanding Results

### Exit Codes
- `0`: All tests passed
- `1`: Some tests failed (check output for details)

### Result Indicators
- ✅ **PASSED**: Test completed successfully
- ❌ **FAILED**: Test failed, requires attention
- ⚠️ **WARNING**: Test passed with minor issues
- ❓ **MISSING**: Required component not found

### Success Rates
- **90%+**: Excellent system health
- **75-89%**: Good, minor issues
- **50-74%**: Fair, several issues need attention
- **<50%**: Critical, immediate action required

## 🔧 Prerequisites

### Required Tools
- `curl` - HTTP requests
- `docker` - Container management
- `redis-cli` - Redis testing
- `psql` - PostgreSQL testing (optional)
- `ab` - Apache Bench for load testing (optional)

### Optional Tools for Enhanced Testing
```bash
# macOS
brew install postgresql redis apache-bench

# Ubuntu/Debian
sudo apt-get install postgresql-client redis-tools apache2-utils

# Docker alternative (no local tools needed)
# All tests can run using Docker containers
```

## 🐛 Troubleshooting

### Common Issues

**1. Service Not Accessible**
```bash
# Check if containers are running
docker ps | grep shopsphere

# Check container logs
docker logs shopsphere_backend
```

**2. Database Connection Failed**
```bash
# Test PostgreSQL
PGPASSWORD=password psql -h localhost -U user -d shopdb -c "SELECT 1;"

# Test Redis
redis-cli -h localhost -p 6379 ping
```

**3. Performance Issues**
```bash
# Check resource usage
docker stats

# Check system resources
top
df -h
```

### Getting Help

1. **Check Container Logs:**
   ```bash
   docker-compose logs <service_name>
   ```

2. **Restart Services:**
   ```bash
   docker-compose restart <service_name>
   ```

3. **Full System Restart:**
   ```bash
   docker-compose down && docker-compose up -d
   ```

## 📈 Monitoring Recommendations

1. **Set up Grafana Dashboards**
   - Service health metrics
   - Performance monitoring
   - Error rate tracking

2. **Configure Prometheus Alerts**
   - Service downtime
   - High response times
   - Error rate thresholds

3. **Regular Testing Schedule**
   - Run quick health checks every hour
   - Full infrastructure tests daily
   - Load testing weekly

## 🔄 CI/CD Integration

These scripts can be integrated into your CI/CD pipeline:

```yaml
# Example Jenkins pipeline step
steps:
  - name: "Health Check"
    script: "./quick-health-check.sh"
  
  - name: "Full Testing"
    script: "./test-all.sh"
```

## 📝 Contributing

To add new tests:

1. Create test script following existing patterns
2. Add to `test-all.sh` master suite
3. Update this documentation
4. Test thoroughly before committing

## 🎉 Success Indicators

Your ShopSphere system is healthy when:
- ✅ All services return HTTP 200/healthy status
- ✅ Database operations complete successfully
- ✅ Message queues are operational
- ✅ Load tests show good performance
- ✅ No container health check failures

Happy testing! 🚀
