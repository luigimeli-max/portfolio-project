#!/bin/bash
#############################################################################
# Script di deploy per Portfolio Django
# Esegui questo script dopo ogni modifica al codice per aggiornare il sito
#############################################################################

set -e  # Exit on error

# Colori per output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Variabili
APP_DIR="/home/portfolio/portfolio_project"
VENV_DIR="$APP_DIR/venv"

echo -e "${GREEN}==================================================="
echo "DEPLOY PORTFOLIO - $(date)"
echo "===================================================${NC}"

# 1. Vai alla directory del progetto
cd $APP_DIR

# 2. Pull delle modifiche da Git
echo -e "${GREEN}[1/7] Pull da Git...${NC}"
git pull origin main || {
    echo -e "${YELLOW}Errore nel pull da git. Continuo comunque...${NC}"
}

# 3. Attiva virtual environment
echo -e "${GREEN}[2/7] Attivazione virtual environment...${NC}"
source $VENV_DIR/bin/activate

# 4. Aggiorna le dipendenze
echo -e "${GREEN}[3/7] Aggiornamento dipendenze...${NC}"
pip install --upgrade pip
pip install -r requirements.txt

# 5. Esegui migrazioni database
echo -e "${GREEN}[4/7] Esecuzione migrazioni database...${NC}"
python manage.py makemigrations
python manage.py migrate --noinput

# 6. Raccogli file statici
echo -e "${GREEN}[5/7] Raccolta file statici...${NC}"
python manage.py collectstatic --noinput

# 7. Riavvia Gunicorn
echo -e "${GREEN}[6/7] Riavvio Gunicorn...${NC}"
sudo systemctl restart gunicorn

# Verifica stato
sleep 2
if sudo systemctl is-active --quiet gunicorn; then
    echo -e "${GREEN}✓ Gunicorn riavviato correttamente${NC}"
else
    echo -e "${RED}✗ Errore: Gunicorn non è attivo!${NC}"
    sudo systemctl status gunicorn
    exit 1
fi

# 8. Riavvia Nginx (opzionale, solo se hai modificato configurazioni)
echo -e "${GREEN}[7/7] Riavvio Nginx...${NC}"
sudo systemctl reload nginx

echo ""
echo -e "${GREEN}==================================================="
echo "DEPLOY COMPLETATO CON SUCCESSO!"
echo "===================================================${NC}"
echo ""
echo -e "${GREEN}Sito aggiornato: https://luigimeli.work${NC}"
echo ""

# Mostra ultimi log
echo -e "${YELLOW}Ultimi log di Gunicorn:${NC}"
sudo tail -n 20 /var/log/gunicorn/error.log
