#!/bin/bash
# Dump file by Object ID

# Only print info
DRYRUN="0"

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

[[ $LOGFILE != "" ]] && [[ $ERRORFILE != "" ]] && rm "$LOGFILE"
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
	# ./write_log.sh "File exists"
	EXIST_SIZE=$(stat --printf="%s" "$FILE_PATH$FILE_NAME")
	if [ $EXIST_SIZE -eq $SIZE ]
	then
		# ./write_log.sh "Size identical"
		SIZECORRECT="1"
	else
		./write_log.sh "Size not match($SIZE->$EXIST_SIZE)"
		SIZECORRECT="0"
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

	if [[ $EXIST_MTIME = $DUMP_MTIME ]] \
	# && [[ $EXIST_ATIME = $DUMP_ATIME ]]
	then
		# ./write_log.sh "Time identical"
		TIMECORRECT="1"
	else
		./write_log.sh "Time not match($DUMP_MTIME->$EXIST_MTIME)"
		# ./write_log.sh "Exist file a/mtime ($EXIST_ATIME) ($EXIST_MTIME)"
		# ./write_log.sh "Dump file a/mtime ($DUMP_ATIME) ($DUMP_MTIME)"
		TIMECORRECT="0"
	fi
	if [[ $SIZECORRECT = "1" ]] && [[ $TIMECORRECT = "1" ]]
	then
		./write_log.sh WARN "Identical file of $FILE_PATH$FILE_NAME found, skipping"
		exit
	else
		./write_log.sh WARN "File with same name $FILE_PATH$FILE_NAME found but different($SIZECORRECT $TIMECORRECT), removing and dump again"
		[[ $FILE_PATH$FILE_NAME != "" ]] && rm "$FILE_PATH$FILE_NAME"
	fi
fi
# Dump the file
# for i in "${OFFSETS[@]}"
INDEX=0
REGX_PSIZE=".*(\w+):(\w+):(\w+)"
VDEV=""
NEXT_OFFSET="0"
SUM_INDEX="0"
SUM_OFFSET="0"		#! Store the start of continuous block
SUM_PSIZE="0"		#! Store the size of continuous block
#! Find if any continuous block can be dump together

while [[ $INDEX -le $((OFFSET_LEN-1)) ]]
do
	# ./write_log.sh "Started to dump $INDEX/$((OFFSET_LEN-1)) at "${OFFSETS[$INDEX]}""
	# if [ $DRYRUN -ne 1 ]
	# then
	# 	$ZDB --read-block -e $POOLNAME ${OFFSETS[$INDEX]}:r >> "$FILE_PATH$FILE_NAME"
	# fi
	if [[ ${OFFSETS[$INDEX]} =~ $REGX_PSIZE ]]
	then
		VDEV=${BASH_REMATCH[1]}
		CURRENT_OFFSET=${BASH_REMATCH[2]}
		CURRENT_PSIZE=${BASH_REMATCH[3]}

		#! For SUM_OFFSET = 0 (first time or just dumped), 
		#!		update it to current offset
		[[ 0x$SUM_OFFSET -eq 0 ]] && SUM_OFFSET=$CURRENT_OFFSET && SUM_INDEX=$INDEX

		# echo ------------------------------
		# echo "Current index $INDEX, Current sum at $SUM_INDEX"
		# echo "Offset should be $NEXT_OFFSET"
		# echo "Current offset $CURRENT_OFFSET:$CURRENT_PSIZE"


		#! For NEXT_OFFSET != CURRENT_OFFSET (the block is not continuous),
		#!		dump VDEV:SUM_OFFSET:SUM_PSIZE:r
		#! 		update NEXT_OFFSET to 0
		#! 		update SUM_OFFSET to 0
		#! 		update SUM_PSIZE to 0
		if [[ 0x$NEXT_OFFSET -ne 0x${BASH_REMATCH[2]} ]] \
		&& [[ 0x$NEXT_OFFSET -ne 0x00 ]]
		then
			./write_log.sh "Started to dump incontinuous block $VDEV:$SUM_OFFSET:$SUM_PSIZE at $SUM_INDEX-$((INDEX-1)) of $((OFFSET_LEN-1)) blocks"

			[ $DRYRUN -ne 1 ] && $ZDB --read-block -e $POOLNAME $VDEV:$SUM_OFFSET:$SUM_PSIZE:r >> "$FILE_PATH$FILE_NAME"

			NEXT_OFFSET=$(printf "%X\n" $((0x$CURRENT_OFFSET + 0x$CURRENT_PSIZE)))
			SUM_OFFSET=$CURRENT_OFFSET
			SUM_PSIZE=$CURRENT_PSIZE

			SUM_INDEX=$INDEX

		#! For NEXT_OFFSET = CURRENT_OFFSET (the block is continuous or the first time), 
		#! 		update NEXT_OFFSET to current offset + psize, update SUM_PSIZE to SUM_PSIZE + CURRENT_PSIZE
		#! For NEXT_OFFSET = 0 (first time or just dumped), 
		#!		update it to current offset + psize
		else
			NEXT_OFFSET=$(printf "%X\n" $((0x$CURRENT_OFFSET + 0x$CURRENT_PSIZE)))
			SUM_PSIZE=$(printf "%X\n" $((0x$SUM_PSIZE + 0x$CURRENT_PSIZE)))
		fi

		# echo "Continuous block $SUM_OFFSET:$SUM_PSIZE"
		# echo ------------------------------
	else
		./write_log.sh WARN "Cannot parse offset:psize of $OBJECT_ID at $FILE_PATH$FILE_NAME"
		exit
	fi
	INDEX=$((INDEX+1))
done
#! If last block is continuous, it needs to be dump at last, otherwise it's already dumped
if [[ 0x$NEXT_OFFSET -ne 0 ]] \
&& [[ 0x$SUM_OFFSET -ne 0 ]] \
&& [[ 0x$SUM_PSIZE -ne 0 ]] 
then
	./write_log.sh "Started to dump last block $VDEV:$SUM_OFFSET:$SUM_PSIZE at $SUM_INDEX-$((INDEX-1)) of $((OFFSET_LEN-1)) blocks"
	[ $DRYRUN -ne 1 ] && $ZDB --read-block -e $POOLNAME $VDEV:$SUM_OFFSET:$SUM_PSIZE:r >> "$FILE_PATH$FILE_NAME"

# else
# 	./write_log.sh WARN "Offset missing or invaild"
# 	./write_log.sh WARN "Offset in question: $VDEV:$SUM_OFFSET:$SUM_PSIZE"
fi
./write_log.sh "Dumped ${FILE_PATH}${FILE_NAME}"

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
./write_log.sh "Finished $OBJECT_ID at "$FILE_PATH$FILE_NAME" in $((ELAPSED_TIME / 1000)).$((ELAPSED_TIME % 1000)) s"

# echo $FILE_NAME
# echo $FILE_PATH
# echo $ACCESS_TIME
# echo $MODIFIED_TIME
# echo $CHANGE_TIME
# echo $CREATION_TIME
# echo $SIZE
# echo $DUMP_OFFSET
# echo $SHA256SUM
