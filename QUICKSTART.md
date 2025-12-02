# Quick Start Guide

Get the Secure Docker CI Pipeline running in under 5 minutes!

## Prerequisites

You only need **Docker** and **Docker Compose** installed.

Check if you have them:
```bash
docker --version
docker-compose --version
```

If not, install [Docker Desktop](https://docs.docker.com/get-docker/) (includes both).

## Run the Project

### Step 1: Navigate to the project
```bash
cd secure-docker-ci-pipeline
```

### Step 2: Start the application
```bash
docker-compose up --build
```

### Step 3: Test it works
Open another terminal and run:
```bash
# Check health
curl http://localhost:8000/health

# View API docs in browser
open http://localhost:8000/docs
```

You should see:
```json
{
  "status": "healthy",
  "version": "1.0.0",
  "environment": "development"
}
```

### Step 4: Try the API
```bash
# Create an item
curl -X POST http://localhost:8000/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99}'

# List items
curl http://localhost:8000/items

# Get item #1
curl http://localhost:8000/items/1
```

### Step 5: Stop the application
```bash
# Press Ctrl+C in the terminal running docker-compose
# Or in another terminal:
docker-compose down
```

## Using the Makefile (Optional but Recommended)

The project includes a Makefile for convenience:

```bash
# Show all available commands
make help

# Build and start
make up

# Run tests
make test-docker

# Check health
make health

# Test API endpoints
make api-test

# View logs
make logs

# Stop services
make down

# Complete verification
make verify
```

## Next Steps

- Read [README.md](README.md) for detailed documentation
- Install security tools (Hadolint, Trivy) for full security scanning
- Install Act to run the CI/CD pipeline locally
- Explore the API at http://localhost:8000/docs

## Troubleshooting

**Port already in use?**
```bash
# Stop any existing containers on port 8000
docker ps | grep 8000
docker stop <container-id>
```

**Build fails?**
```bash
# Clean rebuild
docker-compose down
docker-compose build --no-cache
docker-compose up
```

**Still stuck?**
Check the [README.md](README.md) troubleshooting section or open an issue.

---

**That's it! You're running a production-grade containerized API with DevSecOps best practices.**
