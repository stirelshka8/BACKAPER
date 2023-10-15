#!/bin/bash

if ! command -v zip &> /dev/null; then
    echo -e "\e[91mПредупреждение: Не установлен пакет zip\e[0m"
    echo -e "\e[91m *Установите его перед выполнением скрипта*\e[0m"
    exit 1
fi

if ! command -v sshpass &> /dev/null; then
    echo -e "\e[91mПредупреждение: Не установлен пакет sshpass\e[0m"
    echo -e "\e[91m *Установите его перед выполнением скрипта*\e[0m"
    exit 1
fi

echo -e "\e[92mПодготовка к отправке на удаленный сервер ...\e[0m"

# Параметры удаленного сервера SSH
REMOTE_USER="adminserver"
REMOTE_HOST="192.168.1.1"
REMOTE_DIR="/home/admin"
REMOTE_PASS="00000"
# Локальная директория для упаковки
LOCAL_DIR="/BACKUPS"

echo -e "\e[92mСодержимое '$LOCAL_DIR' подготавливается к отправке ...\e[0m"

# Имя архива
ARCHIVE_NAME="sentback_$(date +'%Y%m%d%H%M%S').zip"

echo -e "\e[92mЗапущено архивирование содержимого '$LOCAL_DIR' ...\e[0m"
# Упаковка директории в архив
zip -r "$LOCAL_DIR/$ARCHIVE_NAME" "$LOCAL_DIR"

# Отображение процесса выполнения
echo -e "\e[93mУпаковка директории в архив завершена.\e[0m"

# Передача архива на удаленный сервер с авторизацией по паролю
sshpass -p "$REMOTE_PASS" scp "$LOCAL_DIR/$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

# Проверка успешности передачи архива
if [ $? -eq 0 ]; then
    echo -e "\e[93mПередача архива на удаленный сервер завершена.\e[0m"
    # Удаление локального архива
    rm "$LOCAL_DIR/$ARCHIVE_NAME"
else
    echo -e "\e[91mОшибка при передаче архива на удаленный сервер.\e[0m"
    # Удаление локального архива
    rm "$LOCAL_DIR/$ARCHIVE_NAME"
fi