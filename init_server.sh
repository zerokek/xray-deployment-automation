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
    echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
}
deployment() {
    log "EXEC" "Собираем образ"
    docker build -t xray-zeroke:1.0.0beta .
    log "EXEC" "Создаем контейнер и пробрасываем порты"
    docker run  -p 2083:443 -d xray-zeroke:1.0.0beta
    log "INFO" "Сборка закончена"
}
install_dependencies() {
 

    log "EXEC" "Обновление пакетов"
    apt update
    log "EXEC" "Установка зависимостей"
    apt install ca-certificates curl  -y
    add_keys
    add_repository
    apt update
    log "EXEC" "Установка Docker"
    apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
    deployment
}
install_dependencies
