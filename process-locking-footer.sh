touch /home/ubuntu/locks/$SCRIPTNAME.ok
rm /home/ubuntu/locks/$SCRIPTNAME.running
/usr/bin/logger "Endofrun $SCRIPTNAME"
