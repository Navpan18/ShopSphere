# 🛍️ ShopSphere

A modern, cloud-native e-commerce platform built with microservices architecture, featuring real-time analytics, event-driven messaging, and comprehensive monitoring capabilities.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Services](#services)
- [CI/CD Pipeline](#cicd-pipeline)
- [Monitoring & Observability](#monitoring--observability)
- [Testing](#testing)
- [Deployment](#deployment)
- [Contributing](#contributing)

## 🎯 Overview

ShopSphere is a full-stack e-commerce application demonstrating modern DevOps practices and microservices architecture. The platform supports product management, user authentication, shopping cart functionality, order processing, and real-time analytics. 

## 🏗️ Architecture

The application follows a microservices architecture with the following components:

```
┌─────────────┐     ┌─────────────┐      ┌────────────┐
│   Frontend  │────▶│   Backend   │────▶│  PostgreSQL │
│  (Next.js)  │     │  (FastAPI)  │      │             │
└─────────────┘     └─────────────┘      └─────────────┘
                           │
                           ├──────────▶┌─────────────┐
                           │           │    Redis    │
                           │           └─────────────┘
                           │
                           ├──────────▶┌─────────────┐
                           │           │    Kafka    │
                           │           └──────┬──────┘
                           │                  │
                    ┌──────┴────────┬────────┴──────────┐
                    ▼               ▼                    ▼
            ┌─────────────┐ ┌─────────────┐    ┌──────────────┐
            │  Analytics  │ │Notification │    │  Monitoring  │
            │  Service    │ │  Service    │    │ (Prometheus) │
            └─────────────┘ └─────────────┘    └──────────────┘
```

## ✨ Features

### Core Functionality
- 🛒 **Product Catalog** - Browse and search products
- 👤 **User Authentication** - Secure JWT-based authentication
- 🛍️ **Shopping Cart** - Real-time cart management
- 💳 **Payment Integration** - Stripe payment processing
- 📦 **Order Management** - Track orders and order history

### Advanced Features
- 📊 **Real-time Analytics** - Track user behavior and sales metrics
- 🔔 **Event-Driven Notifications** - Kafka-based messaging system
- 📈 **Monitoring Dashboard** - Prometheus + Grafana integration
- 🚀 **CI/CD Pipeline** - Automated Jenkins deployment
- 🐳 **Containerized Deployment** - Docker & Docker Compose
- ☸️ **Kubernetes Ready** - K8s manifests included
- 🏗️ **Infrastructure as Code** - Terraform configurations

## 🛠️ Tech Stack

### Frontend
- **Framework:** Next.js 14
- **Language:** JavaScript (React 18)
- **Styling:** Tailwind CSS
- **HTTP Client:** Axios
- **UI/UX:** React Hot Toast, NProgress

### Backend
- **Framework:** FastAPI
- **Language:** Python 3.11
- **ORM:** SQLAlchemy
- **Database:** PostgreSQL 14
- **Migration:** Alembic
- **Authentication:** JWT (python-jose)
- **Payment:** Stripe

### Microservices
- **Analytics Service:** Python FastAPI
- **Notification Service:** Python FastAPI
- **Message Broker:** Apache Kafka
- **Cache:** Redis

### DevOps & Infrastructure
- **Containerization:** Docker, Docker Compose
- **Orchestration:** Kubernetes
- **CI/CD:** Jenkins
- **IaC:** Terraform
- **Monitoring:** Prometheus, Grafana
- **Kafka UI:** Provectus Kafka UI

## 📦 Prerequisites

Before running this project, ensure you have:

- **Docker** (version 20.10+)
- **Docker Compose** (version 2.0+)
- **Node.js** (version 18+) - for local frontend development
- **Python** (version 3.11+) - for local backend development
- **Git**

Optional (for advanced usage):
- Jenkins (for CI/CD)
- Kubernetes cluster (for K8s deployment)
- Terraform (for infrastructure provisioning)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/Navpan18/ShopSphere.git
cd ShopSphere
```

### 2. Environment Configuration

Create a `.env` file in the root directory (use `.env.example` as template):

```bash
cp .env.example .env
```

Configure the following environment variables:

```env
# Database
POSTGRES_USER=user
POSTGRES_PASSWORD=password
POSTGRES_DB=shopdb
DATABASE_URL=postgresql://user:password@postgres:5432/shopdb

# Redis
REDIS_URL=redis://redis:6379

# Kafka
KAFKA_BOOTSTRAP_SERVERS=kafka:9092

# JWT
SECRET_KEY=your-secret-key-here
ALGORITHM=HS256

# Stripe (optional)
STRIPE_SECRET_KEY=your-stripe-secret-key
STRIPE_PUBLISHABLE_KEY=your-stripe-publishable-key

# Frontend
NEXT_PUBLIC_API_URL=http://localhost:8001
```

### 3. Start the Application

#### Using Docker Compose (Recommended)

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

#### Using Make (Alternative)

```bash
# Start services
make up

# View logs
make logs

# Stop services
make down

# Clean up
make clean
```

### 4. Access the Application

Once all services are running:

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8001
- **API Documentation:** http://localhost:8001/docs
- **Analytics Service:** http://localhost:8002
- **Notification Service:** http://localhost:8003
- **Kafka UI:** http://localhost:8080
- **Prometheus:** http://localhost:9090
- **Grafana:** http://localhost:3001 (admin/admin)

### 5. Health Check

Run the health check script:

```bash
./quick-health-check.sh
```

## 📡 Services

### Backend API (Port 8001)

FastAPI-based REST API providing:

- User authentication and authorization
- Product management
- Shopping cart operations
- Order processing
- Payment integration

**Key Endpoints:**
- `GET /health` - Health check
- `POST /api/auth/register` - User registration
- `POST /api/auth/login` - User login
- `GET /api/products` - List products
- `POST /api/cart` - Add to cart
- `POST /api/orders` - Create order

### Frontend (Port 3000)

Next.js server-side rendered application with:

- Product browsing and search
- User authentication UI
- Shopping cart management
- Checkout and payment flow
- Order history

### Analytics Service (Port 8002)

Microservice for tracking and analyzing:

- User behavior and events
- Sales metrics
- Product performance
- Real-time dashboards

### Notification Service (Port 8003)

Event-driven service handling:

- Order confirmations
- Payment notifications
- User alerts
- Email/SMS notifications

## 🔄 CI/CD Pipeline

The project includes a Jenkins pipeline (`Jenkinsfile`) that:

1. **Initialize** - Sets up build environment
2. **Cleanup** - Removes old containers and images
3. **Build** - Creates Docker images for all services
4. **Test** - Runs container health checks
5. **Deploy** - Tags and publishes images

### Running the Pipeline

1. Set up Jenkins with Docker support
2. Create a new Pipeline job
3. Point to the repository's Jenkinsfile
4. Configure webhooks for automatic builds

### Alternative Jenkins Configurations

The repository includes multiple Jenkinsfile variations: 
- `Jenkinsfile` - Main build-only pipeline
- `Jenkinsfile.simple` - Simplified pipeline
- `Jenkinsfile.comprehensive` - Full pipeline with testing

## 📊 Monitoring & Observability

### Prometheus

Access metrics at `http://localhost:9090`

Key metrics tracked:
- HTTP request rates
- Response times
- Error rates
- Resource usage

### Grafana

Access dashboards at `http://localhost:3001`

Pre-configured dashboards:
- Application Overview
- Service Health
- Kafka Metrics
- Resource Utilization

### Kafka UI

Monitor Kafka topics and messages at `http://localhost:8080`

## 🧪 Testing

### Backend Tests

```bash
cd backend
pytest
pytest --cov=app tests/
```

### Frontend Tests

```bash
cd frontend
npm test
npm run test:coverage
```

### Integration Tests

```bash
# Test all services
./test-all-services.sh

# Test infrastructure
./infrastructure-test.sh

# Load testing
./load-test.sh
```

## 🚀 Deployment

### Docker Compose (Development)

```bash
docker-compose up -d
```

### Docker Compose (Production)

```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

### Kubernetes

```bash
# Apply all manifests
kubectl apply -f k8s/

# Check deployment status
kubectl get pods -n shopsphere

# Access services
kubectl port-forward svc/frontend 3000:3000
kubectl port-forward svc/backend 8001:8001
```

## 📁 Project Structure

```
ShopSphere/
├── backend/                 # FastAPI backend service
│   ├── app/
│   │   ├── api/            # API routes
│   │   ├── models/         # Database models
│   │   ├── schemas/        # Pydantic schemas
│   │   └── main.py         # Application entry point
│   ├── alembic/            # Database migrations
│   ├── Dockerfile
│   └── requirements.txt
├── frontend/               # Next.js frontend
│   ├── src/
│   │   ├── app/           # App router pages
│   │   ├── components/    # React components
│   │   └── lib/          # Utilities
│   ├── Dockerfile
│   └── package.json
├── microservices/
│   ├── analytics-service/  # Analytics microservice
│   └── notification-service/ # Notification microservice
├── k8s/                    # Kubernetes manifests
├── terraform/              # Infrastructure as Code
├── monitoring/             # Monitoring configurations
├── scripts/                # Utility scripts
├── docker-compose.yml      # Docker Compose configuration
├── Jenkinsfile            # CI/CD pipeline
└── README. md
```

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

For issues, questions, or contributions:

- **GitHub Issues:** [Create an issue](https://github.com/Navpan18/ShopSphere/issues)
- **GitHub:** [@Navpan18](https://github.com/Navpan18)

## 🙏 Acknowledgments

- FastAPI for the excellent Python framework
- Next.js team for the React framework
- Apache Kafka for event streaming
- Prometheus & Grafana for monitoring
- The open-source community

---

**Note:** This is a demonstration project showcasing modern DevOps and microservices architecture. For production use, ensure proper security configurations, secrets management, and scaling strategies. 
