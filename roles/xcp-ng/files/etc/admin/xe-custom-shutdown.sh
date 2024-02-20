#!/bin/bash
FILE=/tmp/xe-custom-shutdown.log
SERVICE_NAME='xe-custom-shutdown.sh'
stop_service() {
  echo "Executing xe-custom-shutdown">$FILE
  names=$(xe vm-list power-state=running|grep name|grep -v genova|grep -v savona|cut -d: -f2|sed 's/^\s//g')
  while IFS= read -r line; do
    echo "Suspending VM: $line">>$FILE
    xe vm-suspend vm="$line"
    echo "VM suspended: $line">>$FILE
  done <<< "$names"
  echo "Completed">>$FILE
}

case "$1" in
  status)    
    ;;
  start)
    ;;
  stop)
    stop_service
    ;;
  restart)
    stop_service
    ;;
  *)
    echo "Usage: service $SERVICE_NAME {start|stop|restart|status}" >&2
    exit 1   
    ;;
esac
exit 0