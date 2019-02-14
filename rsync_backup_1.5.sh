#!/bin/bash

# SAD 24.12.2018
# Скрипт бэкапа используя rsync
# version 1.5
# найден баг - не происходит зеркального копирования

function input_parametrs() {
  while [ 1 ];do
    if [[ "$1" == '--config' || "$1" == '-cfg' || "$1" == '-c' ]];then
      CONFIG_FILE="$2"
      parse_config
      break;
    elif [[ "$1" == '--source' || "$1" == '-src' ]];then
      SOURCE_FOLDER="$2"
      shift;
      shift;
    elif [[ "$1" == '--destination' || "$1" == '-dst' ]];then
      DESTINATION_FOLDER="$2"
      shift;
      shift;
    elif [[ "$1" == '--destination-even' || "$1" == '-evn' ]];then
      DESTINATION_FOLDER_EVEN="$2"
      shift;
      shift;
    elif [[ "$1" == '--destination-odd' || "$1" == '-odd' ]];then
      DESTINATION_FOLDER_ODD="$2"
      shift;
      shift;
    elif [[ "$1" == '--stop-file' || "$1" == '-s' ]];then
      STOP_FILE="$2"
      shift;
      shift;
    elif [[ "" == '--consistent-file' || "$1" == '-cof' ]];then
      CONSISTENT_FILE="$2"
      CONSISTENT_STRING="$3"
      shift;      
      shift;
      shift;      
    elif [[ "$1" == '--file-log' || "$1" == '-log' ]];then
      FILE_LOG="$2"
      shift;
      shift;
    elif [[ "$1" == '--file-log-all' || "$1" == '-lal' ]];then  
      FILE_LOG_ALL="$2"
      shift;
      shift;
    elif [[ "$1" == '--increment' || "$1" == '-i' || "$1" == '-inc' ]];then
      INCREMENT='true'
      shift;
    elif [[ "$1" == '--mirror' || "$1" == '-m' || "$1" == '-mir' ]];then
      MIRROR='true'
      shift;
    elif [[ "$1" == '--verbose' || "$1" == '-v' ]];then
      VERBOSE='true'
      shift;
    elif [[ "$1" == '--address-list' || "$1" == '-arl' ]];then
      ADDRESS_LIST=`echo "$2" | tr [:upper:] [:lower:]`
      shift;
      shift;
    elif [[ "$1" == '--address-file' || "$1" == '-arf' ]];then
      ADDRESS_FILE="$2"
      shift;
      shift;
    elif [[ "$1" == '--attach-verbose' || "$1" == '-atv' ]];then
      ATTACH_VERBOSE='true'
      shift;
    elif [[ "$1" == '--size-trigger' || "$1" == '-szt' ]];then
      SIZE_TRIGGER="$2"
      if [ -z "$SIZE_TRIGGER" ];then
        SIZE_TRIGGER='none'
      fi
      shift;
      shift;      
    elif [[ "$1" == '--make-dir' || "$1" == '-mkd' ]];then
      MAKE_DIRECTORY='true'
      shift;      
    elif [[ "$1" == '--user' || "$1" == '-usr' || "$1" == '-u' ]];then
      USER="$2"
      if [ -z "$USER" ];then
        USER='none'
      fi
      shift;
      shift;
    elif [[ "$1" == '--group' || "$1" == '-grp' || "$1" == '-g' ]];then
      GROUP="$2"
      if [ -z "$GROUP" ];then
        GROUP='none'
      fi
      shift;
      shift;
    elif [[ "$1" == '--help' || "$1" == '-h'  ]];then
      help;
      exit 2      
    elif [ -z "$1" ]; then
      break;
    else
      echo -e "\n$1 - Неизвестный ключ"
      help
      exit 1
    fi
 done

}

