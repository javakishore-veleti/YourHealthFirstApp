#!/bin/bash

#############################################################################
# Local Development Runner Script
# Location: python_flask_back_office/healthcare_plans_bo/run_local.sh
#
# This script allows developers to run V1, V2, or V3 of the Flask app
# locally for development and testing.
#
# Usage:
#   ./run_local.sh          # Interactive mode (choose version)
#   ./run_local.sh v1       # Run V1 directly
#   ./run_local.sh v2       # Run V2 directly
#   ./run_local.sh v3       # Run V3 directly (requires MySQL)
#   ./run_local.sh docker   # Run with Docker (interactive)
#############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
PORT_V1=8080
PORT_V2=8081
PORT_V3=8082

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
    echo "  1) Run V1 (Original API)        - Port $PORT_V1  [SQLite]"
    echo "  2) Run V2 (Modular API)         - Port $PORT_V2  [SQLite]"
    echo "  3) Run V3 (MySQL API)           - Port $PORT_V3  [MySQL - requires Docker]"
    echo ""
    echo -e "${CYAN}  Docker Options:${NC}"
    echo "  4) Run V1 with Docker"
    echo "  5) Run V2 with Docker"
    echo "  6) Run V3 with Docker + MySQL   [Recommended for V3]"
    echo "  7) Start MySQL only (for V3 local dev)"
    echo "  8) Stop all Docker containers"
    echo ""
    echo "  9) Exit"
    echo ""
}

check_python_deps() {
    echo -e "${YELLOW}Checking Python dependencies...${NC}"
    
    if [ ! -d "venv" ]; then
        echo -e "${YELLOW}Creating virtual environment...${NC}"
        python3 -m venv venv
    fi
    
    source venv/bin/activate
    
    if [ "$1" == "v3" ]; then
        pip install -r requirements-v3.txt -q
    elif [ "$1" == "v2" ]; then
        pip install -r v2/requirements_v2.txt -q
    else
        pip install -r requirements.txt -q
    fi
    
    echo -e "${GREEN}Dependencies installed.${NC}"
}

check_mysql_running() {
    if docker ps | grep -q "healthcare-mysql-v3"; then
        return 0
    else
        return 1
    fi
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

run_v3() {
    echo ""
    echo -e "${GREEN}Starting V3 Flask API on port $PORT_V3...${NC}"
    echo ""
    
    # Check if MySQL is running
    if ! check_mysql_running; then
        echo -e "${YELLOW}MySQL is not running. Starting MySQL container...${NC}"
        start_mysql_only
        echo -e "${YELLOW}Waiting for MySQL to be ready...${NC}"
        sleep 10
    fi
    
    check_python_deps "v3"
    
    # Load environment variables from .env.v3.local
    if [ -f ".env.v3.local" ]; then
        export $(cat .env.v3.local | grep -v '^#' | xargs)
    fi
    
    export FLASK_ENV=development
    export PORT=$PORT_V3
    
    python v3/run_v3.py
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

run_v3_docker() {
    echo ""
    echo -e "${GREEN}Running V3 with Docker Compose (Flask + MySQL + phpMyAdmin)...${NC}"
    echo ""
    
    docker-compose -f docker-compose-v3.yml up --build
}

start_mysql_only() {
    echo ""
    echo -e "${GREEN}Starting MySQL container for V3 development...${NC}"
    echo ""
    
    # Start only MySQL service from docker-compose
    docker-compose -f docker-compose-v3.yml up -d mysql
    
    echo ""
    echo -e "${GREEN}MySQL started!${NC}"
    echo -e "  Host: localhost"
    echo -e "  Port: 4306"
    echo -e "  Database: healthcare_db"
    echo -e "  User: healthcare_app"
    echo -e "  Password: healthcare_password"
    echo ""
    echo -e "${YELLOW}You can also access phpMyAdmin at http://localhost:8081${NC}"
    echo -e "${YELLOW}Starting phpMyAdmin...${NC}"
    docker-compose -f docker-compose-v3.yml up -d phpmyadmin
    echo ""
}

stop_all_docker() {
    echo ""
    echo -e "${YELLOW}Stopping all Docker containers...${NC}"
    echo ""
    
    # Stop V3 services
    docker-compose -f docker-compose-v3.yml down 2>/dev/null || true
    
    # Stop individual containers
    docker stop healthcare-bo-v1 2>/dev/null || true
    docker stop healthcare-bo-v2 2>/dev/null || true
    docker stop healthcare-flask-v3 2>/dev/null || true
    docker stop healthcare-mysql-v3 2>/dev/null || true
    docker stop healthcare-phpmyadmin 2>/dev/null || true
    
    echo -e "${GREEN}All containers stopped.${NC}"
}

# Main script
print_header

# Check for command line argument
case "$1" in
    v1)
        run_v1
        exit 0
        ;;
    v2)
        run_v2
        exit 0
        ;;
    v3)
        run_v3
        exit 0
        ;;
    docker)
        # Fall through to interactive mode
        ;;
    mysql)
        start_mysql_only
        exit 0
        ;;
    stop)
        stop_all_docker
        exit 0
        ;;
esac

# Interactive mode
while true; do
    print_menu
    read -p "Enter choice [1-9]: " choice
    
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
            run_v3
            break
            ;;
        4)
            run_v1_docker
            break
            ;;
        5)
            run_v2_docker
            break
            ;;
        6)
            run_v3_docker
            break
            ;;
        7)
            start_mysql_only
            break
            ;;
        8)
            stop_all_docker
            break
            ;;
        9)
            echo -e "${YELLOW}Exiting...${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Invalid option. Please try again.${NC}"
            ;;
    esac
done
