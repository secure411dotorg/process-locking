mv "${LOCKSDIR}/${SCRIPTNAME}.running" "${LOCKSDIR}/${SCRIPTNAME}.ok"

# Save runtime in seconds and update end of run timestamp
echo "SECONDS:${SECONDS}" >> "${LOCKSDIR}/${SCRIPTNAME}.ok"

if [ -n "${PLOCK_ESTAT}" ]; then
	${PLOCKLOG} "Endofrun ${SCRIPTNAME} completed in ${SECONDS} seconds with exit status: ${PLOCK_ESTAT}"
	exit "${PLOCK_ESTAT}"
fi
${PLOCKLOG} "Endofrun ${SCRIPTNAME} completed in ${SECONDS} seconds"
