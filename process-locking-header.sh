# PLOCKLOG on by default should be turned off for high volume scripts to prevent filling /var/log
# A value of 1, f, or false will shut off the use of /usr/bin/logger at the start and end
PLOCKLOG="${PLOCKLOG:-true}"
# Exit status number for process already running
PLOCKEXIT="${PLOCKEXIT:-221}"
# Limit to the number of args that will be saved to the .running and .ok files if number of args is exceeded
# only the number of args will be saved
PLARGLIMIT="${PLARGLIMIT:-20}"

# Limit to the number of characters saved from args
PLARGCHARS="${PLARGCHARS:-1000}"

#Using a function allows the use of local variables to avoid cluttering the variable namespace
function sleepB4PL () {
	local RSLEEP_MAX="${RSLEEP_MAX:-0}"
	if [ "${RSLEEP_MAX}" -gt 59 ]; then
		echo "WARNING: RSLEEP_MAX must never be set to greater than the crontab interval.  To prevent this warning, set to below 60" 1>&2
	fi
	local RSLEEPTIME="${RANDOM:0:${#RSLEEP_MAX}}"
	while [ "${RSLEEPTIME}" -gt "${RSLEEP_MAX}" ]; do
		RSLEEPTIME="$((RSLEEPTIME-RSLEEP_MAX))"
	done
	echo "Delaying for ${RSLEEPTIME} seconds..." 1>&2
	sleep "${RSLEEPTIME}"
}
#Add a random sleep before checking lock status from 0-59 seconds (larger numbers are honored but will display warning)
#NOTE: The intended purpose of this feature is to allow running scripts with different args that share the same lock
# to retry at random times within the same minute.  The sleep is randomish, so one script may run more frequently
# than others on the same interval.

if [ "${RSLEEP_MAX:-0}" -gt 0 ]; then
	sleepB4PL
fi
# A value of true for HASHARGS4LOCK will allow the same script to run with different args
# We are using true temporary while we transition our scripts to set true explicitly
HASHARGS4LOCK="${HASHARGS4LOCK:-true}"
# Configure your preferred lock file dir:
# On most systems /var/lock is cleared on reboot, which is often good.
LOCKSDIR="${LOCKSDIR:-/var/lock}"
# FIXME the RM old ok ts is hard coded which is incompatible with getting updates for the process-locking repo if you change it locally
# all vars should work with vars specified in the script that sources them. 
# Remove ok files created before RM_OLD_OK_TS for SCRIPTNAME_NOARGS
RM_OLD_OK_TS="${RM_OLD_OK_TS:-48 hours ago}"
#
# Nothing below here needs configuration
#

SCRIPTNAME_NOARGS="${0##*/}"

case "$( echo "${HASHARGS4LOCK}" | tr '[A-Z]' '[a-z]' )" in

	custom	)	if [ -z "${SCRIPTNAME}" ]; then
				echo "Warning: HASHARGS4LOCK is set to custom and SCRIPTNAME is null, falling back to HASHARGS4LOCK=true" 1>&2
				if [ "$#" = 0 ]; then
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
				fi
			fi;;

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

case "$( echo "${PLOCKLOG:-true}" | tr '[A-Z]' '[a-z]' )" in

	0|t|true )	PLOCKLOG="/usr/bin/logger";;

	# /bin/true could be in /usr/bin/true, so I have opted for the : built-in which does the same thing
	1|f|false )	PLOCKLOG=":";;

	*	)	echo "Unrecognized value for PLOCKLOG: ${PLOCKLOG}: Logging remains on." 1>&2
			PLOCKLOG="/usr/bin/logger";;

esac

if [ -e "${LOCKSDIR}/${SCRIPTNAME}.ok" ];then
        mv "${LOCKSDIR}/${SCRIPTNAME}.ok" "${LOCKSDIR}/${SCRIPTNAME}.running" 1>&2
        echo "PID:$$" > "${LOCKSDIR}/${SCRIPTNAME}.running"
	# Include script arguments in .running file for better understanding of errors.
	# There has to be some limit to the size of the arguments stored in the .running file
	# wildcard expansion on a large list of files will add to I/O wait and file size if stored
	if [ "$#" -le "${PLARGLIMIT}" ]; then
		PLARGSTEMP="$@"
		if [ "${#PLARGSTEMP}" -gt "${PLARGCHARS}" ]; then
			echo "ARGUMENTS:${PLARGSTEMP:0:${PLARGCHARS}}..." >> "${LOCKSDIR}/${SCRIPTNAME}.running"
		else
			echo "ARGUMENTS:${PLARGSTEMP}" >> "${LOCKSDIR}/${SCRIPTNAME}.running"
			unset PLARGSTEMP
		fi
	else
		echo "ARGUMENTS:limit exceeded:$#" >> "${LOCKSDIR}/${SCRIPTNAME}.running"
	fi	
        ${PLOCKLOG} "Starting $SCRIPTNAME" 
else   
        if [ -e "${LOCKSDIR}/${SCRIPTNAME}.running" ];then
                echo "Exiting because process is already running" 1>&2
                exit "${PLOCKEXIT}"
        else   
                ${PLOCKLOG} "Creating ${SCRIPTNAME}.ok"
                touch "${LOCKSDIR}/${SCRIPTNAME}.ok"
                echo "Created the ok file - must be first time running." 1>&2
        	mv "${LOCKSDIR}/$SCRIPTNAME.ok" "${LOCKSDIR}/${SCRIPTNAME}.running"
        	echo "PID:$$" > "${LOCKSDIR}/${SCRIPTNAME}.running"
		if [ "$#" -le "${PLARGLIMIT}" ]; then
			PLARGSTEMP="$@"
			if [ "${#PLARGSTEMP}" -gt "${PLARGCHARS}" ]; then
				echo "ARGUMENTS:${PLARGSTEMP:0:${PLARGCHARS}}" >> "${LOCKSDIR}/${SCRIPTNAME}.running"
			else
				echo "ARGUMENTS:${PLARGSTEMP}" >> "${LOCKSDIR}/${SCRIPTNAME}.running"
				unset PLARGSTEMP
			fi
		else
			echo "ARGUMENTS:limit exceeded:$#" >> "${LOCKSDIR}/${SCRIPTNAME}.running"
		fi	
        	${PLOCKLOG} "Starting ${SCRIPTNAME}" 
        fi
fi

# Clean up old ok files for files begining with SCRIPTNAME_NOARGS and ending with .ok
OK_FILES=`stat -c "%Y %n" "${LOCKSDIR}/${SCRIPTNAME_NOARGS}"*.ok 2>/dev/null`
if [ -n "${OK_FILES}" ]; then
	EXPIRE_EPOCH="$( date -d "${RM_OLD_OK_TS}" +%s )"
	echo "${OK_FILES}" | while read FILETS FILE; do
		if [ "${FILETS}" -lt "${EXPIRE_EPOCH:-0}" ]; then
			echo "Removing old ok file: ${FILE}" 1>&2
			${PLOCKLOG} "Removing old ok file: ${FILE}"
			rm -f "${FILE}"
		fi
	done
fi
