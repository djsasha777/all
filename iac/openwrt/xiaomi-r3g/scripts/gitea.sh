#!/bin/sh
set -eu

# Проверка, что мы на OpenWrt/ImmortalWrt
if ! [ -x /usr/bin/opkg ]; then
	echo "This script is for OpenWrt/ImmortalWrt only." >&2
	exit 1
fi

# --- Параметры ---
GITEA_USER="gitea"
GITEA_GROUP="users"
GITEA_UID="1000"
GITEA_GID="100"
GITEA_HOME="/home/gitea"
GITEA_PORT="3000"
GITEA_VERSION="1.22.6"
GITEA_ARCH="linux-arm64"
GITEA_BIN_URL="https://dl.gitea.io/gitea/${GITEA_VERSION}/gitea-${GITEA_VERSION}-${GITEA_ARCH}"

GITEA_DIR="${GITEA_HOME}/bin"
GITEA_BIN="${GITEA_DIR}/gitea"
GITEA_CONFIG_DIR="${GITEA_HOME}/custom/conf"
GITEA_CONFIG="${GITEA_CONFIG_DIR}/app.ini"
GITEA_DATA_DIR="${GITEA_HOME}/data"

PG_DB="gitea"
PG_USER="postgres"
PG_GITEA_USER="gitea"
PG_GITEA_PASS="gitea_secure_password_12345"  # поменяй на свой


# --- Установка пакетов (если чего‑то нет) ---

install_if_missing() {
	pkg="$1"
	if ! opkg list-installed | grep -q "^${pkg}\>"; then
		echo "Installing $pkg..."
		opkg install "$pkg"
	else
		echo "$pkg already installed."
	fi
}

opkg update

install_if_missing "wget"
install_if_missing "coreutils-setcap"
install_if_missing "postgresql-server"
install_if_missing "postgresql-contrib"


# --- Создаём пользователя вручную (без adduser) ---

# 1. Группа
if ! grep -q "^$GITEA_GROUP:" /etc/group; then
	echo "Creating group $GITEA_GROUP..."
	echo "$GITEA_GROUP:x:$GITEA_GID:" >> /etc/group
fi

# 2. Пользователь
if ! grep -q "^$GITEA_USER:" /etc/passwd; then
	echo "Creating user $GITEA_USER..."
	echo "$GITEA_USER:x:$GITEA_UID:$GITEA_GID:$GITEA_USER:/home/$GITEA_USER:/bin/false" >> /etc/passwd
fi

# 3. Shadow (если не существует)
if ! grep -q "^$GITEA_USER:" /etc/shadow; then
	echo "$GITEA_USER:!!:18000:0:99999:7:::" >> /etc/shadow
fi

# 4. Домашняя директория
if [ ! -d "$GITEA_HOME" ]; then
	mkdir -p "$GITEA_HOME"
	chown -R "$GITEA_UID:$GITEA_GID" "$GITEA_HOME"
fi


# --- Скачиваем Gitea, если нет или версия не совпадает ---

if [ ! -x "$GITEA_BIN" ] || ! "$GITEA_BIN" --version | grep -q "Gitea version ${GITEA_VERSION}"; then
	echo "Downloading Gitea ${GITEA_VERSION} (${GITEA_ARCH})..."

	mkdir -p "$GITEA_DIR"
	mkdir -p "$GITEA_CONFIG_DIR"
	mkdir -p "$GITEA_DATA_DIR"

	# Скачиваем бинарник
	wget -O "$GITEA_BIN" "$GITEA_BIN_URL"
	chmod +x "$GITEA_BIN"

	# Проверка архитектуры
	file "$GITEA_BIN" 2>/dev/null | grep -q "aarch64" || {
		echo "Error: binary is not for aarch64." >&2
		rm -f "$GITEA_BIN"
		exit 1
	}
fi


# --- Создаём конфиг app.ini, если его нет ---

if [ ! -f "$GITEA_CONFIG" ]; then
	echo "Creating app.ini..."
	cat > "$GITEA_CONFIG" << EOF
[server]
APP_NAME = My Gitea
RUN_MODE = prod
RUN_USER = $GITEA_USER
DOMAIN = 192.168.1.1
HTTP_PORT = $GITEA_PORT
ROOT_URL = http://192.168.1.1:$GITEA_PORT/
ENABLE_GZIP = true

[database]
DB_TYPE = postgres
HOST = 127.0.0.1:5432
NAME = $PG_DB
USER = $PG_GITEA_USER
PASSWD = $PG_GITEA_PASS
SSL_MODE = disable

[git]
MAX_GIT_DIFF_LINES = 1000
MAX_GIT_DIFF_LINE_CHARACTERS = 500
MAX_GIT_DIFF_FILES = 100

[service]
REGISTER_EMAIL_CONFIRM = false
ENABLE_NOTIFY_MAIL = false

[session]
PROVIDER = file

[log]
MODE = file
LEVEL = Info
EOF
	chown -R "$GITEA_USER:$GITEA_GROUP" "$GITEA_CONFIG_DIR"
fi


# --- Запуск Postgresql (если не запущен) ---

if [ -x /etc/init.d/postgresql ]; then
	if ! pgrep -f "postgres" >/dev/null; then
		echo "Starting Postgresql..."
		/etc/init.d/postgresql enable
		/etc/init.d/postgresql start
	fi
fi


# --- Создаём базу и юзера в Postgres, если нет ---

if ! su "$PG_USER" -c "psql -lqt | cut -d '|' -f 1 | grep -q '^$PG_DB\$'"; then
	su "$PG_USER" -c "psql -c \"CREATE USER $PG_GITEA_USER WITH PASSWORD '$PG_GITEA_PASS';\""
	su "$PG_USER" -c "psql -c \"CREATE DATABASE $PG_DB WITH OWNER $PG_GITEA_USER;\""
fi


# --- Создание /etc/init.d/gitea (procd service) ---

GITEA_INIT="/etc/init.d/gitea"

cat > "$GITEA_INIT" << 'EOF'
#!/bin/sh /etc/rc.common

USE_PROCD=1

START=90
STOP=90

GITEA_USER="gitea"
GITEA_HOME="/home/gitea"
GITEA_BIN="/home/gitea/bin/gitea"
GITEA_CONFIG="/home/gitea/custom/conf/app.ini"

start_service() {
	procd_open_instance
	procd_set_param command "$GITEA_BIN" web --config "$GITEA_CONFIG"
	procd_set_param user "$GITEA_USER"
	procd_set_param env GITEA_WORK_DIR="$GITEA_HOME"
	procd_set_param respawn
	procd_set_param stderr 1
	procd_set_param stdout 1
	procd_close_instance
}

stop_service() {
	:  # procd сам останавливает по PID
}

reload_service() {
	procd_signal_service HUP
}

service_triggers() {
	procd_add_reload_trigger "gitea"
}
EOF

chmod +x "$GITEA_INIT"
/etc/init.d/gitea enable


# --- Финальные сообщения ---

echo "----------------------------------------------------------------------"
echo "Gitea installed and configured!"
echo " - Service: /etc/init.d/gitea"
echo " - Web UI: http://192.168.1.1:$GITEA_PORT/install"
echo " - In LuCI: go to System → Startup / Services → gitea to start/stop."
echo "----------------------------------------------------------------------"