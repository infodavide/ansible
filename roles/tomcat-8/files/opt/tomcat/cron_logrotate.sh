#!/bin/bash
# Interfacing script used to rotate application(s) logs
# Scripts based on /appli/tomcat/scripts/logrotate.sh
# Version: ${project.version}
DATE=$(date -d yesterday +%Y%m%d)
BASE=/opt/tomcat
USER_ADMIN=tomcat

#purge logs
PURGE=7
#purge threaddumps
PURGE_TD=7
#purge heapdumps
PURGE_HD=7

[ "$(id -u)" != "$(id -u $USER_ADMIN)" ] && echo "$(basename $0) must be run as $USER_ADMIN!" && exit 1

exec 1>$BASE/logs/logrotate.log 2>&1

. $BASE/setenv

mkdir -p BASE/logs/archives
mkdir -p BASE/logs/threaddumps
mkdir -p BASE/logs/heapdumps
echo $BASE

### purge
for j in $(find $BASE/logs/archives -type f -mtime +$PURGE);do
	echo " - $j"
	rm $j
done
for j in $(find $BASE/logs/threaddumps -type f -mtime +$PURGE_TD);do
	echo " - $j"
	rm $j
done
for j in $(find $BASE/logs/heapdumps -type f -mtime +$PURGE_HD);do
	echo " - $j"
	sudo -u $USER_INSTANCE sh -c "rm $j"
done

### rotate the files already rotated by the logger
for j in $(find $BASE/logs -name *.log.* -maxdepth 1 -type f);do

	FILE=$BASE/logs/archives/$DATE.$(basename $j)
	mv $j $FILE
	echo " + $FILE.gz"
done

### rotate the log files
for j in $(find $BASE/logs -name *.log -maxdepth 1 -type f ! -size 0);do

	FILE=$BASE/logs/archives/$DATE.$(basename $j)
	cp $j $FILE
	echo " + $FILE.gz"
	sudo -u $USER_INSTANCE sh -c "echo -n>$j"
done

### compression
for j in archives threaddumps;do for f in $(find $BASE/logs/$j -type f ! -name '*.gz' -print);do gzip -f $f;done;done
for f in $(find $BASE/logs/heapdumps -type f ! -name '*.gz' -print);do sudo -u $USER_INSTANCE sh -c "gzip -f $f";done

echo
