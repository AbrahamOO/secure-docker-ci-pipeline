# Secure Docker CI Pipeline

A production-ready demonstration of DevSecOps best practices featuring a containerized FastAPI microservice with comprehensive security automation, testing, and CI/CD pipeline.

## 🎯 Project Overview

This project showcases:
- **Multi-stage Docker builds** for optimized production images
- **Automated security scanning** with Trivy
- **Dockerfile linting** with Hadolint
- **Comprehensive test coverage** with pytest
- **GitHub Actions CI/CD** pipeline (runnable locally with Act)
- **Container orchestration** with Docker Compose
- **Security best practices** (non-root user, minimal base image, health checks)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:

### Required:
- **Docker** (v20.10+) - [Install Docker](https://docs.docker.com/get-docker/)
- **Docker Compose** (v2.0+) - Usually bundled with Docker Desktop

### Optional (for full CI/CD simulation):
- **Hadolint** - Dockerfile linter
  - macOS: `brew install hadolint`
  - Linux: `wget -O /usr/local/bin/hadolint https://github.com/hadolint/hadolint/releases/latest/download/hadolint-Linux-x86_64 && chmod +x /usr/local/bin/hadolint`

- **Trivy** - Container vulnerability scanner
  - macOS: `brew install aquasecurity/trivy/trivy`
  - Linux: `curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin`

- **Act** - Run GitHub Actions locally
  - macOS: `brew install act`
  - Linux: `curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash`

- **jq** - JSON processor (for scripts)
  - macOS: `brew install jq`
  - Linux: `sudo apt-get install jq` or `sudo yum install jq`

### Verification:
```bash
docker --version
docker-compose --version
hadolint --version    # Optional
trivy --version       # Optional
act --version         # Optional
```

## 🚀 Quick Start

### 1. Clone or Navigate to Project
```bash
cd secure-docker-ci-pipeline
```

### 2. Run the Application
```bash
# Build and start the service
docker-compose up --build

# Or run in detached mode
docker-compose up --build -d
```

### 3. Verify the API is Running
```bash
# Check health endpoint
curl http://localhost:8000/health

# Expected output:
# {"status":"healthy","version":"1.0.0","environment":"development"}

# Access the API
curl http://localhost:8000/

# Access interactive API documentation
open http://localhost:8000/docs  # macOS
# or visit http://localhost:8000/docs in your browser
```

### 4. Stop the Application
```bash
docker-compose down
```

## 🔧 Project Structure

```
secure-docker-ci-pipeline/
├── app/
│   ├── main.py                 # FastAPI application
│   ├── test_app.py             # Comprehensive test suite
│   └── requirements.txt        # Python dependencies
├── scripts/
│   ├── lint_dockerfile.sh      # Hadolint linting automation
│   └── scan_image.sh           # Trivy security scanning
├── .github/workflows/
│   └── ci.yml                  # GitHub Actions CI/CD pipeline
├── Dockerfile                  # Multi-stage production build
├── docker-compose.yml          # Service orchestration
└── README.md                   # This file
```

## 🧪 Testing & Verification

### Run Unit Tests Locally
```bash
# Install dependencies locally (optional)
cd app
pip install -r requirements.txt

# Run tests
pytest -v test_app.py

# Run tests with coverage
pytest --cov=main --cov-report=term-missing test_app.py
```

### Run Tests in Docker
Tests automatically run during the Docker build process. To see them:
```bash
docker build --target builder -t secure-api-test .
```

### Manual API Testing
```bash
# Start the service
docker-compose up -d

# Create an item
curl -X POST http://localhost:8000/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","description":"High-performance laptop","price":1299.99,"tax":130.00}'

# List all items
curl http://localhost:8000/items

# Get specific item
curl http://localhost:8000/items/1

# Update an item
curl -X PUT http://localhost:8000/items/1 \
  -H "Content-Type: application/json" \
  -d '{"name":"Gaming Laptop","description":"Ultimate gaming machine","price":1899.99,"tax":190.00}'

# Delete an item
curl -X DELETE http://localhost:8000/items/1

# Stop the service
docker-compose down
```

## 🔒 Security Scanning

### Lint Dockerfile (Hadolint)
```bash
# Run the linting script
./scripts/lint_dockerfile.sh

# Or run hadolint directly
hadolint Dockerfile
```

**What it checks:**
- Dockerfile best practices
- Pin versions for reproducibility
- Security vulnerabilities in Dockerfile
- Layer optimization

### Scan Container Image (Trivy)
```bash
# Build the image first
docker-compose build

# Run the scanning script
./scripts/scan_image.sh secure-docker-ci-pipeline-api

# Or run Trivy directly
trivy image secure-docker-ci-pipeline-api
```

**What it scans:**
- OS package vulnerabilities
- Application dependency vulnerabilities
- Secret detection in layers
- Configuration issues

**Output Location:**
- Console: Detailed table format
- JSON Report: `reports/trivy-report.json`

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The pipeline includes 4 jobs:

1. **Lint Dockerfile** - Validates Dockerfile against best practices
2. **Build and Test** - Builds image and runs unit tests
3. **Security Scan** - Scans for vulnerabilities with Trivy
4. **Integration Test** - Runs end-to-end API tests

### Run CI Pipeline Locally with Act

```bash
# Install Act (if not already installed)
# macOS: brew install act
# Linux: curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run the entire pipeline
act push

# Run specific job
act push -j build-and-test

# Run with different event
act pull_request

# List available workflows
act -l
```

**Note:** First run will prompt you to select a Docker image size. Choose "Medium" for best compatibility.

### Expected Pipeline Results

All jobs should pass with:
- ✅ Dockerfile linting: No violations
- ✅ Build: Multi-stage build completes
- ✅ Tests: All pytest tests pass
- ✅ Security: No critical vulnerabilities
- ✅ Integration: API endpoints respond correctly

## 🏗️ Architecture Details

### Multi-Stage Docker Build

**Stage 1: Builder**
- Installs all dependencies including test tools
- Runs complete test suite
- Fails fast if tests don't pass

**Stage 2: Production**
- Minimal Python slim image
- Only production dependencies
- Non-root user (appuser, UID 1000)
- Health check configured
- No test dependencies

### Security Features

1. **Non-root execution** - Container runs as user `appuser`
2. **Minimal base image** - Uses `python:3.11-slim`
3. **Pinned dependencies** - Exact versions in requirements.txt
4. **No cache** - PIP cache disabled to reduce image size
5. **Health checks** - Built-in container health monitoring
6. **Read-only filesystem** (can be enforced via k8s/docker-compose)

### API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Root welcome message |
| GET | `/health` | Health check endpoint |
| GET | `/docs` | Interactive API documentation (Swagger UI) |
| GET | `/items` | List all items |
| GET | `/items/{id}` | Get specific item |
| POST | `/items` | Create new item |
| PUT | `/items/{id}` | Update item |
| DELETE | `/items/{id}` | Delete item |

## 📊 Metrics & Monitoring

### Container Health Check
```bash
# Check container health status
docker inspect secure-api --format='{{.State.Health.Status}}'

# View health check logs
docker inspect secure-api --format='{{range .State.Health.Log}}{{.Output}}{{end}}'
```

### Application Logs
```bash
# View real-time logs
docker-compose logs -f api

# View last 100 lines
docker-compose logs --tail=100 api
```

## 🐛 Troubleshooting

### Issue: Port 8000 already in use
```bash
# Find process using port 8000
lsof -i :8000  # macOS/Linux
netstat -ano | findstr :8000  # Windows

# Kill the process or change port in docker-compose.yml
ports:
  - "8080:8000"  # Maps host port 8080 to container port 8000
```

### Issue: Docker build fails on tests
```bash
# Check test output
docker build --target builder .

# Run tests locally for debugging
cd app
pip install -r requirements.txt
pytest -v test_app.py
```

### Issue: Trivy scan fails
```bash
# Update Trivy database
trivy image --download-db-only

# Check if image exists
docker images | grep secure-docker-ci-pipeline

# Rebuild image
docker-compose build --no-cache
```

### Issue: Act fails to run
```bash
# Use specific platform
act -P ubuntu-latest=catthehacker/ubuntu:act-latest

# Run with verbose output
act -v

# Skip specific jobs
act push -j build-and-test
```

### Issue: Permission denied on scripts
```bash
# Make scripts executable
chmod +x scripts/*.sh
```

## 🔍 Advanced Usage

### Build Production Image Only
```bash
docker build -t secure-api:prod --target production .
docker run -p 8000:8000 secure-api:prod
```

### Run with Custom Environment Variables
```bash
docker-compose up -e ENVIRONMENT=staging
```

### Generate Security Report
```bash
./scripts/scan_image.sh secure-docker-ci-pipeline-api CRITICAL,HIGH,MEDIUM
cat reports/trivy-report.json | jq '.Results[].Vulnerabilities[] | select(.Severity=="CRITICAL")'
```

### Performance Testing
```bash
# Using Apache Bench (install with: brew install httpd)
ab -n 1000 -c 10 http://localhost:8000/health

# Using wrk (install with: brew install wrk)
wrk -t4 -c100 -d30s http://localhost:8000/health
```

## 📝 Best Practices Demonstrated

1. **Multi-stage builds** - Separate build and runtime environments
2. **Least privilege** - Run as non-root user
3. **Dependency pinning** - Exact version specifications
4. **Layer caching** - Optimize build times
5. **Health checks** - Container-level health monitoring
6. **Security scanning** - Automated vulnerability detection
7. **Linting** - Enforce Dockerfile best practices
8. **Test automation** - Tests run during build
9. **Documentation** - Comprehensive README and inline comments
10. **CI/CD** - Fully automated pipeline

## 🤝 Contributing

This is a demonstration project, but if you'd like to extend it:

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run all tests and security scans
5. Submit a pull request

## 📄 License

This project is provided as-is for educational and demonstration purposes.

## 🔗 Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [FastAPI Documentation](https://fastapi.tiangolo.com/)
- [Hadolint Rules](https://github.com/hadolint/hadolint)
- [Trivy Documentation](https://aquasecurity.github.io/trivy/)
- [GitHub Actions](https://docs.github.com/en/actions)
- [Act - Local GitHub Actions](https://github.com/nektos/act)

## ✅ Verification Checklist

Use this checklist to verify the complete setup:

- [ ] Docker and Docker Compose installed
- [ ] Project runs with `docker-compose up --build`
- [ ] API accessible at http://localhost:8000
- [ ] Health check returns healthy status
- [ ] Swagger docs accessible at http://localhost:8000/docs
- [ ] Unit tests pass during build
- [ ] Hadolint script runs successfully
- [ ] Trivy scan completes (install Trivy first)
- [ ] Act can simulate CI pipeline (install Act first)
- [ ] All API endpoints respond correctly

---

**Built with ❤️ demonstrating DevSecOps excellence**
