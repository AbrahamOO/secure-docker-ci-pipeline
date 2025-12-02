#!/usr/bin/env bash

#######################################
# Dockerfile Linting Script
# Uses Hadolint to check Dockerfile best practices
#######################################

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
DOCKERFILE="${PROJECT_ROOT}/Dockerfile"

echo "=========================================="
echo "  Dockerfile Linting with Hadolint"
echo "=========================================="
echo ""

# Check if Hadolint is installed
if ! command -v hadolint &> /dev/null; then
    echo -e "${YELLOW}Warning: hadolint not found${NC}"
    echo "Installing hadolint..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        if command -v brew &> /dev/null; then
            brew install hadolint
        else
            echo -e "${RED}Error: Homebrew not found. Please install hadolint manually.${NC}"
            echo "Visit: https://github.com/hadolint/hadolint"
            exit 1
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux - download binary
        HADOLINT_VERSION="2.12.0"
        wget -q -O /tmp/hadolint "https://github.com/hadolint/hadolint/releases/download/v${HADOLINT_VERSION}/hadolint-Linux-x86_64"
        chmod +x /tmp/hadolint
        sudo mv /tmp/hadolint /usr/local/bin/hadolint
    else
        echo -e "${RED}Error: Unsupported OS. Please install hadolint manually.${NC}"
        exit 1
    fi
fi

# Verify Dockerfile exists
if [ ! -f "$DOCKERFILE" ]; then
    echo -e "${RED}Error: Dockerfile not found at ${DOCKERFILE}${NC}"
    exit 1
fi

echo "Linting: $DOCKERFILE"
echo ""

# Run hadolint with informational output
if hadolint "$DOCKERFILE"; then
    echo ""
    echo -e "${GREEN}✓ Dockerfile linting passed!${NC}"
    echo ""
    exit 0
else
    echo ""
    echo -e "${RED}✗ Dockerfile linting failed${NC}"
    echo "Please fix the issues above and try again."
    echo ""
    exit 1
fi
