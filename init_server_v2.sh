#!/bin/bash
. /etc/os-release
SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

docker_gpg_link= "https://download.docker.com/linux/debian/gpg"
warp_proxy_gpg_link="https://pkg.cloudflareclient.com/pubkey.gpg"
keyrings_warp_folder_path="/usr/share/keyrings/"
keyrings_warp_key_path="${keyrings_warp_folder_path}/cloudflare-warp-archive-keyring.gpg"
keyrings_docker_folder_path="/etc/apt/keyrings"
keyrings_docker_key_path="${keyrings_folder_path}/docker.asc"


log() {
    local LEVEL=$1
    shift
    echo "[$LEVEL] $*"
}
create_keyrings() {
 log "EXEC" "Создаем папку для ключей и выдаем права"
 install -m 0755 -d "$keyrings_folder_path"
 log "EXEC" "Скачиваем ключи и добавляем в папку"
 curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
 curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
 chmod a+r /etc/apt/keyrings/docker.asc
}

add_repository() {
    log "EXEC" "Добавляем репозиторий"
    echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$(. /etc/os-release && echo "$ID") \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
  echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/cloudflare-client.list
}
update_and_install_package() {
    log "EXEC" "Обновляем пакеты"
    apt update
    apt install ca-certificates curl gpg vim resolvconf dnscrypt-proxy -y
    create_keyrings
    add_repository
    apt update
    apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin cloudflare-warp  -y
}
init_proxy() {
    log "EXEC" "Инициализация прокси warp"
    Y | warp-cli registration new
    warp-cli mode proxy
    warp-cli proxy port 40000
    warp-cli connect
}

init_docker() {
    log "EXEC" "Инициализация сборки docker контейнеров"
    docker compose up -d
    log "INFO" "Сборка закончена"
}
init_dnscrypt_proxy() {
  dnscrypt_proxy_config= "${SRC}/configs/dnscrypt-proxy.toml"
  mv "$dnscrypt_proxy_config" /etc/dnscrypt-proxy/dnscrypt-proxy.toml
  systemctl restart dnscrypt-proxy
  systemctl status dnscrypt-proxy
  echo "nameserver 127.0.2.1" | tee /etc/resolvconf/resolv.conf.d/head
  echo "nameserver 127.0.2.1" | sudo tee /etc/resolv.conf
  resolvconf -u
}

main() {
    create_keyrings
    add_repository
    update_and_install_package
    init_proxy
    init_docker
}
main
