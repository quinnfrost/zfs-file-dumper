#!/bin/bash
# Dump file by Object ID
# Todos: 用正则表达式拿OBJECT_ID和其他内容

# Only print info
DRYRUN="1"

ZDB="/usr/local/sbin/zdb"
DUMP_DIR="."
POOLNAME="hdd-1T"
DATASET="smbfiles"

OBJECT_ID=${1-'227078'}
FILE_NAME=""
FILE_PATH=""
SIZE=""
ACCESS_TIME=""
MODIFIED_TIME=""
CHANGE_TIME=""
CREATION_TIME=""
DUMP_OFFSET=""

START_TIME=$(date +%s%3N)

./write_log.sh "Start processing ${OBJECT_ID}"
OBJECT_INFO=$($ZDB -e -AAA -ddddd "${POOLNAME}/${DATASET}" $OBJECT_ID)
# Parse object info
. ./object_parser.sh
FILE_PATH=${DUMP_DIR}${FILE_PATH}
# Get path ready for dump
if [ ! -d $FILE_PATH ]
then
	./write_log.sh "Creating path $FILE_PATH"
	[ $DRYRUN -ne 1 ] && mkdir --parents $FILE_PATH
fi
# Check if file exists. If so, check time and size to determine if it needs to dump again.
if [ -e $FILE_PATH/$FILE_NAME ]
then
	./write_log.sh "File exists"
	EXIST_SIZE=$(stat --printf="%s" $FILE_PATH/$FILE_NAME)
	if [ $EXIST_SIZE -eq $SIZE ]
	then
		./write_log.sh "Size identical"
	else
		./write_log.sh "Size not match"
	fi

	TIME_FORMAT="%d%b%y:%H:%M:%S"
	EXIST_ATIME=$(stat --format="%x" $FILE_PATH/$FILE_NAME)
	EXIST_ATIME=$(date +"$TIME_FORMAT" --date="$EXIST_ATIME")
	DUMP_ATIME=$(date +"$TIME_FORMAT" --date="$ACCESS_TIME")
	./write_log.sh $EXIST_ATIME
	./write_log.sh $DUMP_ATIME

	EXIST_MTIME=$(stat --format="%y" $FILE_PATH/$FILE_NAME)
	EXIST_MTIME=$(date +"$TIME_FORMAT" --date="$EXIST_MTIME")
	DUMP_MTIME=$(date +"$TIME_FORMAT" --date="$MODIFIED_TIME")
	./write_log.sh $EXIST_MTIME
	./write_log.sh $DUMP_MTIME

	if [[ $EXIST_ATIME == $ACCESS_TIME ]] \
	&& [[ $EXIST_MTIME == $MODIFIED_TIME ]]
	then
		./write_log.sh "Time identical"
	else
		./write_log.sh "Time not match"
	fi
fi
# Dump the file
./write_log.sh "Started to dump at $DUMP_OFFSET"
if [ $DRYRUN -ne 1 ]
then
	$ZDB --read-block -e $POOLNAME ${DUMP_OFFSET}:r > $FILE_PATH/$FILE_NAME
fi
./write_log.sh "Dumped ${FILE_PATH}/${FILE_NAME}"
# Cut the file to its actual size
if [ $DRYRUN -ne 1 ]
then
	truncate --size=$SIZE $FILE_PATH/$FILE_NAME
fi
./write_log.sh "Truncated file with size ${SIZE}"
# Update file timestamp
if [ $DRYRUN -ne 1 ]
then
	touch --no-create --date="${ACCESS_TIME}" --time=atime $FILE_PATH/$FILE_NAME
	touch --no-create --date="${MODIFIED_TIME}" --time=mtime $FILE_PATH/$FILE_NAME
fi
./write_log.sh "Updated file access time ($ACCESS_TIME) and modified time ($MODIFIED_TIME)"

ELAPSED_TIME=$(expr $(date +%s%3N) - $START_TIME)
./write_log.sh "Finished $OBJECT_ID at $FILE_PATH/$FILE_NAME in $ELAPSED_TIME ms"

# echo $FILE_NAME
# echo $FILE_PATH
# echo $ACCESS_TIME
# echo $MODIFIED_TIME
# echo $CHANGE_TIME
# echo $CREATION_TIME
# echo $SIZE
# echo $DUMP_OFFSET
# echo $SHA256SUM
