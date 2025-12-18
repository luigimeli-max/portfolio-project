# Portfolio Project - Deployment Guide

## 🚀 Quick Deployment on VPS

### Prerequisites
- VPS with Ubuntu 20.04/22.04 or Debian
- Domain `luigimeli.work` pointing to `38.242.208.240`
- SSH access to the server

### Installation Steps

**1. Connect to VPS**
```bash
ssh root@38.242.208.240
```

**2. Install dependencies**
```bash
apt update
apt install python3 python3-pip python3-venv nginx git -y
```

**3. Navigate to web directory**
```bash
cd /var/www/luigimeli.work/html
```

**4. Clone repository**
```bash
git clone https://github.com/luigimeli-max/portfolio-project.git
cd portfolio-project
```

**5. Run setup script**
```bash
chmod +x setup_vps.sh
sudo ./setup_vps.sh
```

**6. Setup SSL (optional but recommended)**
```bash
apt install certbot python3-certbot-nginx -y
certbot --nginx -d luigimeli.work -d www.luigimeli.work
```

### Access Your Site
- **Main site**: http://luigimeli.work
- **With www**: http://www.luigimeli.work
- **By IP**: http://38.242.208.240
- **Admin panel**: http://luigimeli.work/admin

### Update Deployment

When you push changes to GitHub:

```bash
cd /var/www/luigimeli.work/html/portfolio-project
chmod +x deploy.sh
./deploy.sh
```

### Useful Commands

**View logs:**
```bash
sudo journalctl -u portfolio -f
sudo tail -f /var/log/nginx/portfolio_error.log
```

**Restart services:**
```bash
sudo systemctl restart portfolio
sudo systemctl restart nginx
```

**Check status:**
```bash
sudo systemctl status portfolio
sudo systemctl status nginx
```

### File Structure on VPS

```
/var/www/luigimeli.work/html/
└── portfolio-project/
    ├── venv/                    # Python virtual environment
    ├── portfolio_project/       # Django project
    ├── portfolio/               # Django app
    ├── static/                  # Static files
    ├── staticfiles/             # Collected static files
    ├── media/                   # Uploaded media
    ├── templates/               # HTML templates
    ├── manage.py
    ├── requirements.txt
    ├── gunicorn_config.py       # Gunicorn configuration
    ├── setup_vps.sh             # Initial setup script
    └── deploy.sh                # Update deployment script
```

### Services Configuration

**Gunicorn service:** `/etc/systemd/system/portfolio.service`
**Nginx config:** `/etc/nginx/sites-available/portfolio`

### Troubleshooting

**502 Bad Gateway**
- Check if Gunicorn is running: `sudo systemctl status portfolio`
- View logs: `sudo journalctl -u portfolio -n 50`
- Restart: `sudo systemctl restart portfolio`

**Static files not loading**
- Collect static files: `python manage.py collectstatic --noinput`
- Check permissions: `ls -la staticfiles/`

**Permission denied**
- Fix ownership: `sudo chown -R www-data:www-data /var/www/luigimeli.work/html/portfolio-project`

### Security Checklist

- ✅ DEBUG=False in production
- ✅ Strong SECRET_KEY
- ✅ ALLOWED_HOSTS configured
- ✅ SSL/HTTPS enabled
- ✅ Firewall configured
- ✅ Regular backups

### Backup Database

```bash
python manage.py dumpdata > backup.json
```

Restore:
```bash
python manage.py loaddata backup.json
```
