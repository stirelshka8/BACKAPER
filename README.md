# Руководство по использованию скриптов для резервного копирования и восстановления

## backup.sh

Скрипт `backup.sh` создает резервные копии директорий и Docker контейнеров.

1. Запустите скрипт с помощью `sudo backup.sh`.
2. Следуйте указаниям в терминале.

ВАЖНО! Резервные копии создаются в корне системы, в директории BACKUPS.

## recovery.sh

Скрипт `recovery.sh` восстанавливает данные из резервных копий.

1. Запустите скрипт с помощью `sudo recovery.sh`.
2. Следуйте указаниям в терминале.

ВАЖНО! Данные для восстановления резервных копий берутся из директории BACKUPS что в корне системы, если там несколько резервных копий то будет использован самый новый.

## sending.sh

Скрипт `sending.sh` передает резервные копии на удаленный сервер по SSH.

1. Настройте скрипт для этого отредактируйте его и внесите изменения:
   - В переменной REMOTE_USER - укажите имя пользователя на удаленной машине.
   - В переменной REMOTE_HOST - укажите хост удаленной магины.
   - В переменной REMOTE_DIR - укажите директорию в которую будут отправлены данные (директория должна быть создана заранее).
   - В переменной LOCAL_DIR - укажите директорию которая предварительно будет упакована в ZIP архив и передана на удаленную машину.
2. Запустите скрипт с помощью `sudo sending.sh`.

Следуйте этим инструкциям, чтобы создавать, восстанавливать и передавать резервные копии с помощью этих скриптов.