function help() {
  
  echo -e '\nUsage:\n'
  echo -e '--config           [-cfg] [-c] Конфигурационный файл (не реализовано)'
  echo -e '--source           [-src] Папка которую нужно бэкапить - обязательный параметр'
  echo -e '--destination      [-dst] Папка в которую нужно бэкапить - обязательный если не указаны -evn и -odd'
  echo -e '--destination-even [-evn] Папка в которую нужно бэкапить по четным дням - не может быть использован совместно с --destination'
  echo -e '--destination-odd  [-odd] Папка в которую нужно бэкапить по нечетным дням - не может быть использован совместно с --destination'
  echo -e '--stop-file        [-s]   Файл(флаг) остановки копирования - проверка сетевой папки на монтирование'
  echo -e '--consistent-file  [-cof] Файл для проверки консистентности папки (защита от шифровальщика)'
  echo -e '--file-log         [-log] Файл лог для текущего задания. Имя по умолчанию - sync-script-hostname-yyyy.mm.dd.rlog'
  echo -e '--file-log-all     [-lal] Файл лог общий для нескольких машин'
  echo -e '--increment        [-inc] [-i] Инкрементный бэкап'
  echo -e '--mirror           [-mir] [-m] Зеракльный бэкап'
  echo -e '--verbose          [-v]   Подробный режим rsync'
#  echo -e '--address-list     [-arl] Список адресатов для отправки письма с отчетами (не более 5-ти адресов в строчку, разделенные ",")'
#  echo -e '--attach-verbose   [-atv] Прикрепить к письму подробный отчет о копировании'
  echo -e '--size-trigger     [-szt] Минимальный размер исходной папки при которой начнется зеркальное копирование (в байтах)'
#  echo -e '--address-file     [-afl] Файл со списком адресатов'
  echo -e '--user             [-usr] [-u] После завершения копирования назначить владельцем каталога пользователя USER'
  echo -e '--group            [-grp] [-g] После завершения копирования назначить владельцами каталога группу GROUP'
  echo -e '--make-dir         [-mkd] Принудительно создавать путь указанных папок (не реализовано)'
  echo -e '--help             [-h]   Показать эту справку и выйти'

}

function yes_no() {

  read myAnswer
  until [[ "$myAnswer" ==  "y" || "$myAnswer" ==  "n" ]]
    do
    echo "y or n"
    read  myAnswer
    done

  if [ "$myAnswer" == "n" ];then
    exit 3
  fi

}

function logging() {

  LOG_DATE=`date +%Y.%m.%d\ %H:%M:%S`
    
  if [[ "$1" == 'all' ]];then

    echo -e "\n$LOG_DATE $2\n"
    echo -e "\n$LOG_DATE $2" >> "$FILE_LOG"
    echo -e "$LOG_DATE `hostname` $2" >> "$FILE_LOG_ALL"
    echo -e "$LOG_DATE `hostname` $2" >> "$MAIL_BODY"

  elif [[ "$1" == 'local-mail' ]];then

    echo -e "\n$LOG_DATE $2\n"
    echo -e "$LOG_DATE $2" >> "$FILE_LOG"
    echo -e "$2" >> "$MAIL_BODY"

  elif [[ "$1" == 'local' ]];then

    echo -e "\n$LOG_DATE $2\n"
    echo -e "$LOG_DATE $2" >> "$FILE_LOG"

  elif [[ "$1" == 'silence-all' ]];then

    echo -e "\n$LOG_DATE $2" >> "$FILE_LOG"
    echo -e "$LOG_DATE `hostname` $2" >> "$FILE_LOG_ALL"

  elif [[ "$1" == 'only-local' ]];then

    echo -e "\n$LOG_DATE $2" >> "$FILE_LOG"

  elif [[ "$1" == 'only-group' ]];then

    echo -e "$LOG_DATE `hostname` $2" >> "$FILE_LOG_ALL"

  elif [[ "$1" == 'only-echo' ]];then

    echo -e "\n$LOG_DATE $2"

  elif [[ "$1" == 'mail' ]];then

    echo -e "$2" >> "$MAIL_BODY"

  elif [[ "$1" == 'group-mail' ]];then

    echo -e "$2" >> "$MAIL_BODY"
    echo -e "$LOG_DATE $2" >> "$FILE_LOG_ALL"

  fi

}


