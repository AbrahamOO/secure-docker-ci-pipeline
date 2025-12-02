#!/usr/bin/env bash

#######################################
# Complete Project Verification Script
# Verifies all components of the secure-docker-ci-pipeline project
#######################################

set -euo pipefail

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo ""
echo "=========================================="
echo "  Secure Docker CI Pipeline Verification"
echo "=========================================="
echo ""

# Track overall status
FAILED=0

# Check prerequisites
echo -e "${BLUE}Checking prerequisites...${NC}"
echo ""

if command -v docker &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Docker installed: $(docker --version)"
else
    echo -e "  ${RED}✗${NC} Docker not found"
    FAILED=1
fi

if command -v docker-compose &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Docker Compose installed: $(docker-compose --version)"
else
    echo -e "  ${RED}✗${NC} Docker Compose not found"
    FAILED=1
fi

# Optional tools
if command -v hadolint &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Hadolint installed (optional): $(hadolint --version)"
else
    echo -e "  ${YELLOW}!${NC} Hadolint not installed (optional)"
fi

if command -v trivy &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Trivy installed (optional): $(trivy --version | head -n1)"
else
    echo -e "  ${YELLOW}!${NC} Trivy not installed (optional)"
fi

if command -v act &> /dev/null; then
    echo -e "  ${GREEN}✓${NC} Act installed (optional): $(act --version)"
else
    echo -e "  ${YELLOW}!${NC} Act not installed (optional)"
fi

echo ""

# Check if we should continue
if [ $FAILED -ne 0 ]; then
    echo -e "${RED}Missing required prerequisites. Please install Docker and Docker Compose.${NC}"
    exit 1
fi

# Verify project structure
echo -e "${BLUE}Verifying project structure...${NC}"
echo ""

REQUIRED_FILES=(
    "Dockerfile"
    "docker-compose.yml"
    "Makefile"
    "README.md"
    "app/main.py"
    "app/test_app.py"
    "app/requirements.txt"
    "scripts/lint_dockerfile.sh"
    "scripts/scan_image.sh"
    ".github/workflows/ci.yml"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo -e "  ${GREEN}✓${NC} $file"
    else
        echo -e "  ${RED}✗${NC} $file missing"
        FAILED=1
    fi
done

echo ""

# Build the image
echo -e "${BLUE}Building Docker image...${NC}"
echo ""

if docker-compose build > /tmp/build.log 2>&1; then
    echo -e "  ${GREEN}✓${NC} Docker image built successfully"
else
    echo -e "  ${RED}✗${NC} Docker build failed. Check /tmp/build.log for details"
    FAILED=1
fi

echo ""

# Start the service
echo -e "${BLUE}Starting services...${NC}"
echo ""

if docker-compose up -d > /tmp/compose.log 2>&1; then
    echo -e "  ${GREEN}✓${NC} Services started"
else
    echo -e "  ${RED}✗${NC} Failed to start services"
    cat /tmp/compose.log
    FAILED=1
    exit 1
fi

# Wait for service to be ready
echo ""
echo -e "${BLUE}Waiting for API to be ready...${NC}"
sleep 5

# Test endpoints
echo ""
echo -e "${BLUE}Testing API endpoints...${NC}"
echo ""

# Health check
if curl -sf http://localhost:8000/health > /dev/null; then
    HEALTH_RESPONSE=$(curl -s http://localhost:8000/health)
    echo -e "  ${GREEN}✓${NC} Health endpoint: $HEALTH_RESPONSE"
else
    echo -e "  ${RED}✗${NC} Health endpoint failed"
    FAILED=1
fi

# Root endpoint
if curl -sf http://localhost:8000/ > /dev/null; then
    echo -e "  ${GREEN}✓${NC} Root endpoint responding"
else
    echo -e "  ${RED}✗${NC} Root endpoint failed"
    FAILED=1
fi

# Create item
CREATE_RESPONSE=$(curl -sf -X POST http://localhost:8000/items \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Item","price":99.99}')
if [ $? -eq 0 ]; then
    echo -e "  ${GREEN}✓${NC} POST /items: Item created"
else
    echo -e "  ${RED}✗${NC} POST /items failed"
    FAILED=1
fi

# List items
if curl -sf http://localhost:8000/items > /dev/null; then
    echo -e "  ${GREEN}✓${NC} GET /items: Listed items"
else
    echo -e "  ${RED}✗${NC} GET /items failed"
    FAILED=1
fi

# Get specific item
if curl -sf http://localhost:8000/items/1 > /dev/null; then
    echo -e "  ${GREEN}✓${NC} GET /items/1: Retrieved item"
else
    echo -e "  ${RED}✗${NC} GET /items/1 failed"
    FAILED=1
fi

# Check container health
echo ""
echo -e "${BLUE}Checking container health...${NC}"
echo ""

HEALTH_STATUS=$(docker inspect secure-api --format='{{.State.Health.Status}}' 2>/dev/null || echo "unknown")
if [ "$HEALTH_STATUS" == "healthy" ]; then
    echo -e "  ${GREEN}✓${NC} Container health status: $HEALTH_STATUS"
else
    echo -e "  ${YELLOW}!${NC} Container health status: $HEALTH_STATUS"
fi

# Show container stats
CONTAINER_STATUS=$(docker ps --filter "name=secure-api" --format "{{.Status}}")
echo -e "  ${GREEN}✓${NC} Container status: $CONTAINER_STATUS"

# Cleanup
echo ""
echo -e "${BLUE}Cleaning up...${NC}"
echo ""

docker-compose down > /dev/null 2>&1
echo -e "  ${GREEN}✓${NC} Services stopped"

# Final summary
echo ""
echo "=========================================="
echo "  Verification Summary"
echo "=========================================="
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ ALL CHECKS PASSED!${NC}"
    echo ""
    echo "The secure-docker-ci-pipeline project is working correctly."
    echo ""
    echo "Next steps:"
    echo "  - View API docs: docker-compose up -d && open http://localhost:8000/docs"
    echo "  - Run security scan: ./scripts/scan_image.sh secure-docker-ci-pipeline-api"
    echo "  - Run Dockerfile lint: ./scripts/lint_dockerfile.sh"
    echo "  - Simulate CI pipeline: act push"
    echo "  - Read full docs: cat README.md"
    echo ""
    exit 0
else
    echo -e "${RED}✗ SOME CHECKS FAILED${NC}"
    echo ""
    echo "Please review the errors above and fix any issues."
    echo "Check logs with: docker-compose logs"
    echo ""
    exit 1
fi
