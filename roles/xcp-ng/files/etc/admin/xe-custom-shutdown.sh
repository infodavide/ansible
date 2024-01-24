#!/bin/bash
SERVICE_NAME='xe-custom-shutdown.sh'
stop_service() {
  names=$(xe vm-list power-state=running|grep name|grep -v genova|grep -v savona|cut -d: -f2|sed 's/^\s//g')
  while IFS= read -r line; do
    xe vm-suspend vm="$line"
  done <<< "$names"
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