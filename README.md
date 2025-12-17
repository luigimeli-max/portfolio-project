# 🚀 Portfolio Django

Un portfolio professionale per web developer costruito con Django, caratterizzato da un design moderno dark theme con accenti teal, animazioni fluide e un'esperienza utente ottimizzata.

![Python](https://img.shields.io/badge/Python-3.10+-blue.svg)
![Django](https://img.shields.io/badge/Django-5.0+-green.svg)
![License](https://img.shields.io/badge/License-MIT-yellow.svg)

## ✨ Caratteristiche

- **Design Moderno**: Dark theme (#0a0a0a) con accenti teal (#00d9ff)
- **10 Sezioni Uniche**: Hero, Intro, Timeline, Progetti, Testimonial, Skills, Stats, Process, CTA, Footer
- **Micro-interazioni**: Animazioni scroll con AOS, counter animati, effetti hover
- **Responsive**: Mobile-first design ottimizzato per tutti i dispositivi
- **SEO Friendly**: Sitemap XML, meta tags, structured data
- **Admin Personalizzato**: Gestione contenuti intuitiva con anteprime immagini
- **Performance**: Lazy loading, ottimizzazione immagini, caching statico

## 🛠️ Tecnologie

- **Backend**: Django 5.0+, Python 3.10+
- **Database**: PostgreSQL (SQLite per sviluppo)
- **Frontend**: HTML5, CSS3, Vanilla JavaScript
- **Librerie JS**: AOS.js, Swiper.js
- **Static Files**: WhiteNoise
- **Immagini**: Pillow

## 📦 Installazione

### Prerequisiti

- Python 3.10+
- pip
- virtualenv (consigliato)
- PostgreSQL (per produzione)

### Setup Locale

1. **Clona il repository**
```bash
git clone https://github.com/tuousername/portfolio-django.git
cd portfolio-django
```

2. **Crea e attiva l'ambiente virtuale**
```bash
# Windows
python -m venv venv
venv\Scripts\activate

# Linux/macOS
python3 -m venv venv
source venv/bin/activate
```

3. **Installa le dipendenze**
```bash
pip install -r requirements.txt
```

4. **Crea il file .env**
```bash
cp .env.example .env
# Modifica .env con le tue configurazioni
```

5. **Esegui le migrazioni**
```bash
python manage.py makemigrations
python manage.py migrate
```

6. **Crea un superuser**
```bash
python manage.py createsuperuser
```

7. **Raccogli i file statici**
```bash
python manage.py collectstatic
```

8. **Avvia il server**
```bash
python manage.py runserver
```

9. **Visita** `http://127.0.0.1:8000`

## 📁 Struttura del Progetto

```
portfolio_project/
├── manage.py
├── requirements.txt
├── .env.example
├── portfolio_project/          # Configurazione Django
│   ├── settings.py
│   ├── urls.py
│   ├── wsgi.py
│   └── asgi.py
├── portfolio/                  # App principale
│   ├── models.py              # Modelli dati
│   ├── views.py               # Viste
│   ├── urls.py                # URL routing
│   ├── admin.py               # Configurazione admin
│   ├── forms.py               # Form contatto
│   ├── context_processors.py  # Context processor
│   └── sitemaps.py            # Sitemap SEO
├── templates/                  # Template HTML
│   ├── base.html
│   ├── 404.html
│   ├── 500.html
│   └── portfolio/
│       ├── index.html
│       ├── project_detail.html
│       └── projects_list.html
└── static/                     # File statici
    ├── css/
    │   └── styles.css
    ├── js/
    │   └── main.js
    └── images/
```

## 🔧 Configurazione

### Variabili d'Ambiente (.env)

```env
# Django
SECRET_KEY=your-secret-key-here
DEBUG=True
ALLOWED_HOSTS=localhost,127.0.0.1

# Database (per produzione)
DB_NAME=portfolio_db
DB_USER=postgres
DB_PASSWORD=your-password
DB_HOST=localhost
DB_PORT=5432

# Email
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=your-email@gmail.com
EMAIL_HOST_PASSWORD=your-app-password
DEFAULT_FROM_EMAIL=your-email@gmail.com
```

### Configurazione Admin

1. Accedi a `/admin` con le credenziali superuser
2. **SiteSettings**: Configura nome sito, bio, social links
3. **Projects**: Aggiungi i tuoi progetti con immagini e tecnologie
4. **Skills**: Definisci le tue competenze con livelli
5. **Timeline**: Aggiungi eventi della tua carriera
6. **Testimonials**: Inserisci le recensioni dei clienti

## 🎨 Personalizzazione

### Colori (CSS Variables)

Modifica `static/css/styles.css`:

```css
:root {
    --color-bg-primary: #0a0a0a;      /* Background principale */
    --color-bg-secondary: #111111;     /* Background secondario */
    --color-accent: #00d9ff;           /* Colore accento */
    --color-accent-secondary: #00ffcc; /* Accento secondario */
    --color-text-primary: #ffffff;     /* Testo principale */
    --color-text-secondary: #a0a0a0;   /* Testo secondario */
}
```

### Font

I font utilizzati sono:
- **Inter**: Per il testo corpo
- **Playfair Display**: Per i titoli

Modifica in `base.html` per cambiare i font Google.

## 📱 Responsive Breakpoints

- **Mobile**: < 576px
- **Tablet**: 576px - 992px
- **Desktop**: > 992px

## 🚀 Deploy

### Deploy su Railway/Render/Heroku

1. Configura le variabili d'ambiente
2. Imposta `DEBUG=False`
3. Configura `ALLOWED_HOSTS`
4. Usa PostgreSQL come database
5. Configura WhiteNoise per i file statici

### Checklist Produzione

- [ ] `DEBUG = False`
- [ ] Secret key unica e sicura
- [ ] HTTPS configurato
- [ ] Database PostgreSQL
- [ ] File statici con CDN/WhiteNoise
- [ ] Backup database configurato
- [ ] Monitoring errori (Sentry)

## 📧 Contatto Form

Il form di contatto salva i messaggi nel database e può inviare email. 
Configura le impostazioni SMTP nel file `.env` per abilitare le notifiche email.

## 🔐 Sicurezza

In produzione sono abilitate automaticamente:
- CSRF Protection
- XSS Protection
- Content Type Nosniff
- HSTS (con HTTPS)
- Secure Cookies

## 📄 Licenza

Questo progetto è rilasciato sotto licenza MIT. Vedi il file [LICENSE](LICENSE) per i dettagli.

## 🤝 Contributi

I contributi sono benvenuti! Per favore:

1. Fai un fork del repository
2. Crea un branch per la tua feature (`git checkout -b feature/AmazingFeature`)
3. Committa le modifiche (`git commit -m 'Add some AmazingFeature'`)
4. Pusha il branch (`git push origin feature/AmazingFeature`)
5. Apri una Pull Request

## 📞 Supporto

Per domande o problemi, apri una issue su GitHub.

---

⭐ Se questo progetto ti è stato utile, lascia una stella!

Made with ❤️ and Django