function parse_config() {
  
  if [ ! -e "$CONFIG_FILE" ];then
    echo -e "\nconfig file - $CONFIG_FILE does not exist!\n"
    exit 20
  fi	  

  logging all "Using config file: $CONFIG_FILE" 
 
  CONFIG=`grep -Ev '^ *#|^$' $CONFIG_FILE` # This is config file prepared for parsing 
  
  SOURCE_FOLDER=`echo -e "$CONFIG" | grep -iE '^ *source folder' | awk -F 'source folder *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  DESTINATION_FOLDER=`echo -e "$CONFIG" | grep -iE '^ *destination folder' | awk -F 'destination folder *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  DESTINATION_FOLDER_EVEN=`echo -e "$CONFIG" | grep -iE '^ *even folder' | awk -F 'even folder *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  DESTINATION_FOLDER_ODD=`echo -e "$CONFIG" | grep -iE '^ *odd folder' | awk -F 'odd folder *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  STOP_FILE=`echo -e "$CONFIG" | grep -iE '^ *stop file' | awk -F 'stop file *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  CONSISTENT_FILE=`echo -e "$CONFIG" | grep -iE '^ *consistent file' | awk -F 'consistent file *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  CONSISTENT_STRING=`echo -e "$CONFIG" | grep -iE '^ *consistent string' | awk -F 'consistent string *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  SIZE_TRIGGER=`echo -e "$CONFIG" | grep -iE '^ *size trigger' | awk -F 'size trigger *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  FILE_LOG=`echo -e "$CONFIG" | grep -iE '^ *log file' | awk -F 'log file *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  FILE_LOG_ALL=`echo -e "$CONFIG" | grep -iE '^ *log group file' | awk -F 'log group file *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  INCREMENT=`echo -e "$CONFIG" | grep -iE '^ *increment' | awk -F 'increment *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  MIRROR=`echo -e "$CONFIG" | grep -iE '^ *mirror' | awk -F 'mirror *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  VERBOSE=`echo -e "$CONFIG" | grep -iE '^ *verbose' | awk -F 'verbose *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  USER=`echo -e "$CONFIG" | grep -iE '^ *user' | awk -F 'user *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  GROUP=`echo -e "$CONFIG" | grep -iE '^ *group' | awk -F 'group *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  ADDRESS_LIST=`echo -e "$CONFIG" | grep -iE '^ *address list' | awk -F 'address list *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  ADDRESS_FILE=`echo -e "$CONFIG" | grep -iE '^ *address file' | awk -F 'address file *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  ATTACH_VERBOSE=`echo -e "$CONFIG" | grep -iE '^ *attach verbose' | awk -F 'attach verbose *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
  MAKE_DIRECTORY=`echo -e "$CONFIG" | grep -iE '^ *mkdir force' | awk -F 'mkdir force *' '{print $2}' | sed 's/ * #.*//g;s/^\t*//g'`
 
  if [ -z "$SIZE_TRIGGER" ];then
    SIZE_TRIGGER='none'
  fi

  if [ -z "$USER" ];then
    USER='none'
  fi
  
  if [ -z "$GROUP" ];then
    GROUP='none'
  fi
  
  echo " " 
  echo "SOURCE_FOLDER = $SOURCE_FOLDER"
  echo "DESTINATION_FOLDER = $DESTINATION_FOLDER"
  echo "DESTINATION_FOLDER_EVEN = $DESTINATION_FOLDER_EVEN"
  echo "DESTINATION_FOLDER_ODD = $DESTINATION_FOLDER_ODD"
  echo "STOP_FILE = $STOP_FILE"
  echo "CONSISTENT_FILE = $CONSISTENT_FILE"
  echo "CONSISTENT_STRING = $CONSISTENT_STRING"
  echo "SIZE_TRIGGER = $SIZE_TRIGGER"
  echo "FILE_LOG = $FILE_LOG"
  echo "FILE_LOG_ALL = $FILE_LOG_ALL"
  echo "INCREMENT = $INCREMENT"
  echo "MIRROR = $MIRROR"
  echo "VERBOSE = $VERBOSE"
  echo "ADDRESS_LIST = $ADDRESS_LIST"
  echo "ADDRESS_FILE = $ADDRESS_FILE"
  echo "ATTACH_VERBOSE = $ATTACH_VERBOSE"
  echo "MAKE_DIRECTORY = $MAKE_DIRECTORY"

}

