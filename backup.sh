#!/bin/bash

log_dir="/BACKUPS/logs"
log_file="$log_dir/logs_backups_$(date +'%Y%m%d_%H%M%S').log"

log_message() {
    mkdir -p "$log_dir"

    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

log_message "********* START BACKUPS *********"  

# Проверка наличия установленных пакетов rsync и zip
check_packages() {
    echo "-------------------------------------------"
    for package in "$@"; do
        echo "Проверка установлен ли пакет - $package"
        if ! command -v "$package" &> /dev/null; then
            log_message "Предупреждение: Не установлен пакет $package"
            echo -e "\e[91mПредупреждение: Не установлен пакет $package\e[0m"
            echo -e "\e[91mДальнейшая работа скрипта не возможна без его наличия в системе!\e[0m"

            read -p "Желаете установить $package (yes/no)? " install_app

            if [ "$install_app" = "yes" ]; then
                log_message "Установка пакета $package..."
                echo -e "\e[92mУстановка пакета $package...\e[0m"
                
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
            echo -e "\e[92mСоздание резервной копии директории $directory...\e[0m"
            rsync -av --relative "$directory" "$backup_dir/"
            log_message "Резервная копия директории $directory создана."
            echo -e "\e[93mРезервная копия директории $directory создана.\e[0m"
            directories_exist=true
        else
            log_message "Предупреждение: Директория '$directory' не существует."
            echo -e "\e[91mПредупреждение: Директория '$directory' не существует.\e[0m"
        fi
    done
else
    log_message "Резервные копии диекторий не созданы."
    echo -e "\e[91Резервные копии диекторий не созданы.\e[0m"
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

            echo -e "\e[92mСоздание временной резервной копии Docker контейнера $container_name...\e[0m"
            sudo docker export -o "$docker_temp_dir/$container_name.tar" $container_id
            echo -e "\e[93mВременная резервная копия Docker контейнера $container_name создана.\e[0m"
        done

        # Упаковываем временные резервные копии Docker контейнеров в zip архив
        echo -e "\e[92mУпаковка временных резервных копий Docker контейнеров в zip архив...\e[0m"
        sudo zip -rj "$backup_dir/docker_containers.zip" "$docker_temp_dir"
        log_message "Резервные копии Docker контейнеров упакованы в '$backup_dir/docker_containers.zip'."
        echo -e "\e[93mРезервные копии Docker контейнеров упакованы в '$backup_dir/docker_containers.zip'.\e[0m"

        # Удаляем временные файлы Docker контейнеров
        echo -e "\e[92mУдаление временных файлов Docker контейнеров...\e[0m"
        sudo rm -r "$docker_temp_dir"
        log_message "Временные файлы Docker контейнеров удалены."
        echo -e "\e[93mВременные файлы Docker контейнеров удалены.\e[0m"
    else
        echo -e "\e[91mНет активных Docker контейнеров для резервирования.\e[0m"
    fi
else
log_message "Резервные копии контейнеров не созданы."
echo -e "\e[91Резервные копии контейнеров не созданы.\e[0m"

fi

# Проверка на отсутствие каких-либо резервных копий
if [ "$directories_exist" = false ] && [ -z "$docker_containers" ]; then
    log_message "Предупреждение: Нет директорий для резервных копий и нет активных Docker контейнеров."   
    echo -e "\e[91mПредупреждение: Нет директорий для резервных копий и нет активных Docker контейнеров.\e[0m"
    exit 1
fi

# Выводим сообщение о успешном завершении скрипта
if [ "$backdirs" = true ] && [ "$backup_dirs" = "yes" ]; then
    echo -e "\e[92mРезервные копии директорий успешно созданы\e[0m"
fi

# Если Docker контейнеры были упакованы, выводим сообщение об этом
if [ -n "$docker_containers" ] && [ "$backup_containers" = "yes" ]; then
    echo -e "\e[92mDocker контейнеры успешно упакованы в '$backup_dir/docker_containers.zip'\e[0m"
fi

echo "*******************************************************"

# Вывод списка директорий, которые были заархивированы
if [ "$backdirs" = true ] && [ "$backup_dirs" = "yes" ]; then
    echo -e "\e[93mДиректории, которые были заархивированы:"
    log_message "Директории, которые были заархивированы:"  
    for directory in "${directories[@]}"; do
        log_message "$directory"  
        echo "$directory"
    done
    echo -e "\e[0m"
fi

# Вывод списка Docker контейнеров, которые были заархивированы
if [ -n "$docker_containers" ] && [ "$backup_containers" = "yes" ]; then
    echo -e "\e[93mDocker контейнеры, которые были заархивированы:"
    log_message "Docker контейнеры, которые были заархивированы:"  
    for container_id in $docker_containers; do
        container_name=$(sudo docker inspect --format="{{.Name}}" $container_id)
        container_name=${container_name:1}
        log_message "$container_name"  
        echo "$container_name"
    done
    echo -e "\e[0m"
fi

log_message "Резервные копии созданы в директории - $backup_dir"
log_message "********* FINISH *********"  
