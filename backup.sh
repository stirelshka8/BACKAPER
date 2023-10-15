#!/bin/bash

# Проверка наличия установленных пакетов rsync и zip
if ! command -v rsync &> /dev/null; then
    echo -e "\e[91mПредупреждение: Не установлен пакет rsync\e[0m"
    echo -e "\e[91mУстановите его перед выполнением скрипта*\e[0m"
    exit 1
fi

if ! command -v zip &> /dev/null; then
    echo -e "\e[91mПредупреждение: Не установлен пакет zip\e[0m"
    echo -e "\e[91m *Установите его перед выполнением скрипта*\e[0m"
    exit 1
fi

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
        echo -e "\e[93mРезервная копия директории $directory создана.\e[0m"
        directories_exist=true
    else
        echo -e "\e[91mПредупреждение: Директория '$directory' не существует\e[0m"
    fi
done

# Проверка наличия активных Docker контейнеров
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
        echo -e "\e[93mРезервные копии Docker контейнеров упакованы в '$backup_dir/docker_containers.zip'.\e[0m"

        # Удаляем временные файлы Docker контейнеров
        echo -e "\e[92mУдаление временных файлов Docker контейнеров...\e[0m"
        sudo rm -r "$docker_temp_dir"
        echo -e "\e[93mВременные файлы Docker контейнеров удалены.\e[0m"
    else
        echo -e "\e[91mНет активных Docker контейнеров для резервирования.\e[0m"
    fi
fi

# Проверка на отсутствие каких-либо резервных копий
if [ "$directories_exist" = false ] && [ -z "$docker_containers" ]; then
    echo -e "\e[91mПредупреждение: Нет директорий для резервных копий и нет активных Docker контейнеров\e[0m"
    exit 1
fi

# Выводим сообщение о успешном завершении скрипта
echo -e "\e[92mРезервные копии успешно созданы\e[0m"

# Если Docker контейнеры были упакованы, выводим сообщение об этом
if [ -n "$docker_containers" ] && [ "$backup_containers" = "yes" ]; then
    echo -e "\e[92mDocker контейнеры успешно упакованы в '$backup_dir/docker_containers.zip'\e[0m"
fi
