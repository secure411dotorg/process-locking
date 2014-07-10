#mv "$LOCKSDIR/$SCRIPTNAME.running" "$LOCKSDIR/$SCRIPTNAME.ok"
#echo "SECONDS:${SECONDS}" >> "$LOCKSDIR/$SCRIPTNAME.ok"
rm "$LOCKSDIR/$SCRIPTNAME.running" 
/usr/bin/logger "Endofrun $SCRIPTNAME"

