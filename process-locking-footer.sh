echo "${SECONDS}" > "$LOCKSDIR/$SCRIPTNAME.ok"
rm "$LOCKSDIR/$SCRIPTNAME.running"
/usr/bin/logger "Endofrun $SCRIPTNAME"
