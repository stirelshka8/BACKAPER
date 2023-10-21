#!/bin/bash

VERSION="0.1.0"

clear

log_dir="/BACKUPS/logs"
log_file="$log_dir/logs_backups_$(date +'%Y%m%d_%H%M%S').log"

log_message() {
    mkdir -p "$log_dir"
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

handle_interrupt() {
    clear
    echo -e "\e[91m[STOP]Выполнение скрипта прервано пользователем!\e[0m"
    log_message "Выполнение скрипта прервано пользователем!"
    sleep 3
    exit 1
}

trap handle_interrupt SIGINT

log_message "********* START BACKUPS *********"

log_message "v.$VERSION"

# Проверка наличия установленных пакетов
check_packages() {
    echo "-------------------------------------------"
    for package in "$@"; do
        if ! command -v "$package" &> /dev/null; then
            log_message "Не установлен пакет $package"
            echo -e "\e[91m [PAC]Не установлен пакет $package\e[0m"
            echo -e "\e[91m [PAC]Дальнейшая работа скрипта не возможна без его наличия в системе!\e[0m"

            read -p "Желаете установить $package (yes/no)? " install_app

            if [ "$install_app" = "yes" ]; then
                log_message "Установка пакета $package..."
                echo -e "\e[92m [PAC]Установка пакета $package...\e[0m"

                sudo apt update
                sudo apt install $package -y

            else
                log_message "РАБОТА СКРИПТА ОСТАНОВЛЕНА!!!"
                echo -e "\e[91mЗавершение работы скрипта!\e[0m"
                exit 1
            fi

        else
            log_message "$package - Ok"
            echo -e "\e[93m$package - Ok\e[0m"
        fi
    done
    echo "-------------------------------------------"
}

check_packages "rsync" "zip"

read -p "Желаете создать резервные копии директорий (yes/no)? " backup_dirs

backdirs=false

if [ "$backup_dirs" = "yes" ]; then

    backdirs=true

    echo -e "\033[30m\033[103mДиректория BACKUPS с резервными копиями будет создана в корне системы \n\033[0m"

    read -p "Введите абсолютные пути к директориям для резервного копирования (разделите их пробелом): " -a directories

    # Создаем директорию для резервных копий
    backup_dir="/BACKUPS/backup_$(date +'%Y%m%d%H%M%S')"
    mkdir -p "$backup_dir"

    # Создаем резервные копии директорий с использованием rsync
    directories_exist=false
    for directory in "${directories[@]}"; do
        if [ -d "$directory" ]; then
            echo -e "\e[92m [DIR]Создание резервной копии директории $directory...\e[0m"
            log_message "Создание резервной копии директории $directory"
            rsync -a --relative "$directory" "$backup_dir/"
            log_message "Резервная копия директории $directory создана."
            echo -e "\e[93m [DIR]Резервная копия директории $directory создана.\e[0m"
            directories_exist=true
        else
            log_message "Директория '$directory' не существует."
            echo -e "\e[91m [WARNING]Директория '$directory' не существует.\e[0m"
        fi
    done
else
    log_message "Резервные копии диекторий не созданы."
    echo "Резервные копии диекторий не созданы."
fi

read -p "Желаете создать резервные копии Docker контейнеров (yes/no)? " backup_containers

# Если есть активные Docker контейнеры и пользователь согласен, создаем резервные копии каждого контейнера
if [ "$backup_containers" = "yes" ]; then
    docker_containers=$(sudo docker ps -q)
    if [ -n "$docker_containers" ]; then
        # Создаем временную директорию для временных файлов Docker контейнеров
        docker_temp_dir="$backup_dir/docker_temp"
        mkdir -p "$docker_temp_dir"
        for container_id in $docker_containers; do
            container_name=$(sudo docker inspect --format="{{.Name}}" $container_id)
            container_name=${container_name:1}

            echo -e "\e[92m [DOCKER]Создание временной резервной копии Docker контейнера $container_name...\e[0m"
            log_message "Создание временной резервной копии Docker контейнера $container_name"
            sudo docker export -o "$docker_temp_dir/$container_name.tar" $container_id
            echo -e "\e[93m [DOCKER]Временная резервная копия Docker контейнера $container_name создана.\e[0m"
        done

        # Упаковываем временные резервные копии Docker контейнеров в zip архив
        echo -e "\n\n"
        echo -e "\e[92m [DOCKER-ZIP]Упаковка временных резервных копий Docker контейнеров в ZIP архив...\e[0m"
        log_message "Упаковка временных резервных копий Docker контейнеров в ZIP архив"
        sudo zip -rj "$backup_dir/docker_containers.zip" "$docker_temp_dir"
        log_message "Резервные копии Docker контейнеров упакованы в '$backup_dir/docker_containers.zip'."
        echo -e "\e[93m [DOCKER-ZIP]Резервные копии Docker контейнеров упакованы в '$backup_dir/docker_containers.zip'.\e[0m"

        # Удаляем временные файлы Docker контейнеров
        echo -e "\e[92m [DOCKER]Удаление временных файлов Docker контейнеров...\e[0m"
        log_message "Удаление временных файлов Docker контейнеров"
        sudo rm -r "$docker_temp_dir"
        log_message "Временные файлы Docker контейнеров удалены."
        echo -e "\e[93m [DOCKER]Временные файлы Docker контейнеров удалены.\e[0m"
    else
        echo -e "\e[91m [WARNING]Нет активных Docker контейнеров для резервирования.\e[0m"
        log_message "Нет активных Docker контейнеров для резервирования."
    fi
else
    log_message "Резервные копии контейнеров не созданы."
    echo "Резервные копии контейнеров не созданы."
fi

# Проверка на отсутствие каких-либо резервных копий
if [ "$directories_exist" = false ] && [ -z "$docker_containers" ]; then
    log_message "Нет директорий для резервных копий и нет активных Docker контейнеров."
    echo -e "\e[91m [WARNING]Нет директорий для резервных копий и нет активных Docker контейнеров.\e[0m"
    exit 1
fi

# Выводим сообщение о успешном завершении скрипта
if [ "$backdirs" = true ] && [ "$backup_dirs" = "yes" ]; then
    echo -e "\e[92m [INFO]Резервные копии директорий успешно созданы\e[0m"
    log_message "Резервные копии директорий успешно созданы"
fi

# Если Docker контейнеры были упакованы, выводим сообщение об этом
if [ -n "$docker_containers" ] && [ "$backup_containers" = "yes" ]; then
    echo -e "\e[92m [INFO]Docker контейнеры успешно упакованы в '$backup_dir/docker_containers.zip'\e[0m"
    log_message "Docker контейнеры успешно упакованы в '$backup_dir/docker_containers.zip'"
fi

echo "-------------------------------------------"

# Вывод списка директорий, которые были заархивированы
if [ "$backdirs" = true ] && [ "$backup_dirs" = "yes" ]; then
    echo -e "\e[93m [INFO]Директории, которые были заархивированы:"
    log_message "Директории, которые были заархивированы:"
    for directory in "${directories[@]}"; do
        log_message "$directory"
        echo "$directory"
    done
    echo -e "\e[0m"
fi

# Вывод списка Docker контейнеров, которые были заархивированы
if [ -n "$docker_containers" ] && [ "$backup_containers" = "yes" ]; then
    echo -e "\e[93m [INFO]Docker контейнеры, которые были заархивированы:"
    log_message "Docker контейнеры, которые были заархивированы:"
    echo
    for container_id in $docker_containers; do
        container_name=$(sudo docker inspect --format="{{.Name}}" $container_id)
        container_name=${container_name:1}
        log_message "$container_name"
        echo "$container_name"
    done
    echo -e "\e[0m"
fi

log_message "********* FINISH *********"
