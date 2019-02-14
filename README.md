# rsync-backup
Скрипт с конфигурационным файлом для организации зеркальных и инкрементных бэкапов с помощью утилиты rsync
# Резервные копии rsync
## Основные режимы использования:
* Создание ИНКРЕМЕНТНЫХ копий в режиме архивирования с сохранением прав владельца, доступа, временных меток и копирования симлинков
* Создание ЗЕРКАЛЬНЫХ копий в режиме архивирования
* Создание ЗЕРКАЛЬНЫХ или ИНКРЕМЕНТНЫХ копий с чередованием по четным/нечетным дням
* Возможны 3 типа проверок источника данных перед копированием:
  1. Проверка точки монтирования<br>Проверяет есть ли указанный файл в папке источника, если он присутствует - значит папка несмонтирована и копирование не начнется
  2. Проверка целостности (консистенции) файлов<br>Проверяет наличие и содержимое файла, если файл на месте и содержимое файла соответствует указанному - проверка пройдена
  3. Минимальный объем файлов в источнике данных<br>Если объем источника меньше указанного лимита - проверка не пройдена
* Установление необходимых владельца и/или группы после копирования файлов в целевой папке
* Ведение полного лога (file-log) и общего (меньше информации) лога (file-log-all) 
* И еще некоторые незадокументированные возможности (фичи и баги) :)  

### --help
```
--help             [-h]   Показать эту справку и выйти
--config           [-cfg] [-c] Конфигурационный файл (не реализовано)
--source           [-src] Папка которую нужно бэкапить - обязательный параметр
--destination      [-dst] Папка в которую нужно бэкапить - обязательный если не указаны -evn и -odd
--destination-even [-evn] Папка в которую нужно бэкапить по четным дням - не может быть использован совместно с --destination
--destination-odd  [-odd] Папка в которую нужно бэкапить по нечетным дням - не может быть использован совместно с --destination
--stop-file        [-s]   Файл(флаг) остановки копирования - проверка сетевой папки на монтирование
--consistent-file  [-cof] Файл для проверки консистентности папки (защита от шифровальщика)
--file-log         [-log] Файл лог для текущего задания. Имя по умолчанию - sync-script-hostname-yyyy.mm.dd.rlog
--file-log-all     [-lal] Файл лог общий для нескольких машин
--increment        [-inc] [-i] Инкрементный бэкап
--mirror           [-mir] [-m] Зеракльный бэкап
--verbose          [-v]   Подробный режим rsync
--size-trigger     [-szt] Минимальный размер исходной папки при которой начнется зеркальное копирование (в байтах)
--user             [-usr] [-u] После завершения копирования назначить владельцем каталога пользователя USER
--group            [-grp] [-g] После завершения копирования назначить владельцами каталога группу GROUP
```
### В будущей реализации:
```
--address-file     [-afl] Файл со списком адресатов
--address-list     [-arl] Список адресатов для отправки письма с отчетами (не более 5-ти адресов в строчку, разделенные ",")
--attach-verbose   [-atv] Прикрепить к письму подробный отчет о копировании
--make-dir         [-mkd] Принудительно создавать путь указанных папок
```
## TODO
* Реализовать проверку точки монтирования с через mount
* Принудительно создавать путь указанных папок
* Отключить принудительную отправку писем
* Указать формат отправления писем вручную
  
