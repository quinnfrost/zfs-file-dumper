#!/bin/bash
# Dump file by Object ID

# Only print info
DRYRUN="1"

# ZDB="/usr/local/sbin/zdb"
# DUMP_DIR="."
# POOLNAME="hdd-1T"
# DATASET="smbfiles"
. ./common.sh

OBJECT_ID=${1-'227078'}
FILE_NAME=""
FILE_PATH=""
SIZE=""
ACCESS_TIME=""
MODIFIED_TIME=""
CHANGE_TIME=""
CREATION_TIME=""
OFFSETS=""
OFFSET_LEN=""

START_TIME=$(date +%s%3N)

[[ $LOGFILE != "" ]] && [[ $ERRORFILE != "" ]] && rm $LOGFILE
./write_log.sh "Start processing ${OBJECT_ID}"
# OBJECT_INFO=$($ZDB -e -AAA -ddddd "${POOLNAME}${DATASET}" $OBJECT_ID)
# Parse object info
. ./object_parser.sh $OBJECT_ID
FILE_PATH="${DUMP_DIR}${FILE_PATH}"
# Get path ready for dump
if [ ! -d "$FILE_PATH" ]
then
	./write_log.sh "Creating path $FILE_PATH"
	[ $DRYRUN -ne 1 ] && mkdir --parents "$FILE_PATH"
fi
# Check if file exists. If so, check time and size to determine if it needs to dump again.
if [ -e "$FILE_PATH$FILE_NAME" ]
then
	./write_log.sh "File exists"
	EXIST_SIZE=$(stat --printf="%s" "$FILE_PATH$FILE_NAME")
	if [ $EXIST_SIZE -eq $SIZE ]
	then
		./write_log.sh "Size identical"
		SIZECORRECT="1"
	else
		./write_log.sh "Size not match"
	fi

	TIME_FORMAT="%Y%m%d %H:%M:%S"
	EXIST_ATIME=$(stat --format="%x" "$FILE_PATH$FILE_NAME")
	EXIST_ATIME=$(date +"$TIME_FORMAT" --date="$EXIST_ATIME")
	DUMP_ATIME=$(date +"$TIME_FORMAT" --date="$ACCESS_TIME")
	# ./write_log.sh $EXIST_ATIME
	# ./write_log.sh $DUMP_ATIME

	EXIST_MTIME=$(stat --format="%y" "$FILE_PATH$FILE_NAME")
	EXIST_MTIME=$(date +"$TIME_FORMAT" --date="$EXIST_MTIME")
	DUMP_MTIME=$(date +"$TIME_FORMAT" --date="$MODIFIED_TIME")
	# ./write_log.sh $EXIST_MTIME
	# ./write_log.sh $DUMP_MTIME

	if [[ $EXIST_ATIME = $DUMP_ATIME ]] \
	&& [[ $EXIST_MTIME = $DUMP_MTIME ]]
	then
		./write_log.sh "Time identical"
		TIMECORRECT="1"
	else
		./write_log.sh "Time not match"
	fi
	[[ $SIZECORRECT = "1" ]] && [[ $TIMECORRECT = "1" ]] && \
	./write_log.sh WARN "Identical file of $FILE_PATH$FILE_NAME found, skipping" ; return 0
fi
# Dump the file
# for i in "${OFFSETS[@]}"
INDEX=0
REGX_PSIZE=".*(\w+):(\w+):(\w+)"
VDEV=""
SUM_OFFSET=""
SUM_PSIZE="0"
while [[ $INDEX -le $((OFFSET_LEN-1)) ]]
do
	# ./write_log.sh "Started to dump $INDEX/$((OFFSET_LEN-1)) at "${OFFSETS[$INDEX]}""
	# if [ $DRYRUN -ne 1 ]
	# then
	# 	$ZDB --read-block -e $POOLNAME ${OFFSETS[$INDEX]}:r >> "$FILE_PATH$FILE_NAME"
	# fi
	if [[ ${OFFSETS[$INDEX]} =~ $REGX_PSIZE ]]
	then
		# Todos: 验证block是连续的
		SUM_PSIZE=$(printf "%X\n" $((0x$SUM_PSIZE + 0x${BASH_REMATCH[3]})))
	else
		./write_log.sh WARN "Cannot parse offset:psize of $OBJECT_ID at $FILE_PATH$FILE_NAME"
		exit
	fi
	INDEX=$((INDEX+1))
done
VDEV=${BASH_REMATCH[1]}
SUM_OFFSET=${BASH_REMATCH[2]}
if [[ $VDEV != "" ]] \
&& [[ $SUM_OFFSET != "" ]] \
&& [[ $SUM_PSIZE != "" ]] \
&& [[ $SUM_PSIZE -gt 0 ]]
then
	./write_log.sh "Started to dump $VDEV:$SUM_OFFSET:$SUM_PSIZE with $OFFSET_LEN of blocks"
	[ $DRYRUN -ne 1 ] && $ZDB --read-block -e $VDEV:$SUM_OFFSET:$SUM_PSIZE:r >> "$FILE_PATH$FILE_NAME"
	./write_log.sh "Dumped ${FILE_PATH}${FILE_NAME}"
else
	./write_log.sh WARN "Offset missing or invaild"
	./write_log.sh WARN "Offset in question: $VDEV:$SUM_OFFSET:$SUM_PSIZE"
fi

# Cut the file to its actual size
if [ $DRYRUN -ne 1 ]
then
	truncate --size=$SIZE "$FILE_PATH$FILE_NAME"
fi
./write_log.sh "Truncated file with size ${SIZE}"
# Update file timestamp
if [ $DRYRUN -ne 1 ]
then
	touch --no-create --date="${ACCESS_TIME}" --time=atime "$FILE_PATH$FILE_NAME"
	touch --no-create --date="${MODIFIED_TIME}" --time=mtime "$FILE_PATH$FILE_NAME"
fi
./write_log.sh "Updated file access time ($ACCESS_TIME) and modified time ($MODIFIED_TIME)"

ELAPSED_TIME=$(expr $(date +%s%3N) - $START_TIME)
./write_log.sh "Finished $OBJECT_ID at "$FILE_PATH$FILE_NAME" in $ELAPSED_TIME ms"

# echo $FILE_NAME
# echo $FILE_PATH
# echo $ACCESS_TIME
# echo $MODIFIED_TIME
# echo $CHANGE_TIME
# echo $CREATION_TIME
# echo $SIZE
# echo $DUMP_OFFSET
# echo $SHA256SUM
