#!/bin/bash
LOG_FILE=/tmp/cron_send_backups.log
ZIP_FILE="/tmp/backups-$(date +"%Y-%m-%d").gz"
TO=$(cat /etc/aliases |grep root | cut -d: -f2)
rm -f $LOG_FILE>/dev/null 2>&1
rm -f /tmp/backups-*.gz>/dev/null 2>&1
DIRS=()
while IFS= read -r -d $'\0'; do
	echo "Adding $REPLY to the list of folders..."
    DIRS+=("$REPLY")
done < <(find /srv -type d -name *dumps* -print0)
for dir in "${DIRS[@]}"
do	
	echo "Adding $dir to $ZIP_FILE..."
    gzip -cr9  $dir > $ZIP_FILE
done
if [ -f "$ZIP_FILE" ]; then
	echo "Sending $ZIP_FILE to root..."
	echo "Backups for this week" | mail -s "$HOSTNAME - Backups for this week" $TO -A $ZIP_FILE
	rm -f /tmp/backups-*.gz>/dev/null 2>&1
fi
exit 0
