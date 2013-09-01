process-locking
===============

bash - Prevent a process from running multiple times

[Legal and License GPLv3](#license)

***
###PROBLEM INTENDED TO SOLVE:

I need to run bash scripts on crontab, some even every minute. They may take longer than a minute to run, and they need to run again as soon as the last run successfully completes. I have tried many different solutions to this and finally wrote this universal header and footer file because every other solution failed at one time or another. 

The centralized lock file dir lets me see at a glance which of my scripts are running and for how long. The logging gives the opportunity for potential automated graphing and monitoring of process duration / status.

By using the "source" command to include this header and footer into my scripts, I can improve or configure the file in one spot without re-editing hundreds of scripts. No configuration is needed when writing new scripts, just include the two "source" lines, one at top and one at bottom. Bytes are saved through code re-use.


***
###HOW TO USE:

###1. Create a directory where the process locking files will reside. 
The user your script(s) run as must have read and write permissions.

###2. Configure process-locking-header.sh to point to that dir. 
Do not end the path with a /

###3. In your script, source the header and footer files:

Near the top of your script (but below #!/bin/bash), insert a line such as:

```
source /path/to/process-locking-header.sh
```

At the bottom of your script, insert a line such as:

```
source /path/to/process-locking-footer.sh
```

Run your script once. It will not execute other than to create one file in the process locking dir.

The next time your script runs, it will fully execute as expected. Checking the log where your /usr/bin/logger points (such as syslog) you will see an entry for the start and end times of your script.

If you try to run your script while it is still running, you will see a message saying that the script is already running, and it will exit rather than run a second copy.

### TO CREATE LOCKS PER USER
If you want to lock execution so each user can run only one instance of a script instead of one instance for all users, make the following modifications to process-locking-header.sh:

```
LOCKSDIR=/var/lock/$USER
mkdir -p "$LOCKSDIR"	#Creates the path if it does not exist
```

<a name="license"></a>

***
###Legal Notices re GPLv3 Licensing

    Copyright (C) 2012 April Lorenzen
    
    Paper mail contact: April Lorenzen, PO Box 293, Jamestown RI 02835
    Electronic contact: https://github.com/secure411dotorg/process-locking/issues

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>
