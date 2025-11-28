#!/bin/sh

REPO_URL="https://github.com/djsasha777/hardware.git"
LOCAL_FILE="/etc/nginx/nginx.conf"
SHA="https://api.github.com/repos/djsasha777/hardware/commits?path=OPENWRT%2Fnginx%2Fnginx.conf&page=1&per_page=1"

CURRENT_SHA=""

while true; do

    NEW_SHA=$(curl -sL $SHA | jq '.[0].sha')
    
    if [[ ! -z "$NEW_SHA" && "$NEW_SHA" != "$CURRENT_SHA" ]]; then
        echo "Обнаружены изменения в файле!"
        
        mkdir autoconf && cd autoconf
        git clone $REPO_URL
        cd hardware/OPENWRT/nginx
        cp nginx.conf $LOCAL_FILE.tmp
        cd ../../../.. && rm -rf autoconf
        
        if [[ -f "$LOCAL_FILE.tmp" ]]; then
            mv "$LOCAL_FILE.tmp" "$LOCAL_FILE"
            chmod 644 "$LOCAL_FILE"
            
            CURRENT_SHA="$NEW_SHA"
            echo "Файл успешно обновлён."
            service nginx restart
            echo "nginx сервер был перезапущен."
        else
            echo "Ошибка загрузки файла или перезапуска"
        fi
    fi
    
    sleep 180
done