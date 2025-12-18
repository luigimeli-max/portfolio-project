#!/bin/bash
#############################################################################
# Script di configurazione completa VPS Ubuntu 24 per Django Portfolio
# Domini: luigimeli.work, www.luigimeli.work
# IP: 38.242.208.240
#############################################################################

set -e  # Exit on error

echo "==================================================="
echo "SETUP VPS UBUNTU 24 - PORTFOLIO DJANGO"
echo "==================================================="

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variabili di configurazione
DOMAIN="luigimeli.work"
APP_NAME="portfolio"
APP_USER="portfolio"
APP_DIR="/home/$APP_USER/portfolio_project"
VENV_DIR="$APP_DIR/venv"
DB_NAME="portfolio_db"
DB_USER="portfolio_user"
DB_PASSWORD="ChangeMeToSecurePassword123!"  # CAMBIA QUESTO!

echo -e "${YELLOW}Attenzione: Modifica le password nel file prima di eseguire!${NC}"
echo ""

# 1. UPDATE DEL SISTEMA
echo -e "${GREEN}[1/12] Aggiornamento sistema...${NC}"
sudo apt update
sudo apt upgrade -y

# 2. INSTALLAZIONE PACCHETTI BASE
echo -e "${GREEN}[2/12] Installazione pacchetti base...${NC}"
sudo apt install -y \
    python3.12 \
    python3.12-venv \
    python3-pip \
    postgresql \
    postgresql-contrib \
    nginx \
    git \
    supervisor \
    ufw \
    certbot \
    python3-certbot-nginx \
    build-essential \
    libpq-dev \
    python3-dev \
    curl \
    wget

# 3. CONFIGURAZIONE FIREWALL
echo -e "${GREEN}[3/12] Configurazione firewall UFW...${NC}"
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw --force enable

# 4. CREAZIONE UTENTE APPLICAZIONE
echo -e "${GREEN}[4/12] Creazione utente applicazione...${NC}"
if ! id "$APP_USER" &>/dev/null; then
    sudo adduser --system --group --home /home/$APP_USER --shell /bin/bash $APP_USER
    echo -e "${GREEN}Utente $APP_USER creato${NC}"
else
    echo -e "${YELLOW}Utente $APP_USER esiste già${NC}"
fi

# 5. CONFIGURAZIONE POSTGRESQL
echo -e "${GREEN}[5/12] Configurazione PostgreSQL...${NC}"
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Crea database e utente
sudo -u postgres psql <<EOF
-- Crea utente se non esiste
DO \$\$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_user WHERE usename = '$DB_USER') THEN
        CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';
    END IF;
END
\$\$;

-- Crea database se non esiste
SELECT 'CREATE DATABASE $DB_NAME OWNER $DB_USER'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = '$DB_NAME')\gexec

-- Assegna privilegi
ALTER ROLE $DB_USER SET client_encoding TO 'utf8';
ALTER ROLE $DB_USER SET default_transaction_isolation TO 'read committed';
ALTER ROLE $DB_USER SET timezone TO 'Europe/Rome';
GRANT ALL PRIVILEGES ON DATABASE $DB_NAME TO $DB_USER;
EOF

echo -e "${GREEN}Database PostgreSQL configurato${NC}"

# 6. CREAZIONE DIRECTORY PROGETTO
echo -e "${GREEN}[6/12] Creazione directory progetto...${NC}"
sudo mkdir -p $APP_DIR
sudo chown -R $APP_USER:$APP_USER $APP_DIR

# 7. CREAZIONE DIRECTORY LOG
echo -e "${GREEN}[7/12] Creazione directory log...${NC}"
sudo mkdir -p /var/log/gunicorn
sudo chown -R $APP_USER:$APP_USER /var/log/gunicorn
sudo mkdir -p /var/run/gunicorn
sudo chown -R $APP_USER:$APP_USER /var/run/gunicorn

# 8. CREAZIONE FILE .ENV
echo -e "${GREEN}[8/12] Creazione file .env produzione...${NC}"
sudo -u $APP_USER bash <<EOF
cat > $APP_DIR/.env <<EOL
# Django Configuration
SECRET_KEY=$(python3 -c 'from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())')
DEBUG=False
ALLOWED_HOSTS=luigimeli.work,www.luigimeli.work,38.242.208.240

# Database Configuration
DB_NAME=$DB_NAME
DB_USER=$DB_USER
DB_PASSWORD=$DB_PASSWORD
DB_HOST=localhost
DB_PORT=5432

# Email Configuration (opzionale - configurare se necessario)
# EMAIL_HOST=smtp.gmail.com
# EMAIL_PORT=587
# EMAIL_HOST_USER=your-email@gmail.com
# EMAIL_HOST_PASSWORD=your-app-password
EOL
echo -e "${GREEN}File .env creato${NC}"
EOF

