.PHONY: help build up down test lint scan clean all

# Variables
IMAGE_NAME := secure-docker-ci-pipeline-api
COMPOSE := docker-compose

help: ## Show this help message
	@echo "Secure Docker CI Pipeline - Available Commands:"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	@echo "Building Docker image..."
	$(COMPOSE) build

up: ## Start the services
	@echo "Starting services..."
	$(COMPOSE) up -d
	@echo "Waiting for service to be ready..."
	@sleep 5
	@echo "Service is running at http://localhost:8000"
	@echo "API docs available at http://localhost:8000/docs"

down: ## Stop the services
	@echo "Stopping services..."
	$(COMPOSE) down

logs: ## View service logs
	$(COMPOSE) logs -f

test: ## Run unit tests locally
	@echo "Running unit tests..."
	cd app && python -m pytest -v test_app.py

test-docker: ## Run tests in Docker
	@echo "Running tests in Docker..."
	docker build --target builder -t $(IMAGE_NAME)-test .

lint: ## Lint Dockerfile with Hadolint
	@echo "Linting Dockerfile..."
	./scripts/lint_dockerfile.sh

scan: build ## Scan image for vulnerabilities
	@echo "Scanning image for vulnerabilities..."
	./scripts/scan_image.sh $(IMAGE_NAME)

ci: ## Run full CI pipeline locally with Act
	@echo "Running CI pipeline with Act..."
	act push

health: ## Check service health
	@echo "Checking service health..."
	@curl -s http://localhost:8000/health | jq .

api-test: ## Run API integration tests
	@echo "Testing API endpoints..."
	@echo "1. Root endpoint:"
	@curl -s http://localhost:8000/ | jq .
	@echo "\n2. Health check:"
	@curl -s http://localhost:8000/health | jq .
	@echo "\n3. Creating item:"
	@curl -s -X POST http://localhost:8000/items -H "Content-Type: application/json" -d '{"name":"Test Item","price":99.99}' | jq .
	@echo "\n4. Listing items:"
	@curl -s http://localhost:8000/items | jq .

clean: down ## Clean up containers and images
	@echo "Cleaning up..."
	docker rmi $(IMAGE_NAME) 2>/dev/null || true
	rm -rf reports/

rebuild: clean build up ## Clean rebuild and start

all: lint build scan up health ## Run complete workflow

status: ## Show container status
	$(COMPOSE) ps
	@echo ""
	docker inspect secure-api --format='Health Status: {{.State.Health.Status}}' 2>/dev/null || echo "Container not running"

verify: ## Verify complete setup
	@echo "=========================================="
	@echo "  Verifying Complete Setup"
	@echo "=========================================="
	@echo ""
	@echo "1. Checking Docker..."
	@docker --version
	@echo ""
	@echo "2. Checking Docker Compose..."
	@docker-compose --version
	@echo ""
	@echo "3. Building image..."
	@make build > /dev/null 2>&1 && echo "✓ Build successful" || echo "✗ Build failed"
	@echo ""
	@echo "4. Starting services..."
	@make up > /dev/null 2>&1 && echo "✓ Services started" || echo "✗ Services failed"
	@echo ""
	@echo "5. Testing health endpoint..."
	@sleep 3
	@curl -sf http://localhost:8000/health > /dev/null && echo "✓ Health check passed" || echo "✗ Health check failed"
	@echo ""
	@echo "6. Testing API..."
	@curl -sf http://localhost:8000/ > /dev/null && echo "✓ API responding" || echo "✗ API not responding"
	@echo ""
	@echo "=========================================="
	@echo "Verification complete!"
	@echo "Access API docs at: http://localhost:8000/docs"
	@echo "=========================================="
