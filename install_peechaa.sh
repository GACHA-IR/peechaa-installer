#!/bin/bash

set -e

echo "شروع نصب ربات telegram peechaa..."

# --- پارامترها ---
INSTALL_DIR="/opt/peechaa"
REPO_URL="https://github.com/arash10abbasi/peechaa"
DB_NAME="peechaadatabase"
DB_USER="peechaauser"
DB_PASS="peechaapassword"
LINUX_USER="root"

# --- نصب پیش‌نیازها ---
echo "نصب پیش‌نیازها..."
apt update && apt upgrade -y
apt install -y git python3 python3-venv python3-pip postgresql postgresql-contrib

# --- کلون سورس کد ---
echo "کلون پروژه..."
git clone "$REPO_URL" "$INSTALL_DIR"
cd "$INSTALL_DIR"
mv sample_config.ini config.ini

# --- ساخت محیط مجازی ---
echo "ساخت venv..."
python3 -m venv venv
source venv/bin/activate
pip install --upgrade pip
pip install -U -r requirements.txt

# --- ساخت دیتابیس و یوزر ---
echo "ساخت دیتابیس PostgreSQL..."
sudo -u postgres psql <<EOF
CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';
CREATE DATABASE $DB_NAME OWNER $DB_USER;
EOF

DB_URL="postgresql://${DB_USER}:${DB_PASS}@localhost:5432/${DB_NAME}"

# --- تنظیم فایل config.ini ---
echo "تنظیم config.ini..."
cat > config.ini <<EOF
[peechaaconfig]

log = True
APP_ID = 2123019
API_HASH = d5d83de034f8777ec5231230cc7ff5850
TOKEN = 7971554100:AAPznWS7KG4IpzN16fJYwD_2f2Sw6iBoxQM
OWNER_ID = 5457332304
OWNER_USERNAME = Arash10Abbasi

SQLALCHEMY_DATABASE_URI = ${DB_URL}
MESSAGE_DUMP = -1001834667516
GBAN_LOGS = -1001834667516
SYS_ADMIN = 5457332304
LOAD =
NO_LOAD = sed
WEBHOOK = False
SPB_MODE = True
URL = None
INFOPIC = True
CERT_PATH = None
PORT = 5000
DEL_CMDS = True
STRICT_GBAN = True
BAN_STICKER =
ALLOW_EXCL = True
CUSTOM_CMD = False

CASH_API_KEY = https://www.alphavantage.co/support/#api-key
TIME_API_KEY = https://timezonedb.com/api
WALL_API = https://wall.alphacoders.com/api.php
spamwatch_api = https://t.me/SpamWatchBot
SPAMMERS =
LASTFM_API_KEY = https://www.last.fm/api/account/create
BOT_API_URL = https://api.telegram.org/bot
BOT_API_FILE_URL = https://api.telegram.org/file/bot
EOF

# --- ساخت سرویس systemd ---
echo "ساخت سرویس systemd..."
cat > /etc/systemd/system/peechaa.service <<EOF
[Unit]
Description=Telegram Bot - peechaa
After=network.target

[Service]
User=$LINUX_USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/venv/bin/python3 -m tg_bot
Restart=always
RestartSec=10
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
EOF

# --- فعال‌سازی سرویس ---
echo "فعال‌سازی سرویس..."
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable peechaa
systemctl start peechaa

echo "نصب کامل شد. برای بررسی لاگ از دستور زیر استفاده کن:"
echo "journalctl -u peechaa -f"