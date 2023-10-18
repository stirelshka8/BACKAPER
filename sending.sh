#!/bin/bash

log_dir="/BACKUPS/logs"
log_file="$log_dir/logs_sending_$(date +'%Y%m%d_%H%M%S').log"

log_message() {
    mkdir -p "$log_dir"

    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" >> "$log_file"
}

log_message "********* START SENDING *********"  


# Проверка наличия установленных пакетов
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

check_packages "sshpass" "zip"

echo -e "\e[92mПодготовка к отправке на удаленный сервер ...\e[0m"
log_message "Подготовка к отправке на удаленный сервер ..."

# Параметры удаленного сервера SSH
REMOTE_USER="adminserver"
REMOTE_HOST="192.168.1.1"
REMOTE_DIR="/home/admin"
REMOTE_PASS="00000"
# Локальная директория для упаковки
LOCAL_DIR="/BACKUPS"

echo -e "\e[92mСодержимое '$LOCAL_DIR' подготавливается к отправке ...\e[0m"

# Имя архива
ARCHIVE_NAME="sendback_$(date +'%Y%m%d%H%M%S').zip"

echo -e "\e[92mЗапущено архивирование содержимого '$LOCAL_DIR' ...\e[0m"
# Упаковка директории в архив
zip -r "$LOCAL_DIR/$ARCHIVE_NAME" "$LOCAL_DIR"

# Отображение процесса выполнения
log_message "Директория $LOCAL_DIR заархивирована и готова к отправке."
echo -e "\e[93mУпаковка директории в архив завершена.\e[0m"

# Передача архива на удаленный сервер с авторизацией по паролю
log_message "Передача директории ..."
sshpass -p "$REMOTE_PASS" scp "$LOCAL_DIR/$ARCHIVE_NAME" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_DIR"

# Проверка передачи архива
if [ $? -eq 0 ]; then
    echo -e "\e[93mПередача архива на удаленный сервер завершена. Удаленная машина - $REMOTE_HOST, директория - $REMOTE_DIR.\e[0m"
    log_message "Передача архива на удаленный сервер завершена. Удаленная машина - $REMOTE_HOST, директория - $REMOTE_DIR."
    # Удаление локального архива
    rm "$LOCAL_DIR/$ARCHIVE_NAME"
    log_message "Директория $LOCAL_DIR/$ARCHIVE_NAME удалена."
    log_message "********* FINISH *********"  
else
    echo -e "\e[91mОшибка при передаче архива на удаленный сервер.\e[0m"
    log_message "Ошибка при передаче архива на удаленный сервер."
    # Удаление локального архива
    rm "$LOCAL_DIR/$ARCHIVE_NAME"
    log_message "Директория $LOCAL_DIR/$ARCHIVE_NAME удалена."
    log_message "********* FINISH *********"
fi