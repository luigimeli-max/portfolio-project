# 🏗️ Architettura Multi-Progetto Isolato

Guida per gestire più progetti indipendenti sullo stesso VPS con dipendenze isolate.

## 📋 Struttura Consigliata

```
/var/www/html/
├── portfolio-project/          # Django Portfolio (luigimeli.work)
│   ├── venv/                   # Python venv ISOLATO
│   ├── portfolio.sock          # Socket Gunicorn specifico
│   ├── staticfiles/            # Static isolati
│   └── ...
│
├── angular-app/                # App Angular (luigimeli.work/angular1)
│   ├── node_modules/           # Node modules ISOLATI
│   ├── dist/                   # Build Angular
│   └── ...
│
├── react-project/              # App React (luigimeli.work/react1)
│   ├── node_modules/           # Node modules ISOLATI
│   ├── build/                  # Build React
│   └── ...
│
└── altro-progetto/             # Altro progetto
    └── ...
```

## ✅ Vantaggi Isolamento

1. **Dipendenze Separate**: Ogni progetto ha le sue librerie
2. **Versioni Diverse**: Python 3.9 in un progetto, 3.11 in un altro
3. **Zero Conflitti**: Un progetto non influenza gli altri
4. **Manutenzione Facile**: Aggiorna un progetto senza toccare gli altri
5. **Sicurezza**: Problemi in un progetto non impattano gli altri

## 🚀 Configurazione per Progetto Django (Portfolio)

### Già fatto con auto_deploy.sh:
- ✅ Virtual environment in `portfolio-project/venv/`
- ✅ Servizio systemd: `portfolio.service`
- ✅ Socket: `portfolio.sock`
- ✅ Nginx: gestisce solo dominio root `luigimeli.work`

### File Nginx: `/etc/nginx/sites-available/portfolio`
```nginx
server {
    listen 80;
    server_name luigimeli.work www.luigimeli.work;
    
    location /static/ {
        alias /var/www/html/portfolio-project/staticfiles/;
    }
    
    location / {
        proxy_pass http://unix:/var/www/html/portfolio-project/portfolio.sock;
    }
}
```

## 🅰️ Aggiungere Progetto Angular su /angular1

### 1. Clona/Crea il progetto Angular
```bash
cd /var/www/html
git clone https://github.com/username/angular-app.git
cd angular-app
```

### 2. Installa dipendenze (ISOLATE nella cartella)
```bash
npm install
npm run build
```

### 3. Crea configurazione Nginx separata
```bash
sudo nano /etc/nginx/sites-available/angular-app
```

Contenuto:
```nginx
server {
    listen 80;
    server_name luigimeli.work;
    
    # Gestisce SOLO il percorso /angular1
    location /angular1/ {
        alias /var/www/html/angular-app/dist/;
        try_files $uri $uri/ /angular1/index.html;
        
        # Cache per assets statici
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 4. Abilita configurazione
```bash
sudo ln -s /etc/nginx/sites-available/angular-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. Accesso
- Portfolio: `http://luigimeli.work/`
- Angular: `http://luigimeli.work/angular1/`

## ⚛️ Aggiungere Progetto React su /react1

### 1. Setup progetto
```bash
cd /var/www/html
git clone https://github.com/username/react-project.git
cd react-project
npm install
npm run build
```

### 2. Configurazione Nginx
```bash
sudo nano /etc/nginx/sites-available/react-app
```

```nginx
server {
    listen 80;
    server_name luigimeli.work;
    
    location /react1/ {
        alias /var/www/html/react-project/build/;
        try_files $uri $uri/ /react1/index.html;
        
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
}
```

### 3. Abilita
```bash
sudo ln -s /etc/nginx/sites-available/react-app /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

## 🐍 Aggiungere Altro Progetto Django su Porta Diversa

Se hai un altro progetto Django, usa una porta o socket diverso:

### 1. Clona e setup
```bash
cd /var/www/html
git clone https://github.com/username/altro-django.git
cd altro-django
python3 -m venv venv  # NUOVO venv isolato
source venv/bin/activate
pip install -r requirements.txt
```

### 2. Servizio Gunicorn con nome diverso
```bash
sudo nano /etc/systemd/system/altro-django.service
```

```ini
[Unit]
Description=Altro Django Project
After=network.target

[Service]
WorkingDirectory=/var/www/html/altro-django
Environment="PATH=/var/www/html/altro-django/venv/bin"
ExecStart=/var/www/html/altro-django/venv/bin/gunicorn \
    --bind unix:/var/www/html/altro-django/altro.sock \
    config.wsgi:application

