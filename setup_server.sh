#!/bin/bash
# Script di setup iniziale per il primo deployment sul VPS

echo "=========================================="
echo "Setup Iniziale Portfolio Django su VPS"
echo "=========================================="

# Colori per output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Verifica se siamo nella directory corretta
if [ ! -f "manage.py" ]; then
    echo -e "${RED}Errore: esegui questo script dalla directory root del progetto${NC}"
    exit 1
fi

# 1. Crea virtual environment se non existe
if [ ! -d "venv" ]; then
    echo -e "${YELLOW}1. Creando virtual environment...${NC}"
    python3 -m venv venv
else
    echo -e "${GREEN}✓ Virtual environment già esistente${NC}"
fi

# 2. Attiva venv
echo -e "${YELLOW}2. Attivando virtual environment...${NC}"
source venv/bin/activate

# 3. Aggiorna pip
echo -e "${YELLOW}3. Aggiornando pip...${NC}"
pip install --upgrade pip

# 4. Installa dipendenze
echo -e "${YELLOW}4. Installando dipendenze da requirements.txt...${NC}"
pip install -r requirements.txt

# 5. Verifica file .env
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}5. Creando file .env da .env.example...${NC}"
    cp .env.example .env
    echo -e "${RED}⚠ IMPORTANTE: Modifica il file .env con le tue configurazioni!${NC}"
    echo -e "${RED}   Usa: nano .env${NC}"
else
    echo -e "${GREEN}✓ File .env già esistente${NC}"
fi

# 6. Crea directory logs se non esiste
echo -e "${YELLOW}6. Creando directory logs...${NC}"
mkdir -p logs

# 7. Esegui migrazioni
echo -e "${YELLOW}7. Eseguendo migrazioni database...${NC}"
python manage.py migrate

# 8. Raccogli file statici
echo -e "${YELLOW}8. Raccogliendo file statici...${NC}"
python manage.py collectstatic --noinput

# 9. Mostra istruzioni finali
echo -e "${GREEN}=========================================="
echo "Setup iniziale completato!"
echo "==========================================${NC}"
echo ""
echo -e "${YELLOW}Prossimi passi:${NC}"
echo "1. Modifica il file .env con le tue configurazioni"
echo "   nano .env"
echo ""
echo "2. Genera una SECRET_KEY sicura:"
echo "   python -c \"from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())\""
echo ""
echo "3. Crea un superutente per l'admin:"
echo "   python manage.py createsuperuser"
echo ""
echo "4. Configura Gunicorn come servizio:"
echo "   sudo cp gunicorn.service /etc/systemd/system/"
echo "   # Modifica i percorsi nel file prima!"
echo "   sudo systemctl daemon-reload"
echo "   sudo systemctl enable gunicorn"
echo "   sudo systemctl start gunicorn"
echo ""
echo "5. Configura Nginx:"
echo "   sudo cp nginx.conf /etc/nginx/sites-available/portfolio"
echo "   # Modifica dominio e percorsi nel file prima!"
echo "   sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/"
echo "   sudo nginx -t"
echo "   sudo systemctl restart nginx"
echo ""
echo "6. Per maggiori dettagli, leggi DEPLOYMENT.md"
