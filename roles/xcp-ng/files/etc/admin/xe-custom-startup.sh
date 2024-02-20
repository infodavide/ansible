#!/bin/bash
FILE=/tmp/xe-custom-startup.log
SERVICE_NAME='xe-custom-startup.sh'
start_service() {
  echo "Executing xe-custom-startup">$FILE
  controller_state=$(xe vm-list|grep -b1 -a1 genova|grep power-state|cut -d: -f2|sed 's/^\s//g')
  while [ ! "$controller_state" == "running" ]; 
  do
    echo "Controller not running...">>$FILE
    sleep 4
    controller_state=$(xe vm-list|grep -b1 -a1 genova|grep power-state|cut -d: -f2|sed 's/^\s//g')
  done
  xoa_uuid=$(xe vm-list power-state=suspended|grep -v savona_|grep -b1 savona|grep uuid| cut -d: -f2| sed 's/\s//g')
  if  [ ! -z "$xoa_uuid" ]; 
  then
    echo "Resuming xoa vm...">>$FILE
    xe vm-resume uuid=$xoa_uuid
    echo "xoa vm resumed">>$FILE
    exit 0
  fi
  xoa_uuid=$(xe vm-list power-state=halted|grep -v savona_|grep -b1 savona|grep uuid| cut -d: -f2| sed 's/\s//g')
  if  [ ! -z "$xoa_uuid" ]; 
  then
    echo "Starting xoa vm...">>$FILE
    xe vm-start uuid=$xoa_uuid
    echo "xoa vm started">>$FILE
  else 
    echo "xoa vm is already started"
  fi
  uuids=$(xe vm-list power-state=suspended|grep uuid|grep -v genova|grep -v savona|cut -d: -f2|sed 's/^\s//g')
  while IFS= read -r line; do
    auto_poweron=$(xe vm-param-get uuid=$line param-name="other-config"|grep -c 'auto_poweron: true')
    if [ "$auto_poweron" == "1" ]; 
    then
      echo "Resuming vm: $line.">>$FILE
      xe vm-resume uuid="$line" &
    else
      echo "Not resuming vm: $line because auto poweron is not enabled."
    fi
  done <<< "$uuids"
  echo "Completed">>$FILE
}

case "$1" in
  status)    
    ;;
  start)
    start_service
    ;;
  stop)    
    ;;
  restart)
    start_service
    ;;
  *)
    echo "Usage: service $SERVICE_NAME {start|stop|restart|status}" >&2
    exit 1   
    ;;
esac
exit 0