[Install]
WantedBy=multi-user.target
```

### 3. Nginx per sottopercorso
```nginx
server {
    listen 80;
    server_name luigimeli.work;
    
    location /altro-app/ {
        proxy_pass http://unix:/var/www/html/altro-django/altro.sock;
        proxy_set_header Host $host;
    }
}
```

## 📦 Gestione Servizi Multipli

### Lista tutti i servizi Django attivi
```bash
systemctl list-units --type=service | grep -E '(portfolio|altro-django|myapp)'
```

### Riavvia un servizio specifico
```bash
sudo systemctl restart portfolio        # Solo portfolio
sudo systemctl restart altro-django     # Solo altro progetto
```

### Verifica log di un progetto specifico
```bash
sudo journalctl -u portfolio -f         # Log portfolio
sudo journalctl -u altro-django -f      # Log altro progetto
```

## 🔄 Aggiornamenti Indipendenti

### Aggiorna solo Portfolio
```bash
cd /var/www/html/portfolio-project
git pull
source venv/bin/activate
pip install -r requirements.txt
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart portfolio
```

### Aggiorna solo Angular
```bash
cd /var/www/html/angular-app
git pull
npm install
npm run build
# Nessun restart necessario - sono file statici!
```

## 🔒 Permessi per Ogni Progetto

```bash
# Portfolio Django
sudo chown -R www-data:www-data /var/www/html/portfolio-project

# Angular App
sudo chown -R www-data:www-data /var/www/html/angular-app

# Imposta permessi corretti
sudo chmod -R 755 /var/www/html/portfolio-project
sudo chmod -R 755 /var/www/html/angular-app
```

## 🌐 Configurazione Nginx Completa (Esempio)

File: `/etc/nginx/sites-available/luigimeli-work`

```nginx
server {
    listen 80;
    server_name luigimeli.work www.luigimeli.work;

    # ROOT - Portfolio Django
    location / {
        proxy_pass http://unix:/var/www/html/portfolio-project/portfolio.sock;
        include proxy_params;
    }
    
    location /static/ {
        alias /var/www/html/portfolio-project/staticfiles/;
    }
    
    location /media/ {
        alias /var/www/html/portfolio-project/media/;
    }

    # Angular App su /angular1
    location /angular1/ {
        alias /var/www/html/angular-app/dist/;
        try_files $uri $uri/ /angular1/index.html;
    }

    # React App su /react1
    location /react1/ {
        alias /var/www/html/react-project/build/;
        try_files $uri $uri/ /react1/index.html;
    }

    # Altro Django App su /api
    location /api/ {
        proxy_pass http://unix:/var/www/html/api-project/api.sock;
        include proxy_params;
    }
}
```

## 📊 Monitoring Risorse per Progetto

### Uso memoria per servizio
```bash
systemctl status portfolio | grep Memory
systemctl status altro-django | grep Memory
```

### Processi attivi
```bash
ps aux | grep gunicorn
ps aux | grep node
```

## ⚡ Performance e Cache

Ogni progetto può avere la sua strategia di cache:

```nginx
# Cache aggressiva per Angular/React (file statici)
location /angular1/ {
    expires 1y;
    add_header Cache-Control "public, immutable";
}

# Cache moderata per Django static
location /static/ {
    expires 30d;
    add_header Cache-Control "public";
}

# Nessuna cache per contenuti dinamici Django
location / {
    add_header Cache-Control "no-cache";
}
```

## 🎯 Best Practices

1. **Un servizio systemd per progetto** - Nome univoco per ciascuno
2. **Socket/Porte separate** - Evita conflitti
3. **Virtual env per ogni Python** - Isolamento totale
4. **node_modules per ogni JS** - Non condividere dipendenze
5. **Nginx config separate** - Un file per progetto o tutto in uno
6. **Backup separati** - Backup indipendenti per progetto
7. **Git repository separati** - Un repo per progetto
8. **Log separati** - Più facile debug
9. **SSL per dominio principale** - Copre tutti i sottopercorsi
10. **Monitoring indipendente** - Traccia performance per progetto

## 🆘 Troubleshooting

### Progetto X non funziona ma Y sì
1. Controlla log specifico: `sudo journalctl -u nome-servizio -n 50`
2. Verifica permessi: `ls -la /percorso/progetto`
3. Testa Nginx: `sudo nginx -t`
4. Verifica socket: `ls -la /percorso/progetto/*.sock`

### Conflitti porta/socket
- Ogni progetto deve avere socket/porta unica
- Verifica: `sudo netstat -tlnp | grep gunicorn`

### Dipendenze errate
- Attiva venv corretto: `source /percorso/progetto/venv/bin/activate`
- Verifica: `which python` e `which pip`

## 🎉 Risultato Finale

```
http://luigimeli.work/           → Portfolio Django
http://luigimeli.work/angular1/  → App Angular
http://luigimeli.work/react1/    → App React
http://luigimeli.work/api/       → API Django
```

Ogni progetto:
- ✅ Completamente isolato
- ✅ Dipendenze separate
- ✅ Aggiornabile indipendentemente
- ✅ Zero conflitti
- ✅ Facile manutenzione
