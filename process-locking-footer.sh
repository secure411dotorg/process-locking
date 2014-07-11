mv "$LOCKSDIR/$SCRIPTNAME.running" "$LOCKSDIR/$SCRIPTNAME.ok"

# Save runtime in seconds and update end of run timestamp
echo "SECONDS:${SECONDS}" >> "$LOCKSDIR/$SCRIPTNAME.ok"

${PLOCKLOG} "Endofrun $SCRIPTNAME"

