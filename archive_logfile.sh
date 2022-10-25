#!/bin/bash
. ./common.sh

if [ ! -d "$LOGARCHIVE_PATH" ]
then
	./write_log.sh "Creating log path $LOGARCHIVE_PATH"
	mkdir --parents "$LOGARCHIVE_PATH"
fi

if [ -e "$ERRORFILE" ]
then
	tar --create --file "$LOGARCHIVE_PATH$(date "+%Y%m%d-%H:%M:%S")-${OBJECT_ID-'noIDgiven'}.tar" $ERRORFILE
fi
