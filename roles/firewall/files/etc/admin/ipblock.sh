#!/bin/bash
#set -x
### Block all traffic from listed. Use ISO code ###
ISO_IN="ae af ao az bf bh bi bj br bt bw cg co cm cn sg cu dz eg et id il in iq ir ke kh kw lr ly ma ml mr my na ne ng om pk qa ro sn sr sy th tr tm tw kp kr ru ir ve vn ye"
#ISO_IN="kp kr"
ISO_OUT="ae af ao az bf bh bi bj br bt bw cg co cm cn sg cu dz eg et id il in iq ir ke kh kw lr ly ma ml mr my na ne ng om pk qa ro sn sr sy th tr tm tw kp kr ir ve vn ye"
#Testing
#ISO_IN="kr"
EXTIF=eth0
IPT=/usr/sbin/iptables
IPTRE=/usr/sbin/iptables-restore
WGET=/usr/bin/wget
EGREP=/bin/egrep
AWK=/usr/bin/awk
LOCK_FILE=/tmp/.ipblock.lock
SPAMLIST_IN="countrydropin"
SPAMLIST_OUT="countrydropout"
ZONE_ROOT="/etc/ipblock/zones"
DL_ROOT_URL="http://www.ipdeny.com/ipblocks/data/aggregated"
BL_IN="/etc/ipblock/zones/ipblockin.sh"
BL_OUT="/etc/ipblock/zones/ipblockout.sh"
if [ -e ${LOCK_FILE} ] && kill -0 `cat ${LOCK_FILE}`
then
    echo "Lock file exist.. exiting"
    exit
fi
# make sure the lockfile is removed when we exit and then claim it
trap "rm -f ${LOCK_FILE}; exit" INT TERM EXIT
echo $$ > ${LOCK_FILE}
cleanOldRules(){
    $IPT -F $SPAMLIST_IN
    $IPT -F $SPAMLIST_OUT
}
# create a dir
[ ! -d $ZONE_ROOT ] && /bin/mkdir -p $ZONE_ROOT
# add chains if needed
$IPT -L $SPAMLIST_IN -n>/dev/null 2>&1 || ($IPT -N $SPAMLIST_IN && $IPT -I INPUT 1 -i $EXTIF -j $SPAMLIST_IN)
$IPT -F $SPAMLIST_IN
$IPT -L $SPAMLIST_OUT -n>/dev/null 2>&1 || ($IPT -N $SPAMLIST_OUT && $IPT -I FORWARD 1 -m state --state RELATED,ESTABLISHED -j ACCEPT && $IPT -I FORWARD 2 -j $SPAMLIST_OUT)
$IPT -F $SPAMLIST_OUT
# clean old rules
cleanOldRules
rm -f $BL_IN
rm -f $BL_OUT
echo '*filter'>$BL_IN
for c in $ISO_IN
do
    # zone file
    tDB=$ZONE_ROOT/$c-aggregated.zone
	if [ ! -f "$tDB" ]
    then
    	# get fresh zone file
    	$WGET -q -T 30 -O $tDB $DL_ROOT_URL/$c-aggregated.zone
    else
        if [[ $(find "$tDB" -mtime +31 -print) ]]
        then
    	   # get fresh zone file
    	   $WGET -q -T 30 -O $tDB $DL_ROOT_URL/$c-aggregated.zone
        fi
    fi
    $AWK -v SPAMLIST_IN=$SPAMLIST_IN '{print "-A "SPAMLIST_IN" -s "$1" -j DROP"}' $tDB>>$BL_IN
done
echo 'COMMIT'>>$BL_IN
$IPTRE -n<$BL_IN
echo '*filter'>$BL_OUT
for c in $ISO_OUT
do
    # zone file
    tDB=$ZONE_ROOT/$c-aggregated.zone
	if [ ! -f "$tDB" ]
    then
    	# get fresh zone file
    	$WGET -q -T 30 -O $tDB $DL_ROOT_URL/$c-aggregated.zone
    else
        if [[ $(find "$tDB" -mtime +31 -print) ]]
        then
    	   # get fresh zone file
    	   $WGET -q -T 30 -O $tDB $DL_ROOT_URL/$c-aggregated.zone
        fi
    fi
    $AWK -v SPAMLIST_OUT=$SPAMLIST_OUT '{print "-A "SPAMLIST_OUT" -d "$1" -j REJECT"}' $tDB>>$BL_OUT
done
echo 'COMMIT'>>$BL_OUT
$IPTRE -n<$BL_OUT
rm -f ${LOCK_FILE} 
exit 0