# Quick Reference - Comandi Utili per VPS

## 🔄 Deployment Rapido
```bash
# Esegui deploy automatico
./deploy.sh
```

## 📊 Monitoraggio

### Log in tempo reale
```bash
# Gunicorn logs
sudo journalctl -u gunicorn -f

# Nginx access log
sudo tail -f /var/log/nginx/portfolio_access.log

# Nginx error log
sudo tail -f /var/log/nginx/portfolio_error.log

# Django logs
tail -f logs/django.log
```

### Stato servizi
```bash
# Verifica Gunicorn
sudo systemctl status gunicorn

# Verifica Nginx
sudo systemctl status nginx

# Verifica PostgreSQL
sudo systemctl status postgresql
```

## 🔧 Gestione Servizi

### Riavvio servizi
```bash
# Riavvia Gunicorn
sudo systemctl restart gunicorn

# Riavvia Nginx
sudo systemctl restart nginx

# Riavvia entrambi
sudo systemctl restart gunicorn nginx
```

### Stop/Start
```bash
# Stop
sudo systemctl stop gunicorn

# Start
sudo systemctl start gunicorn
```

## 🗄️ Database

### Backup PostgreSQL
```bash
# Backup completo
sudo -u postgres pg_dump portfolio_db > backup_$(date +%Y%m%d).sql

# Ripristino
sudo -u postgres psql portfolio_db < backup_20231218.sql
```

### Accesso PostgreSQL
```bash
# Come postgres user
sudo -u postgres psql

# Connetti al database
\c portfolio_db

# Lista tabelle
\dt

# Esci
\q
```

## 🔐 SSL/Certificati

### Rinnovo certificato Let's Encrypt
```bash
# Rinnovo manuale
sudo certbot renew

# Test dry-run
sudo certbot renew --dry-run
```

### Verifica scadenza
```bash
sudo certbot certificates
```

## 📦 Gestione Python

### Virtual environment
```bash
# Attiva
source venv/bin/activate

# Disattiva
deactivate
```

### Pacchetti
```bash
# Lista pacchetti installati
pip list

# Aggiorna requirements.txt
pip freeze > requirements.txt
```

## 🧹 Pulizia

### File statici vecchi
```bash
python manage.py collectstatic --clear --noinput
```

### Log files
```bash
# Pulisci log vecchi (più di 30 giorni)
find logs/ -type f -mtime +30 -delete
```

## 🐛 Debug

### Test Gunicorn manuale
```bash
source venv/bin/activate
gunicorn --bind 0.0.0.0:8000 portfolio_project.wsgi:application
```

### Test Nginx configuration
```bash
sudo nginx -t
```

### Verifica porte in ascolto
```bash
# Porta 8000 (Gunicorn)
sudo netstat -tlnp | grep :8000

# Porta 80/443 (Nginx)
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :443
```

### Permessi file
```bash
# Verifica proprietario
ls -la /path/to/portfolio_project

# Correggi permessi
sudo chown -R www-data:www-data /path/to/portfolio_project
sudo chmod -R 755 /path/to/portfolio_project
```

## 🔒 Sicurezza

### Firewall status
```bash
sudo ufw status verbose
```

### Fail2Ban (se installato)
```bash
# Status
sudo fail2ban-client status

# Unban IP
sudo fail2ban-client set nginx-http-auth unbanip 192.168.1.1
```

## 📈 Performance

### Processi Gunicorn
```bash
# Lista processi
ps aux | grep gunicorn

# Numero workers consigliato
python3 -c "import multiprocessing; print(multiprocessing.cpu_count() * 2 + 1)"
```

### Uso risorse
```bash
# CPU e Memoria
htop

# Spazio disco
df -h

# Uso database
sudo -u postgres psql -c "SELECT pg_size_pretty(pg_database_size('portfolio_db'));"
```

## 🔄 Git Operations

### Pull e deploy
```bash
git pull origin main
./deploy.sh
```

### Verifica branch
```bash
git branch
git status
```

### Rollback
```bash
# Vedi commit precedenti
git log --oneline

# Rollback a commit specifico
git reset --hard commit-hash
./deploy.sh
```

## 📱 Django Management

### Crea superuser
```bash
source venv/bin/activate
python manage.py createsuperuser
```

### Migrazioni
```bash
# Crea migrazioni
python manage.py makemigrations

# Applica migrazioni
python manage.py migrate

# Lista migrazioni
python manage.py showmigrations
```

### Shell Django
```bash
python manage.py shell
```

## 💾 Backup Completo

### Script backup rapido
```bash
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/portfolio"

# Crea directory backup
mkdir -p $BACKUP_DIR

# Backup database
sudo -u postgres pg_dump portfolio_db > $BACKUP_DIR/db_$DATE.sql

# Backup media files
tar -czf $BACKUP_DIR/media_$DATE.tar.gz media/

# Backup configurazioni
cp .env $BACKUP_DIR/env_$DATE
```

## 🚨 Troubleshooting Rapido

### 502 Bad Gateway
1. Verifica Gunicorn: `sudo systemctl status gunicorn`
2. Check logs: `sudo journalctl -u gunicorn -n 50`
3. Restart: `sudo systemctl restart gunicorn`

### 403 Forbidden
1. Verifica permessi: `ls -la /path/to/files`
2. Fix owner: `sudo chown -R www-data:www-data /path`

### Static files non caricano
1. Collectstatic: `python manage.py collectstatic --noinput`
2. Verifica Nginx config: `sudo nginx -t`
3. Check percorsi in nginx.conf

### Database connection refused
1. Status PostgreSQL: `sudo systemctl status postgresql`
2. Check .env settings
3. Verifica credenziali: `sudo -u postgres psql -c "\du"`
