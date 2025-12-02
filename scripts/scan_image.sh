#!/usr/bin/env bash

#######################################
# Container Vulnerability Scanning Script
# Uses Trivy to scan Docker images for vulnerabilities
#######################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
IMAGE_NAME="${1:-secure-docker-ci-pipeline-api}"
SEVERITY="${2:-CRITICAL,HIGH}"
SCAN_TYPE="${3:-all}" # os, library, or all

echo "=========================================="
echo "  Container Vulnerability Scanning"
echo "=========================================="
echo ""
echo "Image: $IMAGE_NAME"
echo "Severity: $SEVERITY"
echo "Scan Type: $SCAN_TYPE"
echo ""

# Check if Trivy is installed
if ! command -v trivy &> /dev/null; then
    echo -e "${YELLOW}Warning: trivy not found${NC}"
    echo "Installing trivy..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install aquasecurity/trivy/trivy
        else
            echo -e "${RED}Error: Homebrew not found. Please install trivy manually.${NC}"
            echo "Visit: https://aquasecurity.github.io/trivy/"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
    else
        echo -e "${RED}Error: Unsupported OS. Please install trivy manually.${NC}"
        exit 1
    fi
fi

# Check if image exists
if ! docker image inspect "$IMAGE_NAME" &> /dev/null; then
    echo -e "${RED}Error: Docker image '${IMAGE_NAME}' not found${NC}"
    echo "Please build the image first with: docker-compose build"
    exit 1
fi

echo -e "${BLUE}Running Trivy security scan...${NC}"
echo ""

# Update Trivy database
echo "Updating vulnerability database..."
trivy image --download-db-only

echo ""
echo "Scanning image for vulnerabilities..."
echo ""

# Run Trivy scan
SCAN_RESULT=0
trivy image \
    --severity "$SEVERITY" \
    --scanners vuln,config,secret \
    --format table \
    --exit-code 0 \
    "$IMAGE_NAME" || SCAN_RESULT=$?

echo ""
echo "=========================================="

# Generate JSON report for CI/CD integration
REPORT_DIR="$(dirname "$(dirname "${BASH_SOURCE[0]}")")/reports"
mkdir -p "$REPORT_DIR"
REPORT_FILE="${REPORT_DIR}/trivy-report.json"

echo "Generating JSON report..."
trivy image \
    --severity "$SEVERITY" \
    --scanners vuln,config,secret \
    --format json \
    --output "$REPORT_FILE" \
    "$IMAGE_NAME"

echo "Report saved to: $REPORT_FILE"
echo ""

# Count vulnerabilities
CRITICAL_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="CRITICAL")] | length' "$REPORT_FILE")
HIGH_COUNT=$(jq '[.Results[]?.Vulnerabilities[]? | select(.Severity=="HIGH")] | length' "$REPORT_FILE")

echo "Vulnerability Summary:"
echo "  CRITICAL: $CRITICAL_COUNT"
echo "  HIGH: $HIGH_COUNT"
echo ""

# Determine exit code based on findings
if [ "$CRITICAL_COUNT" -gt 0 ]; then
    echo -e "${RED}✗ CRITICAL vulnerabilities found!${NC}"
    echo "Please review and fix critical vulnerabilities before deploying."
    exit 1
elif [ "$HIGH_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}⚠ HIGH severity vulnerabilities found${NC}"
    echo "Consider fixing high severity vulnerabilities."
    exit 0
else
    echo -e "${GREEN}✓ No critical or high severity vulnerabilities found!${NC}"
    exit 0
fi
