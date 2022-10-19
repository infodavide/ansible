#!/bin/bash
#set -x
EXTIF=eth0
IPT=/usr/sbin/iptables
IPTRE=/usr/sbin/iptables-restore
CURL=/usr/bin/curl
GREP=/usr/bin/grep
EGREP=/usr/bin/egrep
SED=/usr/bin/sed
AWK=/usr/bin/awk
LOCK_FILE=/tmp/.firehol.lock
SPAMLIST_IN="bldropin"
SPAMLIST_OUT="bldropout"
BLROOT="/etc/firehol"
BL_FILE="$BLROOT/firehol_level1.netset"
#DL_URL="https://iplists.firehol.org/files/firehol_level1.netset"
DL_URL="https://www.blocklist.de/downloads/export-ips_all.txt"
BL_IN="$BLROOT/fireholblockin.sh"
BL_OUT="$BLROOT/fireholblockout.sh"
if [ -e ${LOCK_FILE} ] && kill -0 `cat ${LOCK_FILE}`; then
    echo "Lock file exist.. exiting"
    exit
fi
trap "rm -f ${LOCK_FILE}; exit" INT TERM EXIT
echo $$ > ${LOCK_FILE}
cleanOldRules(){
    $IPT -F $SPAMLIST_IN
    $IPT -F $SPAMLIST_OUT
}
downloadSet(){
    rm -f $BL_FILE
    $CURL --connect-timeout 30 -o "$BL_FILE.tmp" $DL_URL
    $GREP -v '^#' "$BL_FILE.tmp"|$GREP -E '^([0-9]{1,3}\.)'|$GREP -vE '^172'|$GREP -vE '^127'>$BL_FILE
    rm -f "$BL_FILE.tmp"
}
# create a dir
[ ! -d $BLROOT ] && /bin/mkdir -p $BLROOT
# add chains if needed
$IPT -L $SPAMLIST_IN -n>/dev/null 2>&1 || ($IPT -N $SPAMLIST_IN && $IPT -I INPUT 1 -i $EXTIF -j $SPAMLIST_IN)
$IPT -F $SPAMLIST_IN
$IPT -L $SPAMLIST_OUT -n>/dev/null 2>&1 || ($IPT -N $SPAMLIST_OUT && $IPT -I FORWARD 1 -m state --state RELATED,ESTABLISHED -j ACCEPT && $IPT -I FORWARD 2 -j $SPAMLIST_OUT)
$IPT -F $SPAMLIST_OUT
# clean old rules
cleanOldRules
rm -f $BL_IN
rm -f $BL_OUT
if [ ! -f "$BL_FILE" ]
then
    downloadSet
else
    if [[ $(find "$BL_FILE" -mtime +31 -print) ]]
    then
        downloadSet
    fi
fi    
echo '*filter'>$BL_IN
$AWK -v SPAMLIST_IN=$SPAMLIST_IN '{print "-A "SPAMLIST_IN" -s "$1" -j DROP"}' $BL_FILE>>$BL_IN
echo 'COMMIT'>>$BL_IN
$IPTRE -n<$BL_IN
echo '*filter'>$BL_OUT
$AWK -v SPAMLIST_OUT=$SPAMLIST_OUT '{print "-A "SPAMLIST_OUT" -d "$1" -j REJECT"}' $BL_FILE>>$BL_OUT
echo 'COMMIT'>>$BL_OUT
$IPTRE -n<$BL_OUT
rm -f ${LOCK_FILE} 
exit 0
