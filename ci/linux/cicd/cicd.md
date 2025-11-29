# 1. Скачайте все файлы
chmod +x install.sh
sudo ./install.sh

# 2. Настройте секреты
sudo nano /etc/spongo/secrets.env
# export SPONGO_HOST="your.bpi.ip"
# export SPONGO_USER="root" 
# export SPONGO_PRIVATE_KEY="-----BEGIN..."

sudo chown git:git /etc/spongo/secrets.env

# 3. Создайте репозиторий
sudo -u git mkdir /opt/spongo/repos/myrepo.git
cd /opt/spongo/repos/myrepo.git
sudo -u git git init --bare
sudo -u git ln -s /opt/spongo/spongo-hook hooks/post-receive
sudo chmod +x /opt/spongo/repos/myrepo.git/hooks/post-receive

# 4. Запустите демон
sudo systemctl start spongo-daemon
sudo systemctl status spongo-daemon
