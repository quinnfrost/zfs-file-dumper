#!/bin/bash
. ./common.sh




if [[ $1 = "WARN" ]]
then
	[[ $ERRORFILE != "" ]] && echo -e "[$(date "+%Y%m%d %H:%M:%S") $1 ] $2" >> $ERRORFILE
	[[ $QUIET -ne 1 ]]	   && echo -e "[$(date "+%Y%m%d %H:%M:%S") $1 ] $2"
fi

[[ $LOGFILE != "" ]] && echo -e "[$(date "+%Y%m%d %H:%M:%S")] $@" >> $LOGFILE
[[ $QUIET -ne 1 ]]   && echo -e "[$(date "+%Y%m%d %H:%M:%S")] $@"
