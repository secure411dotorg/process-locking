# Configure your preferred lock file dir:
LOCKSDIR="/home/ubuntu/locks" 
#
# Nothing below here needs configuration
#
SCRIPTNAME="${0}"

if [ -e "${LOCKSDIR}/$SCRIPTNAME.ok" ];then
        mv ${LOCKSDIR}/$SCRIPTNAME.ok ${LOCKSDIR}/$SCRIPTNAME.running
        touch ${LOCKSDIR}/$SCRIPTNAME.running
        /usr/bin/logger "Starting $SCRIPTNAME" 
else   
        if [ -e "${LOCKSDIR}/$SCRIPTNAME.running" ];then
                echo "Exiting because process is already running"
                exit
        else   
                /usr/bin/logger "Creating $SCRIPTNAME.ok"
                touch ${LOCKSDIR}/$SCRIPTNAME.ok
                echo "Created the ok file - must be first time running. Exiting now - run again"
                exit
        fi
fi