function make_dir_force() {

  FILE_LOG_DIR=`dirname $FILE_LOG`          
  FILE_LOG_ALL_DIR=`dirname $FILE_LOG_ALL`    

  echo "FILE_LOG_DIR - $FILE_LOG_DIR"
  echo "FILE_LOG_ALL_DIR - $FILE_LOG_ALL_DIR"

  if [ ! -e "$FILE_LOG_DIR" ];then
    
    mkdir -p "$FILE_LOG_DIR"  
    logging all "Create folder for LOG FILE: $FILE_LOG_DIR"

  fi

  if [ ! -e "$FILE_LOG_DIR" ];then

    mkdir -p "$FILE_LOG_ALL_DIR"
    logging all "Create folder for GROUP LOG FILE: $FILE_LOG_ALL_DIR"
    
    if [ ! -e "$FILE_LOG_ALL" ];then    
      
      touch "$FILE_LOG_ALL"
      logging all "Create GROUP LOG FILE: $FILE_LOG_ALL"

    fi

  fi

}

function parse_email_address() {

  if [[ "$1" == 'file' || "$1" == '-f' ]];then
    ADDRESS_LIST="$2"
    sed -i 's/ //g' "$ADDRESS_LIST"
    while read ADDRESS;do
      if [ ! -z "$ADDRESS" ] && [[ `echo "$ADDRESS" | grep -E "([a-z0-9]{1,})@(.{1,})" | wc -l` != 0 ]];then 
        EMAIL_ADDRESS+=("$ADDRESS")
      else 
        if [ ! -z "$ADDRESS" ];then
        logging local "$ADDRESS is not seem to be an e-mail address. skipping"
        fi
      fi
    done < "$ADDRESS_LIST"
  elif [[ "$1" == 'string' || "$1" == '-s' ]];then
    ADDRESS_STRING="$2"
    for (( i=1; i<=5; i++ ));do
      ADDRESS=`echo "$ADDRESS_STRING" | awk -v i="$i" -F ',' '{print $i}'`
      if [ ! -z "$ADDRESS" ] && [[ `echo "$ADDRESS" | grep -E "([a-z0-9]{1,})@(.{1,})" | wc -l` != 0 ]];then 
        EMAIL_ADDRESS+=("$ADDRESS")
      else 
        if [ ! -z "$ADDRESS" ];then
	logging local "$ADDRESS is not seems to be an e-mail address. skipping"
        fi
      fi
    done
  fi	  

}

function send_email() {
 
  if [[ "$1" == 'regular' ]];then
    HEADER="RSYNC BACKUP on $HOSTNAME"
  elif [[ "$1" == 'warning' ]];then  
    HEADER="WARNING! RSYNC BACKUP on $HOSTNAME $2"  
  elif [[ "$1" == 'error' ]];then  
    HEADER="ERROR! RSYNC BACKUP on $HOSTNAME $2"  
  else
    HEADER="RSYNC BACKUP on $HOSTNAME"  
  fi  

  if [[ `man mail | grep -c '\[\-a attachment \]'` == 1 ]];then

    MAIL_CLIENT='Heirloom'
    echo -e "Heirloom `mail -V`" >> "$MAIL_BODY" 
    mail -s "$HEADER" -r root@$HOSTNAME tech@iz2mon.aa.aliter.spb.ru < "$MAIL_BODY"

  elif [[ `man mail | grep -c '\[\-a header\]'` == 1 ]];then

    MAIL_CLIENT='bsd-mail'
    echo -e '\nuser mail agent: BSD mail\n' >> "$MAIL_BODY" 
    mail -a "Content-Type: text/plain; charset=UTF-8" -s "$HEADER" -r root@$HOSTNAME tech@iz2mon.aa.aliter.spb.ru < "$MAIL_BODY"

  elif [[ `man mail | grep -c '\-a,  --append'` == 1 ]];then
 
    MAIL_CLIENT='mailutils'
    echo -e "\nuser mail agent: Mailutils `mail -V`\n" >> "$MAIL_BODY"
    mail -a "Content-Type: text/plain; charset=UTF-8" -s "$HEADER" -r root@$HOSTNAME tech@iz2mon.aa.aliter.spb.ru < "$MAIL_BODY"

  elif [[ `man s-nail | grep -c 's-nail -h | --help'` == 1 ]];then
    
    MAIL_CLIENT='s-nail'
    echo -e '\nuser mail agent: s-nail\n' >> "$MAIL_BODY"
    mail -s "$HEADER" -r root@$HOSTNAME tech@iz2mon.aa.aliter.spb.ru < "$MAIL_BODY"

  else

    echo -e '\nНе получилось определить почтовый клиент.\n'
    MAIL_CLIENT='NONE'

  fi

}

