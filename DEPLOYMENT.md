# Guida al Deployment su VPS Contabo

Questa guida ti aiuterà a deployare il portfolio Django sul tuo server VPS Contabo.

## 📋 Prerequisiti sul VPS

1. **Sistema Operativo**: Ubuntu 20.04/22.04 o Debian
2. **Accesso**: SSH con privilegi sudo
3. **Dominio**: Puntato all'IP del VPS

## 🚀 Installazione sul Server

### 1. Connettiti al VPS via SSH

```bash
ssh root@tuo-ip-vps
# oppure
ssh utente@tuodominio.com
```

### 2. Aggiorna il sistema

```bash
sudo apt update && sudo apt upgrade -y
```

### 3. Installa le dipendenze necessarie

```bash
# Python e pip
sudo apt install python3 python3-pip python3-venv python3-dev -y

# PostgreSQL
sudo apt install postgresql postgresql-contrib libpq-dev -y

# Nginx
sudo apt install nginx -y

# Git
sudo apt install git -y

# Altre utilità
sudo apt install build-essential libssl-dev libffi-dev -y
```

### 4. Configura PostgreSQL

```bash
# Accedi a PostgreSQL
sudo -u postgres psql

# Crea database e utente (sostituisci con password sicura)
CREATE DATABASE portfolio_db;
CREATE USER portfolio_user WITH PASSWORD 'tua_password_sicura';
ALTER ROLE portfolio_user SET client_encoding TO 'utf8';
ALTER ROLE portfolio_user SET default_transaction_isolation TO 'read committed';
ALTER ROLE portfolio_user SET timezone TO 'Europe/Rome';
GRANT ALL PRIVILEGES ON DATABASE portfolio_db TO portfolio_user;
\q
```

### 5. Clona il progetto dalla repository

```bash
# Vai nella cartella HTML (sostituisci con il tuo percorso)
cd /var/www/html
# oppure
cd /home/utente/html

# Clona la repository
sudo git clone https://github.com/luigimeli-max/portfolio-project.git
cd portfolio-project

# Imposta i permessi corretti
sudo chown -R www-data:www-data /var/www/html/portfolio-project
# oppure se usi un utente specifico
sudo chown -R tuoutente:www-data /percorso/portfolio-project
```

### 6. Crea e configura il Virtual Environment

```bash
# Crea virtual environment
python3 -m venv venv

# Attiva virtual environment
source venv/bin/activate

# Aggiorna pip
pip install --upgrade pip

# Installa dipendenze
pip install -r requirements.txt
```

### 7. Configura le variabili d'ambiente

```bash
# Copia il file .env.example
cp .env.example .env

# Genera una SECRET_KEY sicura
python3 -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# Modifica il file .env
nano .env
```

Configura il file `.env`:

```env
SECRET_KEY=la-tua-secret-key-generata
DEBUG=False
ALLOWED_HOSTS=tuodominio.com,www.tuodominio.com,tuo-ip-vps

DB_ENGINE=django.db.backends.postgresql
DB_NAME=portfolio_db
DB_USER=portfolio_user
DB_PASSWORD=tua_password_sicura
DB_HOST=localhost
DB_PORT=5432
```

### 8. Aggiorna settings.py per la produzione

Modifica `portfolio_project/settings.py` per caricare le variabili dal file .env:

```python
import os
from dotenv import load_dotenv

load_dotenv()

SECRET_KEY = os.environ.get('SECRET_KEY')
DEBUG = os.environ.get('DEBUG', 'False') == 'True'
ALLOWED_HOSTS = os.environ.get('ALLOWED_HOSTS', '').split(',')

DATABASES = {
    'default': {
        'ENGINE': os.environ.get('DB_ENGINE', 'django.db.backends.postgresql'),
        'NAME': os.environ.get('DB_NAME', 'portfolio_db'),
        'USER': os.environ.get('DB_USER', 'portfolio_user'),
        'PASSWORD': os.environ.get('DB_PASSWORD', ''),
        'HOST': os.environ.get('DB_HOST', 'localhost'),
        'PORT': os.environ.get('DB_PORT', '5432'),
    }
}
```

