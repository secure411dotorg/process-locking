# Configure your preferred lock file dir:
LOCKSDIR="/var/lock" 
# Remove ok files created before RM_OLD_OK_TS for SCRIPTNAME_NOARGS
RM_OLD_OK_TS="48 hours ago"	
#
# Nothing below here needs configuration
#

SCRIPTNAME_NOARGS=`echo "${0##*/}"|sed 's/[^[:alnum:]_.\-]//g'`

SCRIPTNAME=`echo "${SCRIPTNAME_NOARGS}.${1}.${2}.${3}" | sed -e 's/[^[:alnum:]._\-]//g; s/\.\.*/./g; s/.$//'`

if [ -e "${LOCKSDIR}/${SCRIPTNAME}.ok" ];then
        mv "${LOCKSDIR}/${SCRIPTNAME}.ok" "${LOCKSDIR}/${SCRIPTNAME}.running" 1>&2
        echo "$$" > "${LOCKSDIR}/${SCRIPTNAME}.running"
        /usr/bin/logger "Starting $SCRIPTNAME" 
else   
        if [ -e "${LOCKSDIR}/${SCRIPTNAME}.running" ];then
                echo "Exiting because process is already running" 1>&2
                exit
        else   
                /usr/bin/logger "Creating ${SCRIPTNAME}.ok"
                touch "${LOCKSDIR}/${SCRIPTNAME}.ok"
                echo "Created the ok file - must be first time running." 1>&2
        	mv "${LOCKSDIR}/$SCRIPTNAME.ok" "${LOCKSDIR}/${SCRIPTNAME}.running"
        	echo "$$" > "${LOCKSDIR}/${SCRIPTNAME}.running"
        	/usr/bin/logger "Starting ${SCRIPTNAME}" 
        fi
fi

# Clean up old ok files for files begining with SCRIPTNAME_NOARGS and ending with .ok
OK_FILES=`stat -c "%Y %n" "${LOCKSDIR}/${SCRIPTNAME_NOARGS}"*.ok 2>/dev/null`
if [ -n "${OK_FILES}" ]; then
	EXPIRE_EPOCH="$( date -d "${RM_OLD_OK_TS}" +%s )"
	echo "${OK_FILES}" | while read FILETS FILE; do
		if [ "${FILETS}" -lt "${EXPIRE_EPOCH:-0}" ]; then
			echo "Removing old ok file: ${FILE}" 1>&2
			/usr/bin/logger "Removing old ok file: ${FILE}"
			rm -f "${FILE}"
		fi
	done
fi
