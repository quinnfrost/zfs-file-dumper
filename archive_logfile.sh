#!/bin/bash
. ./common.sh

COMPRESS="0"

if [[ $1 != "" ]]
then
	CURRENT_ID=${1-'no_id'}
else
	CURRENT_ID=${OBJECT_ID-'no_id'}
fi

if [ ! -d "$LOGARCHIVE_PATH" ]
then
	./write_log.sh "Creating log path $LOGARCHIVE_PATH"
	mkdir --parents "$LOGARCHIVE_PATH"
fi

if [ -e "$LOGFILE" ]
then
	if [[ $COMPRESS -eq 0 ]]
	then
		mv --force "$LOGFILE" "$LOGARCHIVE_PATH$(date "+%Y%m%d-%H:%M:%S")-$CURRENT_ID.log" 
	else
		tar --create --file "$LOGARCHIVE_PATH$(date "+%Y%m%d-%H:%M:%S")-$CURRENT_ID.tar" "$LOGFILE"
		rm "$LOGFILE"
	fi
fi
