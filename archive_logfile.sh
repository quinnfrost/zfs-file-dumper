#!/bin/bash
. ./common.sh

COMPRESS="0"

if [ ! -d "$LOGARCHIVE_PATH" ]
then
	./write_log.sh "Creating log path $LOGARCHIVE_PATH"
	mkdir --parents "$LOGARCHIVE_PATH"
fi

if [ -e "$LOGFILE" ]
then
	if [[ $COMPRESS -eq 0 ]]
	then
		mv --force "$LOGFILE" "$LOGARCHIVE_PATH$(date "+%Y%m%d-%H:%M:%S")-${OBJECT_ID-'no_object_id_given'}.log" 
	else
		tar --create --file "$LOGARCHIVE_PATH$(date "+%Y%m%d-%H:%M:%S")-${OBJECT_ID-'noIDgiven'}.tar" $LOGFILE
	fi
fi