function check_parametrs() {

 if [[ "$MAKE_DIRECTORY" == 'true' ]];then

   make_dir_force

 fi 

 # Check file log path and statements
  if [ ! -z "$FILE_LOG" ];then
    if [ ! -e "$FILE_LOG" ];then
      echo -e '\nFile log does not exist, but --file-log [-log] key is detected\n'
      exit 50
    elif [ -d "$FILE_LOG" ];then
      FILE_LOG="$FILE_LOG/sync-script-`hostname`-$TodayIs.rlog"
      if [[ "$VERBOSE" == 'true' ]];then
        logging all "WARNING! Only directory file log was specified! Log name: $FILE_LOG"
        sleep 1
      fi
    fi
  elif [ -z "$FILE_LOG" ];then
    FILE_LOG="$home_dir/sync-script-`hostname`-$TodayIs.rlog"	  
    if [[ "$VERBOSE" == 'true' ]];then
      logging all "WARNING! file log is not specified!\nDefault file log = $home_dir/sync-script-`hostname`-$TodayIs.rlog\nUse key '-log /dev/null' to log off"
      sleep 1
    fi
  fi
 
  # Check group file log path and statements 
  if [ ! -z "$FILE_LOG_ALL" ];then
    if [ ! -e "$FILE_LOG_ALL" ];then
      echo -e '\nFile group log does not exist, but --file-log-all [-lal] key is detected\n'
      exit 51
    fi
  elif [ -z "$FILE_LOG_ALL" ];then
    FILE_LOG_ALL='/dev/null'
    if [ "$VERBOSE" == 'true' ];then
      logging all "WARNING! File for group log is not defined! Continue..."
      sleep 1
    fi	    
  fi	    

  # Check source folder exists - mandatory condition
  if [ -z "$SOURCE_FOLDER" ];then
    echo -e '\nno SOURCE folder to backup!\n'
    help
    exit 31    
  elif [ ! -d "$SOURCE_FOLDER" ];then
    echo -e "\nSOURCE folder to backup "$SOURCE_FOLDER" does not exist!\n"
    exit 32  
  fi	  
  
  # Check if last symbol is not closing slash '/'

  SRC_FOLDER_LENGTH=`expr length "$SOURCE_FOLDER"`
  SRC_FOLDER_LAST_CHAR=`expr substr "$SOURCE_FOLDER" $SRC_FOLDER_LENGTH 1`
  if [[ "$SRC_FOLDER_LAST_CHAR" != '/' ]];then
    SOURCE_FOLDER=`echo $SOURCE_FOLDER | sed 's/$/\//'`
  fi

  # Check if DESTINATION_FOLDER is empty and it's only DST FOLDER - mandatory condition if other DST folders are not determinded  
  if [ -z "$DESTINATION_FOLDER" ];then
    if [ -z "$DESTINATION_FOLDER_EVEN" ] && [ -z "$DESTINATION_FOLDER_ODD" ];then 
      echo -e 'No destination folder for backup!\n'
      help
      exit 33
    elif [ -z "$DESTINATION_FOLDER_EVEN" ] || [ -z "$DESTINATION_FOLDER_ODD" ];then
      echo -e '-odd and -evn must be used together!\n'
      help
      exit 34
    fi  
  elif [ ! -d "$DESTINATION_FOLDER" ];then
    echo -e "\nDESTINATION folder to backup "$DESTINATION_FOLDER" does not exist!\n"
    exit 35
  fi

  if [ ! -z "$DESTINATION_FOLDER_EVEN" ];then
    if [ ! -d "$DESTINATION_FOLDER_EVEN" ];then
      echo -e "\ndestination folder for even days backup "$DESTINATION_FOLDER_EVEN" does not exist!\n"
      exit 36
    fi
  fi

  if [ ! -z "$DESTINATION_FOLDER_ODD" ];then
    if [ ! -d "$DESTINATION_FOLDER_ODD" ];then
      echo -e "\ndestination folder for odd days backup "$DESTINATION_FOLDER_ODD" does not exist!\n"
      exit 37
    fi
  fi

  # Check if DESTINATION folder used with DESTINATION_EVEN and DESTINATION_ODD - it is prohibbited. ONLY ONE DST. FOLDER

  if [ ! -z "$DESTINATION_FOLDER" ] && [ ! -z "$DESTINATION_FOLDER_EVEN" ];then
    echo -e "\nCan not use --destination-folder && --destination-folder-even together!\n"
    exit 30
  elif [ ! -z "$DESTINATION_FOLDER" ] && [ ! -z "$DESTINATION_FOLDER_ODD" ];then
    echo -e "\nCan not use --destination-folder && --destination-folder-odd together!\n"
    exit 38
  elif [ ! -z "$DESTINATION_FOLDER_EVEN" ] && [ ! -z "$DESTINATION_FOLDER_ODD" ];then
    EVEN_ODD_BACKUP='true'
    REGULAR_BACKUP='false'
  elif [ ! -z "$DESTINATION_FOLDER" ] && [ -z "$DESTINATION_FOLDER_EVEN" ] && [ -z "$DESTINATION_FOLDER_ODD" ];then
    EVEN_ODD_BACKUP='false'
    REGULAR_BACKUP='true'
  fi  

  if [[ "$SOURCE_FOLDER" == "$DESTINATION_FOLDER" ]];then
    logging local "Source folder and Destination folder are the same!"
    exit 39
  elif [[ "$SOURCE_FOLDER" == "$DESTINATION_FOLDER_EVEN" ]] || [[ "$SOURCE_FOLDER" == "$DESTINATION_FOLDER_ODD" ]];then
    logging local "Source folder and Destination even or odd folders are the same!"
    exit 40
  elif [[ "$DESTINATION_FOLDER_EVEN" == "$DESTINATION_FOLDER_ODD" ]] && [ ! -z "$DESTINATION_FOLDER_EVEN" ] && [ ! -z "$DESTINATION_FOLDER_ODD" ] ;then
    logging local "Destination even folder and Destination odd folders are the same!"
    exit 41
  fi	    

  # Check if STOP_FILE is given and it's exist

  if [ ! -z "$STOP_FILE" ];then
    if [ -e "$STOP_FILE" ];then
      logging all "Stop file DETECTED: $STOP_FILE. Aborting"
      send_email error 'SOURCE IS NOT MOUNTED!'
      exit 60
    elif [ ! -e "$STOP_FILE" ] && [[ "$VERBOSE" == 'true' ]];then
      logging only-echo "Stop file not found! it seem's - ok"
    fi	    
  elif [ -z "$STOP_FILE" ];then
    if [[ "$VERBOSE" == 'true' ]];then
    logging local "WARNING! Stop file is not defined! Continue..."
    sleep 1    
    fi 
  fi

  # Check consistent file is given and it's conten is correct!

  if [ ! -z "$CONSISTENT_FILE" ];then
    if [ ! -e "$CONSISTENT_FILE" ];then
      logging all "Consistent file not found: $CONSISTENT_FILE. Aborting"
      send_email error 'Consistent file not found'
      exit 70
    else  
    if [[ `grep $CONSISTENT_STRING $CONSISTENT_FILE` == "$CONSISTENT_STRING" ]];then
        if [[ "$VERBOSE" == 'true' ]];then
	  logging only-echo "Consistent file - ok"
	fi	
      else
        logging all "Consistent file content is corrupted: $CONSISTENT_FILE. Given consistent string: $CONSISTENT_STRING\nContent of $CONSISTENT_FILE:\n`cat "$CONSISTENT_FILE"`"
	send_email error 'Consistent file content is corrupted'
	exit 71
      fi	      
    fi
  elif [ -z "$CONSISTENT_FILE" ] && [[ "$VERBOSE" == 'true' ]];then
      logging local "WARNING! Consistent file is not defined! Continue..."   
  fi	  

  # Check increment && mirror statements
  if [[ "$INCREMENT" == true ]] && [[ "$MIRROR" == true ]];then
    logging local "Can not use --increment and --mirror keys together. Choose one!"
    exit 80  
  elif [[ "$INCREMENT" == true  ]] && [ ! -z "$DESTINATION_FOLDER_EVEN" ] && [ ! -z "$DESTINATION_FOLDER_ODD" ];then
    logging local 'WARNING! Using -odd and -evn for INCREMENTAL backup may make no scence!\nShure to continue?'
    yes_no
  fi	  

  # If increment and mirror keys are empty - default copy - increment
  if [ -z "$INCREMENT" ] && [ -z "$MIRROR" ];then
    if [[ "$EVEN_ODD_BACKUP" == 'true' ]];then
      MIRROR='true'
      INCREMENT='false'      
    elif [[ "$REGULAR_BACKUP" == 'true' ]];then
      INCREMENT='true'
      MIRROR='false'
    fi	    
  fi	  

  # Check address list
  
  if [ ! -z "$ADDRESS_LIST" ];then
    parse_email_address string $ADDRESS_LIST
  fi
  
  # Check address file
  
  if [ ! -z "$ADDRESS_FILE" ] && [ -e "$ADDRESS_FILE" ];then
    parse_email_address file $ADDRESS_FILE
  fi
  
  # Check if e-mail must be sent

  if [ ! -z "$ADDRESS_LIST" ] && [[ ${#EMAIL_ADDRESS[@]} == 0 ]];then
    logging local 'WARNING! No letter will be sent! But address list was sepicified'
  elif [ ! -z "$ADDRESS_FILE" ] && [[ ${#EMAIL_ADDRESS[@]} == 0 ]];then
    logging local 'WARNING! No letter will be sent! But address file was sepicified'
  elif [ ! -z "$ADDRESS_LIST" ] && [ ! -z "$ADDRESS_FILE" ] && [ "$VERBOSE" == 'true' ];then 
    logging local 'WARNING! No letter will be sent!'
  fi	  

}

function set_chown() {

  # Check user and group statements
  if [ ! -z "$USER" ] && [[ "$USER" != 'none' ]] && [ ! -z "$GROUP" ] && [[ "$GROUP" != 'none' ]] ;then
    logging all "Change recursive user - $USER & group - $GROUP for $DESTINATION_FOLDER"
    chown "$USER":"$GROUP" -R "$DESTINATION_FOLDER"
  fi

  if [ ! -z "$USER" ] && [[ "$USER" != 'none' ]] && [ ! -z "$GROUP" ] && [[ "$GROUP" == 'none' ]];then
    logging all "Change recursive user - $USER for $DESTINATION_FOLDER"
    chown "$USER" -R "$DESTINATION_FOLDER"
  fi

}

function synct() {
  
  # ЧЕТН|НЕЧЕТНЫЙ 
  # EVEN|ODD BACKUP
  
  if [[ "$EVEN_ODD_BACKUP" == 'true' ]] && [[ "$REGULAR_BACKUP" == 'false' ]];then
  	  
    DAY=`date +%d | sed 's/^0//'`
  
    if [[ $(( $DAY % 2 )) == 0  ]];then
      # ЧЕТНЫЙ
      BACKUP_TYPE='EVEN|ЧЁТНЫЙ'
      DESTINATION_FOLDER="$DESTINATION_FOLDER_EVEN"
      else
      BACKUP_TYPE='ODD|НЕЧЁТНЫЙ'   
      # НЕЧЕТНЫЙ
      DESTINATION_FOLDER="$DESTINATION_FOLDER_ODD"
    fi
  else
    BACKUP_TYPE="REGULAR"
  fi  
  
  if [ ! -z "$SIZE_TRIGGER" ] && [ "$SIZE_TRIGGER" != 'none' ];then 
    SOURCE_FOLDER_SIZE=`du -s $SOURCE_FOLDER | awk '{print $1}' | sed 's/ //g'`
    DESTINATION_FOLDER_SIZE=`du -s $DESTINATION_FOLDER | awk '{print $1}' | sed 's/ //g'`
  fi  

  if [ ! -z "$SIZE_TRIGGER" ] && [ "$SIZE_TRIGGER" != 'none' ];then
    if [[ "$SIZE_TRIGGER" > "$SOURCE_FOLDER_SIZE" ]];then
      logging all "Source folder size: $SOURCE_FOLDER_SIZE(bytes) less than trigger size $SIZE_TRIGGER(bytes)"
      send_email error
      exit 4
    else
      logging all "Source folder $SOURCE_FOLDER size - $SOURCE_FOLDER_SIZE (bytes)"
      logging all "Destination folder $DESTINATION_FOLDER size - $DESTINATION_FOLDER_SIZE (bytes)"
    fi 
  fi

  # -- INCREMENTAL BACKUP
  if [[ "$INCREMENT" == 'true' ]] && [[ "$MIRROR" != 'true'  ]];then 
      if [[ "$VERBOSE" == 'true' ]];then
      logging all "start incremental $BACKUP_TYPE backup from $SOURCE_FOLDER to $DESTINATION_FOLDER"
      rsync -avh "$SOURCE_FOLDER" "$DESTINATION_FOLDER" | tee -a "$FILE_LOG" 
      wait
    else
      logging all "start incremental $BACKUP_TYPE backup from $SOURCE_FOLDER to $DESTINATION_FOLDER"
      rsync -avh "$SOURCE_FOLDER" "$DESTINATION_FOLDER" >> "$FILE_LOG"
      wait	    
    fi
  fi

  # -- MIRROR BACKUP  

  if [[ "$MIRROR" == 'true' ]] && [[ "$INCREMENT" != 'true' ]];then
      if [[ "$VERBOSE" == 'true' ]];then	  
      logging all "start mirror $BACKUP_TYPE backup from $SOURCE_FOLDER to $DESTINATION_FOLDER"
      rsync -avh --del "$SOURCE_FOLDER" "$DESTINATION_FOLDER" | tee -a "$FILE_LOG"
      wait
    else
      logging all "start mirror $BACKUP_TYPE backup from $SOURCE_FOLDER to $DESTINATION_FOLDER"
      rsync -avh --del "$SOURCE_FOLDER" "$DESTINATION_FOLDER" >> "$FILE_LOG"
      wait	    
    fi
  fi

}

TodayIs=$(date +%Y-%m-%d)
ABSOLUTE_FILENAME=`readlink -e "$0"`
home_dir=`dirname $ABSOLUTE_FILENAME`
EMAIL_ADDRESS=()
MAIL_BODY="$home_dir/mailbody_$TodayIs"
HOSTNAME=`hostname`

input_parametrs ${1} ${2} ${3} ${4} ${5} ${6} ${7} ${8} ${9} ${10} ${11} ${12} ${13} ${14} ${15} ${16} ${17} ${18} ${19} ${20}
check_parametrs

# Пишем основное тело письма:
logging mail "Скрипт резервного копирования: $ABSOLUTE_FILENAME"
logging group-mail "Сервер:                        `hostname`"
logging group-mail "Время запуска:                 $TodayIs"

synct

if [ ! -e "$FILE_LOG" ];then
  RSYNC_REPORT=`tail -n2 $FILE_LOG`
  logging group-mail "$RSYNC_REPORT"
fi

set_chown

if [ -e "$FILE_LOG" ];then
  
  RSYNC_REPORT=`tail -n3 "$FILE_LOG"`
  logging mail "$RSYNC_REPORT"

fi

logging all "Время завершения:              $(date +%Y-%m-%d\ %H:%M:%S)"

send_email regular

rm $MAIL_BODY

exit 0
