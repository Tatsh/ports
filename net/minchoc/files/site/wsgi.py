"""WSGI entry point for the MacPorts minchoc site."""
import os

from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'minchoc_site')
application = get_wsgi_application()
