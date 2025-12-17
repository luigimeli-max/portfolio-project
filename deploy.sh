#!/bin/bash
# Script di deployment per VPS Contabo

echo "====================================="
echo "Deployment Portfolio Django su VPS"
echo "====================================="

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# 1. Aggiorna il codice da Git
echo -e "${YELLOW}1. Pulling ultimo codice da GitHub...${NC}"
git pull origin main

# 2. Attiva virtual environment
echo -e "${YELLOW}2. Attivando virtual environment...${NC}"
if [ -d "venv" ]; then
    source venv/bin/activate
else
    echo -e "${RED}Virtual environment non trovato. Crealo con: python3 -m venv venv${NC}"
    exit 1
fi

# 3. Installa/aggiorna dipendenze
echo -e "${YELLOW}3. Installando dipendenze...${NC}"
pip install -r requirements.txt

# 4. Esegui migrazioni database
echo -e "${YELLOW}4. Eseguendo migrazioni database...${NC}"
python manage.py migrate --noinput

# 5. Raccogli file statici
echo -e "${YELLOW}5. Raccogliendo file statici...${NC}"
python manage.py collectstatic --noinput --clear

# 6. Riavvia Gunicorn
echo -e "${YELLOW}6. Riavviando servizio Gunicorn...${NC}"
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# 7. Verifica stato servizi
echo -e "${YELLOW}7. Verificando stato servizi...${NC}"
if systemctl is-active --quiet gunicorn; then
    echo -e "${GREEN}✓ Gunicorn è attivo${NC}"
else
    echo -e "${RED}✗ Gunicorn non è attivo!${NC}"
    sudo systemctl status gunicorn
fi

if systemctl is-active --quiet nginx; then
    echo -e "${GREEN}✓ Nginx è attivo${NC}"
else
    echo -e "${RED}✗ Nginx non è attivo!${NC}"
    sudo systemctl status nginx
fi

echo -e "${GREEN}====================================="
echo "Deployment completato!"
echo "=====================================${NC}"
