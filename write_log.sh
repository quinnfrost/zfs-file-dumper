#!/bin/bash
. ./common.sh

if [[ $@ = "" ]]
then
	while read LOG_LINE
	do
		[[ $ERRORFILE != "" ]]	&& echo -e "[$(date "+%Y%m%d %H:%M:%S") STDERR ][${OBJECT_ID:-'no_id'}] $LOG_LINE" >> $ERRORFILE
		[[ $LOGFILE != "" ]] 	&& echo -e "[$(date "+%Y%m%d %H:%M:%S") STDERR ][${OBJECT_ID:-'no_id'}] $LOG_LINE" >> $LOGFILE
		[[ $QUIET -ne 1 ]] 		&& echo -e "[$(date "+%Y%m%d %H:%M:%S") STDERR ][${OBJECT_ID:-'no_id'}] $LOG_LINE"
	done < "/dev/stdin"
else
	if [[ $1 = "WARN" ]]
	then
		[[ $ERRORFILE != "" ]] 	&& echo -e "[$(date "+%Y%m%d %H:%M:%S") $1 ][${OBJECT_ID:-'no_id'}] $2" >> $ERRORFILE
		[[ $QUIET -ne 1 ]]	  	&& echo -e "[$(date "+%Y%m%d %H:%M:%S") $1 ][${OBJECT_ID:-'no_id'}] $2"
		[[ $LOGFILE != "" ]] 	&& echo -e "[$(date "+%Y%m%d %H:%M:%S") $1 ][${OBJECT_ID:-'no_id'}] $2" >> $LOGFILE
		# [[ $QUIET -ne 1 ]]   	&& echo -e "[$(date "+%Y%m%d %H:%M:%S") $1 ][${OBJECT_ID:-'no_id'}] $2"
	else
		[[ $LOGFILE != "" ]] && echo -e "[$(date "+%Y%m%d %H:%M:%S")][${OBJECT_ID:-'no_id'}] $@" >> $LOGFILE
		[[ $QUIET -ne 1 ]]   && echo -e "[$(date "+%Y%m%d %H:%M:%S")][${OBJECT_ID:-'no_id'}] $@"
	fi
fi
