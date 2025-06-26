#!/usr/bin/env bash
set -e

# Default values
DEFAULT_USER_NAME="developer"
DEFAULT_TAG="debian-dev:latest"
DEFAULT_NETWORK="host"
EXTRA_PACKAGES=""

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Function to display usage information
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --username USER_NAME   Specify the username (default: $DEFAULT_USER_NAME)"
    echo "  --packages PACKAGES   Specify additional packages to install (comma-separated)"
    echo "  --tag TAG            Specify the Docker image tag (default: $DEFAULT_TAG)"
    echo "  --network NETWORK    Specify the Docker network (default: $DEFAULT_NETWORK)"
    echo "  --help               Display this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --username john"
    echo "  $0 --username sarah --packages nodejs,npm,python3"
    echo "  $0 --username dev --tag custom-dev:1.0"
    echo "  $0 --username dev --network bridge"
    echo ""
}

# Function to validate username
validate_username() {
    local username=$1
    if [[ ! $username =~ ^[a-z_][a-z0-9_-]{0,31}$ ]]; then
        echo "Error: Invalid username format."
        echo "Username must start with a lowercase letter or underscore,"
        echo "and can contain only lowercase letters, digits, underscore, and hyphen."
        echo "Maximum length is 32 characters."
        exit 1
    fi
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --username)
            USER_NAME="$2"
            shift 2
            ;;
        --packages)
            EXTRA_PACKAGES="$2"
            shift 2
            ;;
        --tag)
            TAG="$2"
            shift 2
            ;;
        --network)
            NETWORK="$2"
            shift 2
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Set default values if not provided
USER_NAME=${USER_NAME:-$DEFAULT_USER_NAME}
TAG=${TAG:-$DEFAULT_TAG}
NETWORK=${NETWORK:-$DEFAULT_NETWORK}

# Validate username
validate_username "$USER_NAME"

# Format packages for docker build
if [[ -n "$EXTRA_PACKAGES" ]]; then
    # Replace commas with spaces for apt-get
    EXTRA_PACKAGES=${EXTRA_PACKAGES//,/ }
    echo "Will install additional packages: $EXTRA_PACKAGES"
fi

# Check if Dockerfile exists
if [[ ! -f "$SCRIPT_DIR/Dockerfile" ]]; then
    echo "Error: Dockerfile not found in $SCRIPT_DIR"
    exit 1
fi

# Check if inituser.sh exists
if [[ ! -f "$SCRIPT_DIR/inituser.sh" ]]; then
    echo "Error: inituser.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Make sure inituser.sh is executable
chmod +x "$SCRIPT_DIR/inituser.sh"

echo "Building Docker image with:"
echo "  Username: $USER_NAME"
echo "  Image tag: $TAG"
echo "  Network: $NETWORK"
if [[ -n "$EXTRA_PACKAGES" ]]; then
    echo "  Extra packages: $EXTRA_PACKAGES"
fi

# Build the Docker image using host network to access network tunnels (e.g., nekoray-tun)
echo "Building with host network..."
docker build \
    --network=host \
    --build-arg USER_NAME="$USER_NAME" \
    --build-arg EXTRA_PACKAGES="$EXTRA_PACKAGES" \
    -t "$TAG" \
    "$SCRIPT_DIR"

echo ""
echo "Build complete!"
echo ""
echo "To run the container:"
echo "  docker run -it --network $NETWORK --name devcontainer $TAG"
echo ""
echo "To attach to a running container:"
echo "  docker exec -it devcontainer zsh"
echo ""

