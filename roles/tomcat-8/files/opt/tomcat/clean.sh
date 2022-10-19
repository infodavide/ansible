#!/bin/sh
# Interfacing clean script used when deploying webapps
# Version: ${project.version}
BASE=/opt/tomcat
USER_ADMIN=tomcat 
GROUP_ADMIN=tomcat 

if [ -z "$BASE" ]
then
	echo "Base is empty"
	exit 1
fi

rm -vfR ${BASE}/applications/*.war
rm -vfR ${BASE}/webapps/*.war
rm -vfR ${BASE}/work/Catalina/localhost
rm -vf ${BASE}/logs/catalina.out
rm -vf ${BASE}/logs/*.log

chown -Rv ${USER_ADMIN}.${GROUP_ADMIN} ${BASE}/

chmod -Rv u+rwX,g+rwX,o-rwX ${BASE}/
chmod -v u+rwx,g+rwx,o-rwX ${BASE}/*.sh
chmod -v u+rwx,g+rwx,o-rwX ${BASE}/bin/*.sh