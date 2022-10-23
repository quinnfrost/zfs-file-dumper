#!/bin/bash
. ./common.sh




if [[ $1 = "WARN" ]]
then
	[[ $ERRORFILE != "" ]] && echo \[$(date "+%Y%m%d %H:%M:%S")\ $1 ] $2 >> $ERRORFILE
							  echo \[$(date "+%Y%m%d %H:%M:%S")\ $1 ] $2
else
	[[ $LOGFILE != "" ]] && echo \[$(date "+%Y%m%d %H:%M:%S")\] $@ >> $LOGFILE
						 	echo \[$(date "+%Y%m%d %H:%M:%S")\] $@
fi