# 9. CONFIGURAZIONE GUNICORN SYSTEMD
echo -e "${GREEN}[9/12] Configurazione Gunicorn systemd...${NC}"
sudo tee /etc/systemd/system/gunicorn.service > /dev/null <<EOF
[Unit]
Description=Gunicorn daemon for Django Portfolio
After=network.target

[Service]
User=$APP_USER
Group=$APP_USER
WorkingDirectory=$APP_DIR
Environment="PATH=$VENV_DIR/bin"
ExecStart=$VENV_DIR/bin/gunicorn \\
    --config $APP_DIR/gunicorn_config.py \\
    portfolio_project.wsgi:application

Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

# 10. CONFIGURAZIONE NGINX
echo -e "${GREEN}[10/12] Configurazione Nginx...${NC}"
sudo tee /etc/nginx/sites-available/$APP_NAME > /dev/null <<'EOF'
upstream portfolio_app {
    server 127.0.0.1:8000 fail_timeout=0;
}

server {
    listen 80;
    server_name luigimeli.work www.luigimeli.work 38.242.208.240;
    
    client_max_body_size 10M;
    
    # Logging
    access_log /var/log/nginx/portfolio_access.log;
    error_log /var/log/nginx/portfolio_error.log;

    # Static files
    location /static/ {
        alias /home/portfolio/portfolio_project/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }

    # Media files
    location /media/ {
        alias /home/portfolio/portfolio_project/media/;
        expires 30d;
    }

    # Proxy to Gunicorn
    location / {
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Host $http_host;
        proxy_redirect off;
        proxy_pass http://portfolio_app;
    }
}
EOF

# Abilita il sito
sudo ln -sf /etc/nginx/sites-available/$APP_NAME /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default

# Test configurazione Nginx
sudo nginx -t

# 11. RIAVVIO SERVIZI
echo -e "${GREEN}[11/12] Riavvio servizi...${NC}"
sudo systemctl daemon-reload
sudo systemctl restart nginx
sudo systemctl enable nginx

# 12. INSTALLAZIONE CERTIFICATO SSL (Let's Encrypt)
echo -e "${GREEN}[12/12] Configurazione SSL con Let's Encrypt...${NC}"
echo -e "${YELLOW}NOTA: Assicurati che i DNS puntino correttamente a questo server!${NC}"
echo -e "${YELLOW}Premi CTRL+C per saltare, altrimenti premi ENTER per continuare...${NC}"
read

sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN || {
    echo -e "${YELLOW}Certificato SSL non installato. Puoi eseguirlo manualmente dopo:${NC}"
    echo "sudo certbot --nginx -d $DOMAIN -d www.$DOMAIN"
}

# Rinnovo automatico certificato
sudo systemctl enable certbot.timer

echo ""
echo -e "${GREEN}==================================================="
echo "SETUP VPS COMPLETATO!"
echo "===================================================${NC}"
echo ""
echo -e "${YELLOW}PROSSIMI PASSI:${NC}"
echo "1. Clona il repository nel server:"
echo "   sudo -u $APP_USER git clone <your-repo-url> $APP_DIR"
echo ""
echo "2. Crea virtual environment e installa dipendenze:"
echo "   sudo -u $APP_USER python3 -m venv $VENV_DIR"
echo "   sudo -u $APP_USER $VENV_DIR/bin/pip install --upgrade pip"
echo "   sudo -u $APP_USER $VENV_DIR/bin/pip install -r $APP_DIR/requirements.txt"
echo ""
echo "3. Esegui migrazioni e collectstatic:"
echo "   sudo -u $APP_USER $VENV_DIR/bin/python $APP_DIR/manage.py migrate"
echo "   sudo -u $APP_USER $VENV_DIR/bin/python $APP_DIR/manage.py collectstatic --noinput"
echo ""
echo "4. Crea superuser:"
echo "   sudo -u $APP_USER $VENV_DIR/bin/python $APP_DIR/manage.py createsuperuser"
echo ""
echo "5. Avvia Gunicorn:"
echo "   sudo systemctl start gunicorn"
echo "   sudo systemctl enable gunicorn"
echo ""
echo -e "${GREEN}Accedi al sito: http://$DOMAIN${NC}"
echo -e "${GREEN}Pannello admin: http://$DOMAIN/admin${NC}"
echo ""
echo -e "${RED}IMPORTANTE:${NC}"
echo "- Cambia la password del database in .env!"
echo "- Modifica SECRET_KEY se necessario"
echo "- Configura email in .env se usi form contatti"
echo ""
