#!/bin/bash
set -e

echo "🚀 Установка Spongo CI/CD..."

# Создание пользователя
useradd -r -s /bin/false -d /opt/spongo -m git || true
usermod -aG git git

# Директории
mkdir -p /opt/spongo/{repos,work_trees} /var/log/spongo /etc/spongo
chown -R git:git /opt/spongo /var/log/spongo
chmod 755 /opt/spongo

# Установка зависимостей
apt update
apt install -y git yq curl openssh-client

# Копирование файлов
cp cicd.conf /etc/spongo/
cp spongo-daemon.service /etc/systemd/system/
cp hooks/post-receive /opt/spongo/spongo-hook
chmod +x /opt/spongo/spongo-hook
chown git:git /opt/spongo/spongo-hook

# Systemd
systemctl daemon-reload
systemctl enable spongo-daemon

echo "✅ Установка завершена!"
echo "Создайте секреты: nano /etc/spongo/secrets.env"
echo "Запустите: systemctl start spongo-daemon"
