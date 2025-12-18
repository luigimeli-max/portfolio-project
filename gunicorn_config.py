"""
Gunicorn configuration file for Django portfolio project.
"""

import multiprocessing

# Server socket
bind = "127.0.0.1:8000"
backlog = 2048

# Worker processes
workers = multiprocessing.cpu_count() * 2 + 1
worker_class = "sync"
worker_connections = 1000
timeout = 120
keepalive = 5

# Restart workers after this many requests, to help prevent memory leaks
max_requests = 1000
max_requests_jitter = 50

# Logging
accesslog = "/var/log/gunicorn/access.log"
errorlog = "/var/log/gunicorn/error.log"
loglevel = "info"

# Process naming
proc_name = "portfolio_gunicorn"

# Server mechanics
daemon = False
pidfile = "/var/run/gunicorn/gunicorn.pid"
user = None
group = None
tmp_upload_dir = None

# SSL (if needed, but usually handled by Nginx)
# keyfile = "/path/to/key.pem"
# certfile = "/path/to/cert.pem"
