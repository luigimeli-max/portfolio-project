# 🚀 Guida Completa al Deploy - Portfolio Django

Deploy su VPS Ubuntu 24 con Nginx, Gunicorn, PostgreSQL e SSL

**Domini:** luigimeli.work, www.luigimeli.work  
**IP VPS:** 38.242.208.240

---

## 📋 Indice

1. [Prerequisiti](#prerequisiti)
2. [Setup Iniziale VPS](#setup-iniziale-vps)
3. [Deploy del Progetto](#deploy-del-progetto)
4. [Configurazione SSL](#configurazione-ssl)
5. [Gestione e Manutenzione](#gestione-e-manutenzione)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisiti

### Sul tuo computer locale:
- Git installato
- Accesso SSH alla VPS
- Repository Git del progetto (GitHub/GitLab)

### Sulla VPS:
- Ubuntu 24.04 LTS
- Accesso root o sudo
- DNS configurati correttamente (A records per luigimeli.work e www.luigimeli.work → 38.242.208.240)

---

## 🔧 Setup Iniziale VPS

### 1. Connessione alla VPS

```bash
# Dal tuo computer locale
ssh root@38.242.208.240
```

### 2. Trasferimento dello script di setup

**Opzione A - Crea manualmente lo script:**

```bash
nano setup_vps.sh
```

Copia il contenuto di `setup_vps.sh` e incollalo, poi salva (CTRL+O, ENTER, CTRL+X).

**Opzione B - Clona il repository (se hai già configurato Git):**

```bash
# Installa git
apt update
apt install -y git

# Clona il repository temporaneamente
cd /tmp
git clone <URL-DEL-TUO-REPOSITORY>
cd portfolio_project
cp setup_vps.sh /root/
cd /root
```

### 3. Modifica le password di sicurezza

```bash
nano setup_vps.sh
```

**IMPORTANTE:** Modifica queste righe:

```bash
DB_PASSWORD="ChangeMeToSecurePassword123!"  # ← CAMBIA QUESTO!
```

Usa una password forte! Esempio:
```bash
DB_PASSWORD="MySecureDBPass2024!@#"
```

### 4. Esegui lo script di setup

```bash
# Rendi lo script eseguibile
chmod +x setup_vps.sh

# Esegui lo script
./setup_vps.sh
```

**Questo script eseguirà automaticamente:**
- ✅ Aggiornamento sistema Ubuntu 24
- ✅ Installazione Python 3.12, PostgreSQL, Nginx, Certbot
- ✅ Configurazione firewall (UFW)
- ✅ Creazione utente `portfolio`
- ✅ Creazione database PostgreSQL `portfolio_db`
- ✅ Creazione directory di progetto `/home/portfolio/portfolio_project`
- ✅ Generazione file `.env` con SECRET_KEY sicura
- ✅ Configurazione Gunicorn systemd service
- ✅ Configurazione Nginx
- ✅ Installazione certificato SSL Let's Encrypt

**Tempo stimato:** 5-10 minuti

---

## 📦 Deploy del Progetto

### 5. Clona il repository

```bash
# Passa all'utente portfolio
sudo -u portfolio -i

# Vai alla home directory
cd /home/portfolio

# Rimuovi la directory vuota creata dallo script
rmdir portfolio_project

# Clona il tuo repository
git clone <URL-DEL-TUO-REPOSITORY> portfolio_project

# Vai nella directory del progetto
cd portfolio_project
```

**Esempio:**
```bash
git clone https://github.com/tuousername/portfolio_project.git portfolio_project
```

### 6. Crea e attiva il virtual environment

```bash
# Crea virtual environment
python3 -m venv venv

# Attiva virtual environment
source venv/bin/activate

# Aggiorna pip
pip install --upgrade pip
```

### 7. Installa le dipendenze

```bash
# Installa tutti i pacchetti Python necessari
pip install -r requirements.txt
```

**Output atteso:**
```
Successfully installed Django-5.x gunicorn-21.x psycopg2-binary-2.x ...
```

### 8. Verifica le configurazioni

```bash
# Controlla il file .env
cat .env
```

Assicurati che contenga:
```
SECRET_KEY=<generata-automaticamente>
DEBUG=False
ALLOWED_HOSTS=luigimeli.work,www.luigimeli.work,38.242.208.240
DB_NAME=portfolio_db
DB_USER=portfolio_user
DB_PASSWORD=<password-che-hai-impostato>
DB_HOST=localhost
DB_PORT=5432
```

### 9. Esegui le migrazioni del database

```bash
# Crea le tabelle nel database
python manage.py migrate
```

**Output atteso:**
```
Operations to perform:
  Apply all migrations: admin, auth, contenttypes, sessions, portfolio
Running migrations:
  Applying contenttypes.0001_initial... OK
  Applying auth.0001_initial... OK
  ...
```

### 10. Raccogli i file statici

```bash
# Raccoglie CSS, JS, immagini in staticfiles/
python manage.py collectstatic --noinput
```

**Output atteso:**
```
120 static files copied to '/home/portfolio/portfolio_project/staticfiles'
```

### 11. Crea il superuser (admin Django)

```bash
python manage.py createsuperuser
```

Inserisci:
- Username: `admin` (o quello che preferisci)
- Email: `admin@luigimeli.work`
- Password: scegli una password forte

### 12. Esci dall'utente portfolio

```bash
exit
```

### 13. Avvia i servizi

```bash
# Avvia Gunicorn
sudo systemctl start gunicorn
sudo systemctl enable gunicorn

# Verifica stato Gunicorn
sudo systemctl status gunicorn
```

**Output atteso:** `Active: active (running)`

```bash
# Riavvia Nginx
sudo systemctl restart nginx

# Verifica stato Nginx
sudo systemctl status nginx
```

### 14. Test del sito

Apri il browser e visita:
- **HTTP:** http://luigimeli.work
- **HTTP con www:** http://www.luigimeli.work
- **IP diretto:** http://38.242.208.240

Dovresti vedere il tuo portfolio! 🎉

---

## 🔒 Configurazione SSL

### 15. Installa certificato SSL Let's Encrypt

```bash
# Installa certificato SSL automaticamente
sudo certbot --nginx -d luigimeli.work -d www.luigimeli.work
```

**Domande che ti farà:**
1. Email per notifiche: inserisci la tua email
2. Accetta Terms of Service: `Y`
3. Newsletter: `N` (opzionale)
4. Redirect HTTP → HTTPS: `2` (Sì, raccomandato)

**Output finale:**
```
Successfully deployed certificate for luigimeli.work and www.luigimeli.work
```

### 16. Verifica rinnovo automatico

```bash
# Test rinnovo certificato (dry-run)
sudo certbot renew --dry-run
```

Il certificato verrà rinnovato automaticamente ogni 90 giorni.

### 17. Test HTTPS

Visita:
- **HTTPS:** https://luigimeli.work ✅
- **HTTPS con www:** https://www.luigimeli.work ✅

Dovresti vedere il lucchetto verde nel browser! 🔒

---

## 🛠️ Gestione e Manutenzione

### Comandi Utili

#### Verifica stato servizi
```bash
# Stato Gunicorn
sudo systemctl status gunicorn

# Stato Nginx
sudo systemctl status nginx

# Stato PostgreSQL
sudo systemctl status postgresql
```

#### Riavvio servizi
```bash
# Riavvio Gunicorn
sudo systemctl restart gunicorn

# Riavvio Nginx
sudo systemctl restart nginx

# Reload Nginx (senza downtime)
sudo systemctl reload nginx
```

#### Visualizza log
```bash
# Log Gunicorn
sudo tail -f /var/log/gunicorn/error.log

# Log Nginx errori
sudo tail -f /var/log/nginx/portfolio_error.log

# Log Nginx accessi
sudo tail -f /var/log/nginx/portfolio_access.log

# Log Django
sudo -u portfolio tail -f /home/portfolio/portfolio_project/logs/django.log
```

### Deploy di Aggiornamenti

Quando modifichi il codice e vuoi aggiornare il sito:

#### Metodo 1: Script automatico (consigliato)

```bash
# Rendi eseguibile lo script deploy
sudo chmod +x /home/portfolio/portfolio_project/deploy.sh

# Esegui il deploy
cd /home/portfolio/portfolio_project
sudo -u portfolio ./deploy.sh
```

#### Metodo 2: Comandi manuali

```bash
# 1. Vai nella directory del progetto
cd /home/portfolio/portfolio_project

# 2. Passa all'utente portfolio
sudo -u portfolio -i
cd ~/portfolio_project

# 3. Pull da Git
git pull origin main

# 4. Attiva venv
source venv/bin/activate

# 5. Aggiorna dipendenze (se necessario)
pip install -r requirements.txt

# 6. Migrazioni database (se ci sono nuovi model)
python manage.py migrate

# 7. Collectstatic (se hai modificato CSS/JS)
python manage.py collectstatic --noinput

# 8. Esci
exit

# 9. Riavvia servizi
sudo systemctl restart gunicorn
sudo systemctl reload nginx
```

### Backup Database

```bash
# Backup database PostgreSQL
sudo -u postgres pg_dump portfolio_db > backup_$(date +%Y%m%d_%H%M%S).sql

# Copia backup sul tuo computer
scp root@38.242.208.240:/root/backup_*.sql ./backups/
```

### Ripristino Database

```bash
# Ripristina da backup
sudo -u postgres psql portfolio_db < backup_YYYYMMDD_HHMMSS.sql
```

---

## 🐛 Troubleshooting

### Problema: Sito non raggiungibile

**Diagnosi:**
```bash
# Verifica DNS
nslookup luigimeli.work

# Verifica Nginx
sudo nginx -t
sudo systemctl status nginx

# Verifica Gunicorn
sudo systemctl status gunicorn
```

**Soluzione:**
```bash
# Riavvia servizi
sudo systemctl restart gunicorn
sudo systemctl restart nginx

# Controlla i log
sudo tail -50 /var/log/nginx/portfolio_error.log
sudo tail -50 /var/log/gunicorn/error.log
```

### Problema: Errore 502 Bad Gateway

**Causa:** Gunicorn non è in esecuzione o non risponde

**Soluzione:**
```bash
# Verifica Gunicorn
sudo systemctl status gunicorn

# Se non è attivo
sudo systemctl start gunicorn

# Controlla errori
sudo journalctl -u gunicorn -n 50
```

### Problema: Static files non caricati (CSS/JS mancanti)

**Soluzione:**
```bash
# Raccogli di nuovo i file statici
sudo -u portfolio bash -c "cd /home/portfolio/portfolio_project && source venv/bin/activate && python manage.py collectstatic --noinput"

# Verifica permessi
sudo chown -R portfolio:portfolio /home/portfolio/portfolio_project/staticfiles

# Riavvia Nginx
sudo systemctl reload nginx
```

### Problema: Errore database connection

**Diagnosi:**
```bash
# Verifica PostgreSQL
sudo systemctl status postgresql

# Testa connessione
sudo -u postgres psql -c "\l"

# Verifica credenziali nel file .env
sudo -u portfolio cat /home/portfolio/portfolio_project/.env
```

**Soluzione:**
```bash
# Riavvia PostgreSQL
sudo systemctl restart postgresql

# Verifica che l'utente esista
sudo -u postgres psql -c "\du"
```

### Problema: Permessi negati

**Soluzione:**
```bash
# Ripristina permessi corretti
sudo chown -R portfolio:portfolio /home/portfolio/portfolio_project
sudo chown -R portfolio:portfolio /var/log/gunicorn
sudo chmod -R 755 /home/portfolio/portfolio_project
```

### Controllo Completo del Sistema

```bash
# Script di verifica completo
echo "=== VERIFICA SERVIZI ==="
sudo systemctl status nginx gunicorn postgresql

echo -e "\n=== VERIFICA PORTE ==="
sudo netstat -tulpn | grep -E ':(80|443|8000|5432)'

echo -e "\n=== VERIFICA PROCESSI ==="
ps aux | grep -E '(gunicorn|nginx)'

echo -e "\n=== ULTIMI ERRORI GUNICORN ==="
sudo tail -20 /var/log/gunicorn/error.log

echo -e "\n=== ULTIMI ERRORI NGINX ==="
sudo tail -20 /var/log/nginx/portfolio_error.log
```

---

## 📞 Contatti e Supporto

### Log Principali
- **Gunicorn:** `/var/log/gunicorn/error.log`
- **Nginx:** `/var/log/nginx/portfolio_error.log`
- **Django:** `/home/portfolio/portfolio_project/logs/django.log`
- **System:** `sudo journalctl -u gunicorn -n 100`

### File di Configurazione
- **Nginx:** `/etc/nginx/sites-available/portfolio`
- **Gunicorn Service:** `/etc/systemd/system/gunicorn.service`
- **Gunicorn Config:** `/home/portfolio/portfolio_project/gunicorn_config.py`
- **Django Settings:** `/home/portfolio/portfolio_project/portfolio_project/settings.py`
- **Environment:** `/home/portfolio/portfolio_project/.env`

---

## ✅ Checklist Finale

- [ ] VPS configurata con `setup_vps.sh`
- [ ] Repository clonato
- [ ] Virtual environment creato
- [ ] Dipendenze installate
- [ ] File `.env` configurato correttamente
- [ ] Migrazioni database eseguite
- [ ] Static files raccolti
- [ ] Superuser creato
- [ ] Gunicorn avviato e abilitato
- [ ] Nginx avviato e funzionante
- [ ] Sito accessibile via HTTP
- [ ] Certificato SSL installato
- [ ] Sito accessibile via HTTPS
- [ ] Redirect HTTP → HTTPS funzionante
- [ ] Admin panel accessibile (/admin)
- [ ] Tutte le pagine funzionanti
- [ ] Script `deploy.sh` testato

---

## 🎉 Deploy Completato!

Il tuo portfolio è ora online su:
- **https://luigimeli.work**
- **https://www.luigimeli.work**

Pannello amministrazione:
- **https://luigimeli.work/admin**

Buon lavoro! 🚀
