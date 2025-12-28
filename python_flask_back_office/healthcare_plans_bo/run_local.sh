#!/bin/bash

#############################################################################
# Local Development Runner Script
# Location: python_flask_back_office/healthcare_plans_bo/run_local.sh
#
# This script allows developers to run either V1 or V2 of the Flask app
# locally for development and testing.
#
# Usage:
#   ./run_local.sh          # Interactive mode (choose version)
#   ./run_local.sh v1       # Run V1 directly
#   ./run_local.sh v2       # Run V2 directly
#   ./run_local.sh docker   # Run with Docker (interactive)
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PORT_V1=8080
PORT_V2=8081

print_header() {
    echo ""
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║           YourHealthPlans - Local Development                ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_menu() {
    echo -e "${YELLOW}Select which version to run:${NC}"
    echo ""
    echo "  1) Run V1 (Original API)     - Port $PORT_V1"
    echo "  2) Run V2 (New Modular API)  - Port $PORT_V2"
    echo "  3) Run V1 with Docker"
    echo "  4) Run V2 with Docker"
    echo "  5) Run Both V1 and V2 (Docker Compose)"
    echo "  6) Exit"
    echo ""
}

check_python_deps() {
    echo -e "${YELLOW}Checking Python dependencies...${NC}"
    
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}Creating virtual environment...${NC}"
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    if [ "$1" == "v2" ]; then
        pip install -r v2/requirements_v2.txt -q
    else
        pip install -r requirements.txt -q
    fi
    
    echo -e "${GREEN}Dependencies installed.${NC}"
}

run_v1() {
    echo ""
    echo -e "${GREEN}Starting V1 Flask API on port $PORT_V1...${NC}"
    echo ""
    
    check_python_deps "v1"
    
    export FLASK_ENV=development
    export PORT=$PORT_V1
    
    python run.py
}

run_v2() {
    echo ""
    echo -e "${GREEN}Starting V2 Flask API on port $PORT_V2...${NC}"
    echo ""
    
    check_python_deps "v2"
    
    export FLASK_ENV=development
    export PORT=$PORT_V2
    
    python v2/run_v2.py
}

run_v1_docker() {
    echo ""
    echo -e "${GREEN}Building and running V1 with Docker...${NC}"
    echo ""
    
    docker build -t healthcare-plans-bo:v1 -f Dockerfile .
    docker run -p $PORT_V1:8080 --rm --name healthcare-bo-v1 healthcare-plans-bo:v1
}

run_v2_docker() {
    echo ""
    echo -e "${GREEN}Building and running V2 with Docker...${NC}"
    echo ""
    
    docker build -t healthcare-plans-bo:v2 -f Dockerfile.v2 .
    docker run -p $PORT_V2:8080 --rm --name healthcare-bo-v2 healthcare-plans-bo:v2
}

run_both_docker() {
    echo ""
    echo -e "${GREEN}Running both V1 and V2 with Docker Compose...${NC}"
    echo ""
    
    if [ ! -f "docker-compose.yml" ]; then
        echo -e "${RED}docker-compose.yml not found. Creating...${NC}"
        create_docker_compose
    fi
    
    docker-compose up --build
}

create_docker_compose() {
    cat > docker-compose.yml << 'EOF'
version: '3.8'

services:
  healthcare-bo-v1:
    build:
      context: .
      dockerfile: Dockerfile
    ports:
      - "8080:8080"
    environment:
      - FLASK_ENV=development
      - PORT=8080
    container_name: healthcare-bo-v1

  healthcare-bo-v2:
    build:
      context: .
      dockerfile: Dockerfile.v2
    ports:
      - "8081:8080"
    environment:
      - FLASK_ENV=development
      - PORT=8080
    container_name: healthcare-bo-v2
EOF
    echo -e "${GREEN}docker-compose.yml created.${NC}"
}

# Main script
print_header

# Check for command line argument
if [ "$1" == "v1" ]; then
    run_v1
    exit 0
elif [ "$1" == "v2" ]; then
    run_v2
    exit 0
elif [ "$1" == "docker" ]; then
    print_menu
fi

# Interactive mode
while true; do
    print_menu
    read -p "Enter choice [1-6]: " choice
    
    case $choice in
        1)
            run_v1
            break
            ;;
        2)
            run_v2
            break
            ;;
        3)
            run_v1_docker
            break
            ;;
        4)
            run_v2_docker
            break
            ;;
        5)
            run_both_docker
            break
            ;;
        6)
            echo -e "${YELLOW}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done
