#!/bin/bash

# Находим крайнюю созданную директорию с резервными копиями
backup_dir=$(find /BACKUPS -type d -name "backup_*" | sort -r | head -n 1)

# Проверка наличия директории с резервными копиями
if [ -z "$backup_dir" ]; then
    echo -e "\e[91mПредупреждение: Директория с резервными копиями не найдена\e[0m"
    exit 1
fi

# Восстановление директорий
restore_directories() {
    for backup in "$backup_dir"/*; do
        if [ -d "$backup" ]; then
            # Извлекаем относительный путь из архива и восстанавливаем
            relative_path=$(echo "$backup" | sed -e "s|$backup_dir/||")
            restore_destination="/$relative_path"
            echo -e "\e[92mВосстановление директории из $backup в $restore_destination...\e[0m"
            mkdir -p "$restore_destination"
            rsync -av "$backup/" "$restore_destination/"
            echo -e "\e[93mДиректория восстановлена успешно\e[0m"
        fi
    done
}

# Восстановление Docker контейнеров
restore_containers() {
    if [ -f "$backup_dir/docker_containers.zip" ]; then
        echo -e "\e[92mРаспаковка резервных копий Docker контейнеров...\e[0m"
        sudo unzip -q "$backup_dir/docker_containers.zip" -d "$backup_dir"
        echo -e "\e[93mРезервные копии Docker контейнеров успешно распакованы\e[0m"

        # Восстанавливаем Docker контейнеры
        for tar_file in "$backup_dir"/*.tar; do
            if [ -f "$tar_file" ]; then
                container_name=$(basename "$tar_file" .tar)
                echo -e "\e[92mВосстановление Docker контейнера $container_name...\e[0m"
                sudo docker import "$tar_file" "$container_name"
                echo -e "\e[93mDocker контейнер $container_name восстановлен успешно\e[0m"
            fi
        done
    else
        echo -e "\e[91mПредупреждение: Zip-архив с резервными копиями Docker контейнеров не найден\e[0m"
    fi
}

# Восстановление всего
restore_all() {
    restore_directories
    restore_containers
}

# Выбор между восстановлением директорий, контейнеров или всего вместе
read -p "Что вы хотите восстановить? (директории - d, контейнеры - c, всё - a): " choice
case "$choice" in
    "d") restore_directories ;;
    "c") restore_containers ;;
    "a") restore_all ;;
    *) echo -e "\e[91mНеверный выбор\e[0m" ;;
esac

# Вывод сообщения об успешном восстановлении
echo -e "\e[92mВосстановление завершено\e[0m"
