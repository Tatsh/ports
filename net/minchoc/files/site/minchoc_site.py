"""Minimal Django project serving minchoc, installed by MacPorts.

Local settings (SECRET_KEY, ALLOWED_HOSTS, ALLOW_PACKAGE_DELETION and so on) belong in
@PREFIX@/etc/minchoc/local_settings.py, which is read last.
"""
from pathlib import Path
import runpy

BASE_DIR = Path('@PREFIX@/var/db/minchoc')
DEBUG = False
ALLOWED_HOSTS = ['localhost', '127.0.0.1']
SECRET_KEY = 'change me in @PREFIX@/etc/minchoc/local_settings.py'
INSTALLED_APPS = [
    'django.contrib.admin', 'django.contrib.auth', 'django.contrib.contenttypes',
    'django.contrib.sessions', 'django.contrib.messages', 'django.contrib.staticfiles', 'minchoc'
]
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware', 'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware'
]
ROOT_URLCONF = 'minchoc_urls'
TEMPLATES = [{
    'BACKEND': 'django.template.backends.django.DjangoTemplates',
    'APP_DIRS': True,
    'OPTIONS': {
        'context_processors': [
            'django.template.context_processors.request',
            'django.contrib.auth.context_processors.auth',
            'django.contrib.messages.context_processors.messages'
        ]
    }
}]
DATABASES = {'default': {'ENGINE': 'django.db.backends.sqlite3', 'NAME': BASE_DIR / 'db.sqlite3'}}
MEDIA_ROOT = BASE_DIR / 'media'
STATIC_URL = 'static/'
DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

_local = Path('@PREFIX@/etc/minchoc/local_settings.py')
if _local.exists():
    globals().update({
        k: v
        for k, v in runpy.run_path(str(_local)).items() if k.isupper()
    })
