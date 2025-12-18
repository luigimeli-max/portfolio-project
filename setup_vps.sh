#!/bin/bash
# Initial VPS Setup Script for Portfolio Project

set -e

echo "============================================"
echo "Portfolio Project - VPS Setup"
echo "============================================"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${RED}Please run as root or with sudo${NC}"
    exit 1
fi

# Get project directory
PROJECT_DIR=$(pwd)
echo -e "${BLUE}Project directory: $PROJECT_DIR${NC}"

# Step 1: Create virtual environment
echo -e "${YELLOW}Step 1: Creating virtual environment...${NC}"
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt
echo -e "${GREEN}✓ Virtual environment created${NC}"

# Step 2: Setup .env file
echo -e "${YELLOW}Step 2: Setting up environment variables...${NC}"
if [ ! -f ".env" ]; then
    SECRET_KEY=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())")
    cat > .env << EOF
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=luigimeli.work,www.luigimeli.work,38.242.208.240

DB_NAME=
DB_USER=
DB_PASSWORD=
DB_HOST=localhost
DB_PORT=5432
EOF
    echo -e "${GREEN}✓ .env file created${NC}"
else
    echo -e "${YELLOW}⚠ .env file already exists${NC}"
fi

# Step 3: Django setup
echo -e "${YELLOW}Step 3: Setting up Django...${NC}"
python manage.py migrate --noinput
python manage.py collectstatic --noinput --clear
echo -e "${GREEN}✓ Django setup complete${NC}"

# Step 4: Create superuser
echo -e "${YELLOW}Step 4: Create superuser (optional)${NC}"
read -p "Do you want to create a superuser? (y/n): " CREATE_SUPER
if [ "$CREATE_SUPER" = "y" ]; then
    python manage.py createsuperuser
fi

# Step 5: Create Gunicorn systemd service
echo -e "${YELLOW}Step 5: Creating Gunicorn service...${NC}"
cat > /etc/systemd/system/portfolio.service << EOF
[Unit]
Description=Portfolio Django Application
After=network.target

[Service]
Type=notify
User=www-data
Group=www-data
RuntimeDirectory=gunicorn
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn \\
    --config $PROJECT_DIR/gunicorn_config.py \\
    portfolio_project.wsgi:application
ExecReload=/bin/kill -s HUP \$MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF
echo -e "${GREEN}✓ Gunicorn service created${NC}"

# Step 6: Create Nginx configuration
echo -e "${YELLOW}Step 6: Creating Nginx configuration...${NC}"
cat > /etc/nginx/sites-available/portfolio << 'EOF'
upstream portfolio_app {
    server 127.0.0.1:8000;
}

server {
    listen 80;
    server_name luigimeli.work www.luigimeli.work 38.242.208.240;

    client_max_body_size 10M;

    access_log /var/log/nginx/portfolio_access.log;
    error_log /var/log/nginx/portfolio_error.log;

    location = /favicon.ico {
        access_log off;
        log_not_found off;
    }

    location /static/ {
        alias PROJECT_DIR_PLACEHOLDER/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    location /media/ {
        alias PROJECT_DIR_PLACEHOLDER/media/;
        expires 30d;
        add_header Cache-Control "public";
    }

    location / {
        proxy_pass http://portfolio_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect off;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Gzip
    gzip on;
    gzip_vary on;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml;
}
EOF

# Replace placeholder with actual project directory
sed -i "s|PROJECT_DIR_PLACEHOLDER|$PROJECT_DIR|g" /etc/nginx/sites-available/portfolio

# Enable site
ln -sf /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/
echo -e "${GREEN}✓ Nginx configuration created${NC}"

# Step 7: Set permissions
echo -e "${YELLOW}Step 7: Setting permissions...${NC}"
chown -R www-data:www-data $PROJECT_DIR
chmod -R 755 $PROJECT_DIR
echo -e "${GREEN}✓ Permissions set${NC}"

# Step 8: Start services
echo -e "${YELLOW}Step 8: Starting services...${NC}"
systemctl daemon-reload
systemctl enable portfolio
systemctl start portfolio
nginx -t && systemctl restart nginx
echo -e "${GREEN}✓ Services started${NC}"

echo ""
echo "============================================"
echo -e "${GREEN}Setup completed successfully!${NC}"
echo "============================================"
echo ""
echo "Your portfolio is now accessible at:"
echo -e "${BLUE}http://luigimeli.work${NC}"
echo -e "${BLUE}http://www.luigimeli.work${NC}"
echo -e "${BLUE}http://38.242.208.240${NC}"
echo ""
echo "Next steps:"
echo "1. Configure SSL with Let's Encrypt:"
echo "   apt install certbot python3-certbot-nginx -y"
echo "   certbot --nginx -d luigimeli.work -d www.luigimeli.work"
echo ""
echo "2. Access Django admin:"
echo "   http://luigimeli.work/admin"
echo ""
echo "Useful commands:"
echo "  - View logs: sudo journalctl -u portfolio -f"
echo "  - Restart: sudo systemctl restart portfolio"
echo "  - Deploy updates: ./deploy.sh"
echo ""
