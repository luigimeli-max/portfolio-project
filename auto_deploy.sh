#!/bin/bash
# Auto Deploy Script for Portfolio Django Project
# Esegui questo script dopo aver clonato la repository sul VPS

set -e  # Exit on error

echo "======================================"
echo "🚀 AUTO DEPLOYMENT PORTFOLIO DJANGO"
echo "======================================"
echo ""

# Colori
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Funzioni di utilità
print_step() {
    echo -e "${BLUE}[STEP $1]${NC} $2"
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Verifica di essere nella directory corretta
if [ ! -f "manage.py" ]; then
    print_error "File manage.py non trovato!"
    print_error "Assicurati di eseguire questo script dalla directory root del progetto"
    exit 1
fi

# Ottieni il percorso corrente
PROJECT_DIR=$(pwd)
print_success "Directory progetto: $PROJECT_DIR"
echo ""

# Richiedi informazioni all'utente
echo "======================================"
echo "CONFIGURAZIONE"
echo "======================================"
read -p "Il tuo dominio principale (es. luigimeli.work): " DOMAIN
read -p "Vuoi aggiungere anche www.$DOMAIN? (s/n): " ADD_WWW
read -p "Email amministratore: " ADMIN_EMAIL
read -p "Nome univoco per il servizio (es. portfolio): " SERVICE_NAME
echo ""
print_warning "IMPORTANTE: Questo deploy gestirà SOLO il dominio principale $DOMAIN"
print_warning "I sottopercorsi come $DOMAIN/angular1 NON saranno toccati"
echo ""

# Genera SECRET_KEY automaticamente
print_step "1/12" "Generazione SECRET_KEY..."
SECRET_KEY=$(python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())" 2>/dev/null || echo "django-insecure-$(openssl rand -base64 32)")
print_success "SECRET_KEY generata"

# Crea ambiente virtuale
print_step "2/12" "Creazione ambiente virtuale..."
python3 -m venv venv
print_success "Ambiente virtuale creato"

# Attiva ambiente virtuale e installa dipendenze
print_step "3/12" "Installazione dipendenze Python..."
source venv/bin/activate
pip install --upgrade pip -q
pip install -r requirements.txt -q
print_success "Dipendenze installate"

# Crea file .env
print_step "4/12" "Creazione file .env..."
if [ "$ADD_WWW" = "s" ] || [ "$ADD_WWW" = "S" ]; then
    ALLOWED_HOSTS="$DOMAIN,www.$DOMAIN"
else
    ALLOWED_HOSTS="$DOMAIN"
fi

cat > .env << EOF
# Django Settings
SECRET_KEY=$SECRET_KEY
DEBUG=False
ALLOWED_HOSTS=$ALLOWED_HOSTS

# Database (SQLite per default)
DB_NAME=
DB_USER=
DB_PASSWORD=
DB_HOST=localhost
DB_PORT=5432

# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=$ADMIN_EMAIL
EMAIL_HOST_PASSWORD=
DEFAULT_FROM_EMAIL=noreply@$DOMAIN
EOF
print_success "File .env creato"

# Crea directory logs
print_step "5/12" "Creazione directory logs..."
mkdir -p logs
print_success "Directory logs creata"

# Esegui migrazioni
print_step "6/12" "Esecuzione migrazioni database..."
python manage.py migrate --noinput
print_success "Migrazioni completate"

# Raccogli file statici
print_step "7/12" "Raccolta file statici..."
python manage.py collectstatic --noinput --clear
print_success "File statici raccolti"

# Crea superuser (opzionale)
echo ""
read -p "Vuoi creare un superuser adesso? (s/n): " CREATE_SUPERUSER
if [ "$CREATE_SUPERUSER" = "s" ] || [ "$CREATE_SUPERUSER" = "S" ]; then
    python manage.py createsuperuser
fi

# Configura Gunicorn service
print_step "8/12" "Configurazione servizio Gunicorn..."
sudo tee /etc/systemd/system/${SERVICE_NAME}.service > /dev/null << EOF
[Unit]
Description=${SERVICE_NAME} Django Application - $DOMAIN
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=$PROJECT_DIR
Environment="PATH=$PROJECT_DIR/venv/bin"
ExecStart=$PROJECT_DIR/venv/bin/gunicorn --workers 3 --bind unix:$PROJECT_DIR/${SERVICE_NAME}.sock portfolio_project.wsgi:application

[Install]
WantedBy=multi-user.target
EOF
print_success "Servizio Gunicorn configurato come ${SERVICE_NAME}.service"

# Configura Nginx
print_step "9/12" "Configurazione Nginx..."
if [ "$ADD_WWW" = "s" ] || [ "$ADD_WWW" = "S" ]; then
    SERVER_NAME="$DOMAIN www.$DOMAIN"
else
    SERVER_NAME="$DOMAIN"
fi

sudo tee /etc/nginx/sites-available/${SERVICE_NAME} > /dev/null << EOF
# Configurazione Nginx per $SERVICE_NAME
# Gestisce SOLO il dominio principale: $DOMAIN
# I sottopercorsi (es. /angular1, /app2) devono essere configurati separatamente

server {
    listen 80;
    server_name $SERVER_NAME;

    # Limita dimensione upload
    client_max_body_size 10M;

    # Favicon
    location = /favicon.ico { 
        access_log off; 
        log_not_found off; 
    }
    
    # File statici di questo progetto Django - ISOLATI in questa cartella
    location /static/ {
        alias $PROJECT_DIR/staticfiles/;
        expires 30d;
        add_header Cache-Control "public, immutable";
    }
    
    # File media di questo progetto Django - ISOLATI in questa cartella
    location /media/ {
        alias $PROJECT_DIR/media/;
        expires 30d;
        add_header Cache-Control "public";
    }

    # IMPORTANTE: location / gestisce solo il dominio root
    # Altri progetti in sottopercorsi NON sono gestiti da questa configurazione
    location / {
        include proxy_params;
        proxy_pass http://unix:$PROJECT_DIR/${SERVICE_NAME}.sock;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        
        # Timeout
        proxy_connect${SERVICE_NAME}
sudo systemctl enable ${SERVICE_NAME}
sudo nginx -t && sudo systemctl restart nginx
print_success "Servizi avviati (${SERVICE_NAME})"

# Verifica stato servizi
print_step "12/12" "Verifica servizi..."
sleep 2
if systemctl is-active --quiet ${SERVICE_NAME}; then
    print_success "Gunicorn (${SERVICE_NAME}) è attivo"
else
    print_error "Gunicorn (${SERVICE_NAME}) non è attivo!"
    print_warning "Controlla i log con: sudo journalctl -u ${SERVICE_NAME}
sudo chown -R www-data:www-data $PROJECT_DIR
sudo chmod -R 755 $PROJECT_DIR
print_success "Permessi impostati"

# Avvia servizi
print_step "11/12" "Avvio servizi..."
sudo systemctl daemon-reload
sudo systemctl start portfolio
sudo systemctl enable portfolio
sudo nginx -t && sudo systemctl restart nginx
print_success "Servizi avviati"

# Verifica stato servizi
print_step "12/12" "Verifica servizi..."
sleep 2
if systemctl is-active --quiet portfolio; then
    print_success "Gunicorn è attivo"
else� ARCHITETTURA ISOLATA:"
echo "   ✓ Progetto: $PROJECT_DIR"
echo "   ✓ Virtual env: $PROJECT_DIR/venv (ISOLATO)"
echo "   ✓ Servizio: ${SERVICE_NAME}.service"
echo "   ✓ Socket: $PROJECT_DIR/${SERVICE_NAME}.sock"
echo "   ✓ Nginx config: /etc/nginx/sites-available/${SERVICE_NAME}"
echo ""
echo -e "${YELLOW}⚠ IMPORTANTE PER ECOSISTEMA MULTI-PROGETTO:${NC}"
echo "   • Questo progetto gestisce SOLO: $DOMAIN (root)"
echo "   • Altri progetti (es. /angular1) NON sono toccati"
echo "   • Ogni progetto avrà la sua configurazione Nginx separata"
echo "   • Tutte le dipendenze Python sono in: $PROJECT_DIR/venv"
echo ""
echo "📝 PROSSIMI PASSI:"
echo ""
echo "1. Configura SSL/HTTPS con Let's Encrypt:"
echo "   sudo apt install certbot python3-certbot-nginx -y"
echo "   sudo certbot --nginx -d $DOMAIN"
if [ "$ADD_WWW" = "s" ] || [ "$ADD_WWW" = "S" ]; then
    echo "   (aggiungi -d www.$DOMAIN se necessario)"
fi
echo ""
echo "2. Accedi all'admin Django:"
echo "   http://$DOMAIN/admin"
echo ""
echo "3. Per vedere i log di QUESTO progetto:"
echo "   sudo journalctl -u ${SERVICE_NAME} -f"
echo "   sudo tail -f /var/log/nginx/error.log"
echo ""
echo "4. Per aggiornare QUESTO progetto in futuro:"
echo "   cd $PROJECT_DIR"
echo "   git pull origin main"
echo "   source venv/bin/activate"
echo "   pip install -r requirements.txt"
echo "   python manage.py migrate"
echo "   python manage.py collectstatic --noinput"
echo "   sudo systemctl restart ${SERVICE_NAME}"
echo ""
echo "5. Per aggiungere altri progetti (es. Angular):"
echo "   • Crea una nuova cartella separata"
echo "   • Configura un nuovo file Nginx per i sottopercorsi"
echo "   • Esempio: /etc/nginx/sites-available/angular-app"
echo "   • Non interferiranno con questo progetto!-certbot-nginx -y"
echo "   sudo certbot --nginx -d $DOMAIN"
if [ "$ADD_WWW" = "s" ] || [ "$ADD_WWW" = "S" ]; then
    echo "   (aggiungi -d www.$DOMAIN se necessario)"
fi
echo ""
echo "2. Accedi all'admin Django:"
echo "   http://$DOMAIN/admin"
echo ""
echo "3. Per vedere i log:"
echo "   sudo journalctl -u portfolio -f"
echo "   sudo tail -f /var/log/nginx/error.log"
echo ""
echo "4. Per aggiornare il sito in futuro:"
echo "   cd $PROJECT_DIR"
echo "   git pull origin main"
echo "   source venv/bin/activate"
echo "   pip install -r requirements.txt"
echo "   python manage.py migrate"
echo "   python manage.py collectstatic --noinput"
echo "   sudo systemctl restart portfolio"
echo ""
echo "======================================"
echo -e "${GREEN}Buon lavoro! 🚀${NC}"
echo "======================================"
