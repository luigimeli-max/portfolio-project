#!/bin/bash
# Deployment script for Portfolio Project

echo "==================================="
echo "Portfolio Deployment Script"
echo "==================================="

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get current directory
PROJECT_DIR=$(pwd)

echo -e "${YELLOW}1. Pulling latest code...${NC}"
git pull origin main

echo -e "${YELLOW}2. Activating virtual environment...${NC}"
source venv/bin/activate

echo -e "${YELLOW}3. Installing dependencies...${NC}"
pip install -r requirements.txt

echo -e "${YELLOW}4. Running migrations...${NC}"
python manage.py migrate --noinput

echo -e "${YELLOW}5. Collecting static files...${NC}"
python manage.py collectstatic --noinput --clear

echo -e "${YELLOW}6. Restarting Gunicorn...${NC}"
sudo systemctl restart portfolio

echo -e "${YELLOW}7. Restarting Nginx...${NC}"
sudo systemctl restart nginx

echo -e "${GREEN}==================================="
echo "Deployment completed successfully!"
echo "===================================${NC}"

# Check service status
if systemctl is-active --quiet portfolio; then
    echo -e "${GREEN}✓ Gunicorn is running${NC}"
else
    echo -e "${RED}✗ Gunicorn is not running${NC}"
    sudo systemctl status portfolio
fi

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx is running${NC}"
else
    echo -e "${RED}✗ Nginx is not running${NC}"
    sudo systemctl status nginx
fi
