#!/bin/bash
. /etc/os-release
log() {
    local LEVEL=$1
    shift
    echo "[$LEVEL] $*"
}

add_keys() {
 log "EXEC" "Создаем папку для ключей и выдаем права"
 install -m 0755 -d /etc/apt/keyrings
 log "EXEC" "Скачиваем ключи и добавляем в папку"
 curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
 chmod a+r /etc/apt/keyrings/docker.asc
}
add_repository() {
    log "EXEC" "Добавляем репозиторий"
    tee /etc/apt/sources.list.d/docker.sources <<EOF
       Types: deb
        URIs: https://download.docker.com/linux/debian
        Suites: $(. /etc/os-release && echo "$VERSION_CODENAME")
        Components: stable
        Signed-By: /etc/apt/keyrings/docker.asc
EOF
}
install_dependencies() {
 

 log "EXEC" "Обновление пакетов"
 apt update
 log "EXEC" "Установка зависимостей"
 apt install ca-certificates curl
 add_keys
 add_repository
 apt update
 log "EXEC" "Установка Docker"
 apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
 log "EXEC" "Скачивание образа"

}
install_dependencies