# PLOCKLOG on by default should be turned off for high volume scripts to prevent filling /var/log
PLOCKLOG="${PLOCKLOG:-true}"
# FIXME there are 3 places here and one in footer that use the logger - please find a way to make them inactive if PLOCKLOG is false
#
# A value of true for HASHARGS4LOCK will allow the same script to run with different args
# We are using true temporary while we transition our scripts to set true explicitly
HASHARGS4LOCK="${HASHARGS4LOCK:-true}"
# Configure your preferred lock file dir:
LOCKSDIR="/var/lock"
# FIXME the RM old ok ts is hard coded which is incompatible with getting updates for the process-locking repo if you change it locally
# all vars should work with vars specified in the script that sources them. 
# Remove ok files created before RM_OLD_OK_TS for SCRIPTNAME_NOARGS
RM_OLD_OK_TS="48 hours ago"
#
# Nothing below here needs configuration
#

SCRIPTNAME_NOARGS="${0##*/}"

case "$( echo "${HASHARGS4LOCK}" | tr '[A-Z]' '[a-z]' )" in

	0|t|true )	if [ "$#" = 0 ]; then
				SCRIPTNAME="${0##*/}"
			else
				for i in /usr/bin/md5sum /sbin/md5 /bin/md5sum /usr/local/bin/md5sum "$(which md5sum || which md5)"; do
					if [ -f "${i:-/dev/null/null}" ]; then
						SCRIPTNAME="${0##*/}.$(echo "$@" | ${i} | awk '{print $1}')"
						break
					fi
				done
				if [ -z "${SCRIPTNAME}" ]; then
					echo "Error: Unable to locate md5sum utility to hash arguments: ingoring args and limiting to 1 instance of script" 1>&2
					SCRIPTNAME="${0##*/}"
				fi
			fi;;

	1|f|false )	SCRIPTNAME="${0##*/}";;

esac

if [ -e "${LOCKSDIR}/${SCRIPTNAME}.ok" ];then
        mv "${LOCKSDIR}/${SCRIPTNAME}.ok" "${LOCKSDIR}/${SCRIPTNAME}.running" 1>&2
        echo "PID:$$" > "${LOCKSDIR}/${SCRIPTNAME}.running"
	# Include script arguments in .running file for better understanding of errors.
	echo "ARGUMENTS:$@" >> "${LOCKSDIR}/${SCRIPTNAME}.running"
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