### 9. Esegui le migrazioni e raccogli i file statici

```bash
# Esegui migrazioni
python manage.py migrate

# Crea superutente per l'admin
python manage.py createsuperuser

# Raccogli file statici
python manage.py collectstatic --noinput
```

### 10. Configura Gunicorn come servizio systemd

```bash
# Modifica il file gunicorn.service con i percorsi corretti
sudo nano gunicorn.service

# Copia il file nella directory systemd
sudo cp gunicorn.service /etc/systemd/system/

# Ricarica systemd
sudo systemctl daemon-reload

# Abilita e avvia Gunicorn
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

# Verifica lo stato
sudo systemctl status gunicorn
```

### 11. Configura Nginx

```bash
# Modifica nginx.conf con il tuo dominio e percorsi
nano nginx.conf

# Copia la configurazione in Nginx
sudo cp nginx.conf /etc/nginx/sites-available/portfolio

# Crea symlink in sites-enabled
sudo ln -s /etc/nginx/sites-available/portfolio /etc/nginx/sites-enabled/

# Rimuovi configurazione default (opzionale)
sudo rm /etc/nginx/sites-enabled/default

# Testa la configurazione
sudo nginx -t

# Riavvia Nginx
sudo systemctl restart nginx
```

### 12. Configura SSL con Let's Encrypt (opzionale ma consigliato)

```bash
# Installa Certbot
sudo apt install certbot python3-certbot-nginx -y

# Ottieni certificato SSL
sudo certbot --nginx -d tuodominio.com -d www.tuodominio.com

# Il certificato si rinnoverà automaticamente
# Puoi testare il rinnovo con:
sudo certbot renew --dry-run
```

### 13. Configura il Firewall

```bash
# Permetti SSH, HTTP e HTTPS
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable

# Verifica lo stato
sudo ufw status
```

## 🔄 Aggiornamenti futuri

Per aggiornare il sito dopo modifiche al codice:

```bash
cd /percorso/portfolio-project
chmod +x deploy.sh
./deploy.sh
```

Oppure manualmente:

```bash
# 1. Pull del codice
git pull origin main

# 2. Attiva venv
source venv/bin/activate

# 3. Aggiorna dipendenze
pip install -r requirements.txt

# 4. Migrazioni
python manage.py migrate

# 5. Raccogli statici
python manage.py collectstatic --noinput

# 6. Riavvia servizi
sudo systemctl restart gunicorn
sudo systemctl restart nginx
```

## 📝 Comandi utili

```bash
# Visualizza log Gunicorn
sudo journalctl -u gunicorn -f

# Visualizza log Nginx
sudo tail -f /var/log/nginx/portfolio_error.log
sudo tail -f /var/log/nginx/portfolio_access.log

# Riavvia servizi
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# Verifica stato servizi
sudo systemctl status gunicorn
sudo systemctl status nginx
```

## 🐛 Troubleshooting

### Gunicorn non si avvia
```bash
# Controlla i log
sudo journalctl -u gunicorn -n 50

# Verifica i permessi
ls -la /percorso/portfolio-project

# Testa Gunicorn manualmente
source venv/bin/activate
gunicorn --bind 0.0.0.0:8000 portfolio_project.wsgi:application
```

### Nginx restituisce 502 Bad Gateway
- Verifica che Gunicorn sia in esecuzione
- Controlla i log di Nginx
- Verifica che il socket/porta in nginx.conf corrisponda a gunicorn_config.py

### File statici non caricano
- Verifica che `collectstatic` sia stato eseguito
- Controlla i permessi della cartella staticfiles
- Verifica i percorsi in nginx.conf

## 🔒 Sicurezza

1. **Cambia sempre la SECRET_KEY in produzione**
2. **Imposta DEBUG=False**
3. **Usa password forti per database**
4. **Mantieni sistema e dipendenze aggiornate**
5. **Configura backup regolari del database**
6. **Monitora i log regolarmente**

## 📧 Supporto

Per problemi o domande, controlla i log o consulta la documentazione Django.
