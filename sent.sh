#!/bin/bash

# Параметры удаленного сервера SSH
REMOTE_USER="adminserver"
REMOTE_HOST="192.168.1.1"
REMOTE_DIR="/home/admin"

# Локальная директория для упаковки
LOCAL_DIR="/BACKUPS"

# Имя архива
ARCHIVE_NAME="sentback_$(date +'%Y%m%d%H%M%S').zip"

# Упаковка директории в архив
zip -r "$LOCAL_DIR/$ARCHIVE_NAME" "$LOCAL_DIR"

# Отображение процесса выполнения
echo "Упаковка директории в архив завершена."

# Передача архива на удаленный сервер с авторизацией по паролю
sshpass -p "000000" scp "$LOCAL_DIR/$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

# Проверка успешности передачи архива
if [ $? -eq 0 ]; then
    echo "Передача архива на удаленный сервер завершена."
    # Удаление локального архива
    rm "$LOCAL_DIR/$ARCHIVE_NAME"
else
    echo "Ошибка при передаче архива на удаленный сервер."
    # Удаление локального архива
    rm "$LOCAL_DIR/$ARCHIVE_NAME"
fi