#!/bin/bash
# Dump file by Object ID

# Only print info
DRYRUN="0"
# Dump even if file exists
FORCE="0"
NOEXCLUDE="0"
# Flags used by the zdb -R, rdv mean dump raw, decompress, and verbose on decompress
RFLAGS="r"
# Batch dd
BATCHDD="1"
STATUSDD="status=progress"

export ZDB_NO_ZLE

# ZDB="/usr/local/sbin/zdb"
# DUMP_DIR="."
# POOLNAME="hdd-1T"
# DATASET="smbfiles"
. ./common.sh

OBJECT_ID=$1
SKIP="0"
FILE_NAME=""
FILE_PATH=""
SIZE=""
ACCESS_TIME=""
MODIFIED_TIME=""
CHANGE_TIME=""
CREATION_TIME=""
OFFSETS=""
OFFSET_LEN=""

# if [[ $LOGFILE != "" ]] || [[ $ERRORFILE != "" ]] 
# then
# 	. ./archive_logfile.sh $OBJECT_ID
# 	# rm "$LOGFILE" # && rm "$ERRORFILE"
# fi
# OBJECT_INFO=$($ZDB -e -AAA -ddddd "${POOLNAME}${DATASET}" $OBJECT_ID)
#! Parse object info
. ./object_parser.sh $OBJECT_ID
FILE_PATH="${DUMP_DIR}${FILE_PATH}"
#! Determine if the object is going to skipped
if [[ $DRYRUN -ne 1 ]]
then
	if [[ $FILE_NAME = "" ]] \
	|| [[ $FILE_PATH = "" ]] \
	|| [[ $ACCESS_TIME = "" ]] \
	|| [[ $MODIFIED_TIME = "" ]] \
	|| [[ $CHANGE_TIME = "" ]] \
	|| [[ $CREATION_TIME = "" ]] \
	|| [[ $SIZE = "" ]] \
	|| [[ $OFFSET_LEN -eq 0 ]] \
	|| [[ ${#OFFSETS[@]} -ne ${#INFILE_OFFSETS[@]} ]]
	then
		if [[ $DUMP_OFFSET =~ .*EMBEDDED.* ]]
		then
			. ./write_log.sh WARN "Embedded file \"${FILE_PATH}${FILE_NAME}\" found at $OBJECT_ID, skipping"
			printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_EMBEDDED_FILENAME"
		elif [[ $SIZE -eq 0 ]]
		then
			. ./write_log.sh WARN "Zero sized file \"${FILE_PATH}${FILE_NAME}\" found at $OBJECT_ID, skipping"
			printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_ZEROED_FILENAME"
		else
			. ./write_log.sh WARN "Something is missing in $OBJECT_ID at \"${FILE_PATH:-'no_path'}${FILE_NAME:-'no_name'}\", skipping"
		fi
		SKIP="1"
	fi

	if [[ $NOEXCLUDE != "1" ]]
	then
		declare -a REGX_EX_PATH=(".*/.recycle/.*")
		for ITEM in "${REGX_EX_PATH[@]}"
		do
			if [[ "$FILE_PATH" =~ $ITEM ]]
			then
				. ./write_log.sh WARN "Object file \"$FILE_PATH$FILE_NAME\" match exclude rule $ITEM, skipping"
				SKIP="1"
			fi
		done
	fi
fi

#! Get path ready for dump
if [ ! -d "$FILE_PATH" ] \
&& [[ $SKIP -ne 1 ]]
then
	. ./write_log.sh "Creating path $FILE_PATH"
	[[ $DRYRUN -ne 1 ]] && mkdir --parents "$FILE_PATH"
fi
#! Check if file exists. If so, check time and size to determine if it needs to dump again.
if [ -e "$FILE_PATH$FILE_NAME" ] \
&& [[ $SKIP -ne 1 ]]
then
	# . ./write_log.sh "File exists"
	EXIST_SIZE=$(stat --printf="%s" "$FILE_PATH$FILE_NAME")
	if [ $EXIST_SIZE -eq $SIZE ]
	then
		# . ./write_log.sh "Size identical"
		SIZECORRECT="1"
	else
		. ./write_log.sh "Size not match($SIZE->$EXIST_SIZE)"
		SIZECORRECT="0"
	fi

	TIME_FORMAT="%Y%m%d %H:%M:%S"
	EXIST_ATIME=$(stat --format="%x" "$FILE_PATH$FILE_NAME")
	EXIST_ATIME=$(date +"$TIME_FORMAT" --date="$EXIST_ATIME")
	DUMP_ATIME=$(date +"$TIME_FORMAT" --date="$ACCESS_TIME")
	# . ./write_log.sh $EXIST_ATIME
	# . ./write_log.sh $DUMP_ATIME

	EXIST_MTIME=$(stat --format="%y" "$FILE_PATH$FILE_NAME")
	EXIST_MTIME=$(date +"$TIME_FORMAT" --date="$EXIST_MTIME")
	DUMP_MTIME=$(date +"$TIME_FORMAT" --date="$MODIFIED_TIME")
	# . ./write_log.sh $EXIST_MTIME
	# . ./write_log.sh $DUMP_MTIME

	if [[ $EXIST_MTIME = $DUMP_MTIME ]] \
	# && [[ $EXIST_ATIME = $DUMP_ATIME ]]
	then
		# . ./write_log.sh "Time identical"
		TIMECORRECT="1"
	else
		. ./write_log.sh "Time not match($DUMP_MTIME->$EXIST_MTIME)"
		# . ./write_log.sh "Exist file a/mtime ($EXIST_ATIME) ($EXIST_MTIME)"
		# . ./write_log.sh "Dump file a/mtime ($DUMP_ATIME) ($DUMP_MTIME)"
		TIMECORRECT="0"
	fi
	if [[ $SIZECORRECT = "1" ]] && [[ $TIMECORRECT = "1" ]] && [[ ! $FORCE -ne 0 ]]
	then
		. ./write_log.sh WARN "Identical file of $FILE_PATH$FILE_NAME found, skipping"
		[ $DRYRUN -ne 1 ] && SKIP="1"
	else
		[[ $FORCE -eq 0 ]] && . ./write_log.sh WARN "File with same name $FILE_PATH$FILE_NAME found but different($SIZECORRECT $TIMECORRECT), removing and dump again"
		[[ $FORCE -eq 1 ]] && . ./write_log.sh WARN "File with same name $FILE_PATH$FILE_NAME found but force flag is set($FORCE), removing and dump again"
		[[ $FILE_PATH$FILE_NAME != "" ]] && rm "$FILE_PATH$FILE_NAME"
		[[ $? -ne 0 ]] && . ./write_log.sh WARN "Failed to remove exist file" && exit
	fi
fi

if [[ $SKIP -ne 1 ]]
then
#! Dump the file
DUMP_START_TIME=$(date +%s%3N)

INDEX=0
# REGX_PSIZE=".*(\w+):(\w+):(\w+)"
REGX_PSIZE=".*(\w+):(\w+):(\w+)\/(\w+)"
VDEV=""
NEXT_OFFSET="0"
NEXT_INFILE_OFFSET="0"
SUM_INDEX="0"
SUM_OFFSET="0"		#! Store the start of continuous block
SUM_PSIZE="0"		#! Store the size of continuous block
SUM_LSIZE="0"
SUM_INFILE_OFFSET="0"
SUM_INFILE_LSIZE="0"

# Check if temp file name is taken
TEMP_FILENAME="dump${RANDOM}.tmp"
if [ -e "$FILE_PATH$TEMP_FILENAME" ] \
|| [[ $FILE_PATH$TEMP_FILENAME = "" ]]
then
	. ./write_log.sh WARN "Temp file conflict"
	exit
	# rm "$FILE_PATH$TEMP_FILENAME"
	# [[ $? -ne 0 ]] && . ./write_log.sh WARN "No temp file removed"
fi

#! Find if any continuous block can be dump together
while [[ $INDEX -le $((OFFSET_LEN-1)) ]]
do
	# . ./write_log.sh "Started to dump $INDEX/$((OFFSET_LEN-1)) at "${OFFSETS[$INDEX]}""
	# if [ $DRYRUN -ne 1 ]
	# then
	# 	$ZDB --read-block -e $POOLNAME ${OFFSETS[$INDEX]}:r >> "$FILE_PATH$FILE_NAME"
	# fi
	if [[ ${OFFSETS[$INDEX]} =~ $REGX_PSIZE ]]
	then
		VDEV=${BASH_REMATCH[1]}
		CURRENT_OFFSET=${BASH_REMATCH[2]}
		CURRENT_LSIZE=${BASH_REMATCH[3]}
		CURRENT_PSIZE=${BASH_REMATCH[4]}

		# echo "${INFILE_OFFSETS[$INDEX]}"
		# echo "$SUM_INFILE_OFFSET"
		# echo "$INDEX"

		# echo ${BASH_REMATCH[@]}

		#! For SUM_OFFSET = 0 (first time or just dumped), 
		#!		update it to current offset
		[[ 0x$SUM_OFFSET -eq 0 ]] && SUM_OFFSET=$CURRENT_OFFSET && SUM_INDEX=$INDEX

		# echo ------------------------------
		# echo "Current index $INDEX, Current sum at $SUM_INDEX"
		# echo "Offset should be $NEXT_OFFSET"
		# echo "Infile offset should be $NEXT_INFILE_OFFSET"
		# echo "Current offset ${INFILE_OFFSETS[$INDEX]} $CURRENT_OFFSET:$CURRENT_LSIZE/$CURRENT_PSIZE"


		#! For	NEXT_OFFSET != CURRENT_OFFSET (the block is not continuous),
		#!		SUM_PSIZE >= 0x1000000(16,777,217) (Keep dump size smaller than SPA_MAXBLOCKSIZE, otherwise a ASSERT check 
		#!			at module/zfs/zio.c:811:zio_create() "(type != ZIO_TYPE_TRIM) implies (psize <= SPA_MAXBLOCKSIZE)"
		#!			will fail)
		#!		CURRENT_LINE != CURRENT_PSIZE (this block is compressed)
		#!		dump VDEV:SUM_OFFSET:SUM_PSIZE
		#! 		update NEXT_OFFSET to 0
		#! 		update SUM_OFFSET to 0
		#! 		update SUM_PSIZE to 0
		if ([[ 0x$NEXT_OFFSET -ne 0x${BASH_REMATCH[2]} ]] \
		&& [[ 0x$NEXT_OFFSET -ne 0x00 ]]) \
		|| [[ 0x$SUM_PSIZE -ge 0x1000000 ]] \
		|| [[ 0x$CURRENT_LSIZE -ne 0x$CURRENT_PSIZE ]]
		then
			if [[ 0x$SUM_PSIZE -ne 0x00 ]] # If the first block is a compressed block, there is nothing to dump, so don't
			then
				if [[ 0x$SUM_LSIZE -eq 0x$SUM_PSIZE ]]
				then
					RFLAGS="r"
					. ./write_log.sh "Started to dump block $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS at $SUM_INDEX-$((INDEX-1))($((INDEX-SUM_INDEX))) of $((OFFSET_LEN-1)) blocks"
					[[ $DRYRUN -ne 1 ]] && $ZDB --read-block -e $POOLNAME $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS 1>> "${FILE_PATH}${TEMP_FILENAME}" 2> >(sed -e '/^Found vdev/,/^lz4/d' >> ./stderrout.log)
				else
					RFLAGS="rdv"
					. ./write_log.sh "Started to dump compressed block $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS at $SUM_INDEX-$((INDEX-1))($((INDEX-SUM_INDEX))) of $((OFFSET_LEN-1)) blocks"
					[[ $DRYRUN -ne 1 ]] && $ZDB --read-block -e $POOLNAME $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS 1>> "${FILE_PATH}${TEMP_FILENAME}" 2> >(sed -e '/^Found vdev/,/^lz4/d' >> ./stderrout.log)
				fi
			fi
			# Todo: 下面这部分可以考虑挪到大判断之外
			if [[ 0x$NEXT_INFILE_OFFSET -ne 0x${INFILE_OFFSETS[$INDEX]} ]] || [[ $BATCHDD -ne 1 ]]
			then
				# For the first segment of the file
				if [[ -e "$FILE_PATH$FILE_NAME" ]]
				then
					DD_START_TIME=$(date +%s%3N)
					. ./write_log.sh "Writing $SUM_INFILE_LSIZE bytes into $(printf "%d\n" 0x$SUM_INFILE_OFFSET)($SUM_INFILE_OFFSET)"
					# [[ $DRYRUN -ne 1 ]] && dd if="${FILE_PATH}${TEMP_FILENAME}" of="$FILE_PATH$FILE_NAME" bs=1 seek=$(printf "%d\n" 0x$SUM_INFILE_OFFSET) count=$(printf "%d\n" 0x$SUM_INFILE_LSIZE) conv=notrunc $STATUSDD
					[[ $DRYRUN -ne 1 ]] && dd if="${FILE_PATH}${TEMP_FILENAME}" of="$FILE_PATH$FILE_NAME" seek=$(printf "%d\n" 0x$SUM_INFILE_OFFSET) conv=notrunc $STATUSDD
					[[ $? -ne 0 ]] && . ./write_log.sh WARN "Failed to write file" && exit	
					DD_ELAPSED_TIME=$(expr $(date +%s%3N) - $DD_START_TIME)
					. ./write_log.sh "Written $SUM_INFILE_LSIZE bytes into $(printf "%d\n" 0x$SUM_INFILE_OFFSET)($SUM_INFILE_OFFSET) in $(echo "scale=3; $DD_ELAPSED_TIME / 1000" | bc) s"
				else
					. ./write_log.sh "File ${FILE_PATH}${FILE_NAME} not yet exist, renaming temp file"
					[[ $DRYRUN -ne 1 ]] && mv "${FILE_PATH}${TEMP_FILENAME}" "${FILE_PATH}${FILE_NAME}"
					[[ $? -ne 0 ]] && . ./write_log.sh WARN "Failed to rename temp file" && exit
				fi
				[[ $DRYRUN -ne 1 ]] && :> "$FILE_PATH$TEMP_FILENAME" 

				SUM_INFILE_OFFSET=${INFILE_OFFSETS[$INDEX]}
				SUM_INFILE_LSIZE=$CURRENT_LSIZE
			else
				SUM_INFILE_LSIZE=$(printf "%X\n" $((0x$SUM_INFILE_LSIZE + 0x$CURRENT_LSIZE)))	
			fi

			SUM_OFFSET=$CURRENT_OFFSET
			SUM_PSIZE=$CURRENT_PSIZE
			SUM_LSIZE=$CURRENT_LSIZE

			SUM_INDEX=$INDEX

		#! For NEXT_OFFSET = CURRENT_OFFSET (the block is continuous or the first time), 
		#! 		update NEXT_OFFSET to current offset + psize, update SUM_PSIZE to SUM_PSIZE + CURRENT_PSIZE
		#! For NEXT_OFFSET = 0 (first time or just dumped), 
		#!		update it to current offset + psize
		else
			SUM_PSIZE=$(printf "%X\n" $((0x$SUM_PSIZE + 0x$CURRENT_PSIZE)))
			SUM_LSIZE=$(printf "%X\n" $((0x$SUM_LSIZE + 0x$CURRENT_LSIZE)))
			SUM_INFILE_LSIZE=$(printf "%X\n" $((0x$SUM_INFILE_LSIZE + 0x$CURRENT_LSIZE)))	
		fi

		NEXT_OFFSET=$(printf "%X\n" $((0x$CURRENT_OFFSET + 0x$CURRENT_PSIZE)))
		NEXT_INFILE_OFFSET=$(printf "%X\n" $((0x${INFILE_OFFSETS[$INDEX]} + 0x$CURRENT_LSIZE)))

		# echo "Continuous block $SUM_OFFSET:$SUM_PSIZE"
		# echo "Continuous infile block $SUM_INFILE_OFFSET:$SUM_LSIZE"
		# echo ------------------------------
	else
		. ./write_log.sh WARN "Cannot parse offset:lsize/psize of $OBJECT_ID at $FILE_PATH$FILE_NAME"
		exit
	fi
	INDEX=$((INDEX+1))
	# [[ $INDEX -eq 10 ]] && exit
done
#! If last block is continuous, it needs to be dump at last, otherwise it's already dumped
if [[ 0x$NEXT_OFFSET -ne 0 ]] \
&& [[ 0x$SUM_OFFSET -ne 0 ]] \
&& [[ 0x$SUM_PSIZE -ne 0 ]] 
then
	if [[ 0x$SUM_LSIZE -eq 0x$SUM_PSIZE ]]
	then
		RFLAGS="r"
		. ./write_log.sh "Started to dump last block $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS at $SUM_INDEX-$((INDEX-1))($((INDEX-SUM_INDEX))) of $((OFFSET_LEN-1)) blocks"
		[[ $DRYRUN -ne 1 ]] && $ZDB --read-block -e $POOLNAME $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS >> "${FILE_PATH}${TEMP_FILENAME}" 2> >(sed -e '/^Found vdev/,/^lz4/d' >>./stderrout.log)
	else
		RFLAGS="rdv"
		. ./write_log.sh "Started to dump last compressed block $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS at $SUM_INDEX-$((INDEX-1))($((INDEX-SUM_INDEX))) of $((OFFSET_LEN-1)) blocks"
		[[ $DRYRUN -ne 1 ]] && $ZDB --read-block -e $POOLNAME $VDEV:$SUM_OFFSET:$SUM_LSIZE/$SUM_PSIZE:$RFLAGS >> "${FILE_PATH}${TEMP_FILENAME}" 2> >(sed -e '/^Found vdev/,/^lz4/d' >> ./stderrout.log)
	fi

	if [[ -e "$FILE_PATH$FILE_NAME" ]]
	then
		DD_START_TIME=$(date +%s%3N)
		. ./write_log.sh "Writing $SUM_INFILE_LSIZE bytes into $(printf "%d\n" 0x$SUM_INFILE_OFFSET)($SUM_INFILE_OFFSET)"
		[[ $DRYRUN -ne 1 ]] && dd if="${FILE_PATH}${TEMP_FILENAME}" of="$FILE_PATH$FILE_NAME" seek=$(printf "%d\n" 0x$SUM_INFILE_OFFSET) count=$(printf "%d\n" 0x$SUM_INFILE_LSIZE) conv=notrunc $STATUSDD
		[[ $? -ne 0 ]] && . ./write_log.sh WARN "Failed to write file" && exit		
		DD_ELAPSED_TIME=$(expr $(date +%s%3N) - $DD_START_TIME)
		. ./write_log.sh "Written $SUM_INFILE_LSIZE bytes into $(printf "%d\n" 0x$SUM_INFILE_OFFSET)($SUM_INFILE_OFFSET) in $(echo "scale=3; $DD_ELAPSED_TIME / 1000" | bc) s"
	else
		. ./write_log.sh "File ${FILE_PATH}${FILE_NAME} not yet exist, renaming temp file"
		[[ $DRYRUN -ne 1 ]] && mv "${FILE_PATH}${TEMP_FILENAME}" "${FILE_PATH}${FILE_NAME}"
		[[ $? -ne 0 ]] && . ./write_log.sh WARN "Failed to rename temp file" && exit
	fi


# else
# 	. ./write_log.sh WARN "Offset missing or invaild"
# 	. ./write_log.sh WARN "Offset in question: $VDEV:$SUM_OFFSET:$SUM_PSIZE"
fi
# Remove temp file
if [ -e "$FILE_PATH$TEMP_FILENAME" ]
then
	. ./write_log.sh "Removing $FILE_PATH$TEMP_FILENAME"
	rm "$FILE_PATH$TEMP_FILENAME"
	[[ $? -ne 0 ]] && . ./write_log.sh WARN "Failed to remove temp file"
fi

DUMP_ELAPSED_TIME=$(expr $(date +%s%3N) - $DUMP_START_TIME)
. ./write_log.sh "Finished dumping $OBJECT_ID at \"$FILE_PATH$FILE_NAME\" in $(echo "scale=3; $DUMP_ELAPSED_TIME / 1000" | bc) s \
(appx. $(echo "scale=3; $DUMP_ELAPSED_TIME / $OFFSET_LEN / 1000" | bc) s per block)"
#! Dump end

# Cut the file to its actual size
if [ $DRYRUN -ne 1 ]
then
	# DUMP_FILESIZE=$(du -k "$FILE_PATH$FILE_NAME" | cut -f1)
	DUMP_FILESIZE=$(stat --printf="%s" "$FILE_PATH$FILE_NAME")
	if [[ $SIZE -gt $DUMP_FILESIZE ]]
	then
		. ./write_log.sh WARN "Dumped file at $FILE_PATH$FILE_NAME is smaller than it should be($DUMP_FILESIZE->$SIZE), skipped truncate"
	else
		truncate --size=$SIZE "$FILE_PATH$FILE_NAME"
		if [[ $? -eq 0 ]]
		then
			. ./write_log.sh "Truncated file with size ${SIZE}"
		else
			. ./write_log.sh WARN "Truncate failed"
		fi
	fi
else
	. ./write_log.sh "Truncate file with size ${SIZE}"
fi

# Update file timestamp
if [ $DRYRUN -ne 1 ]
then
	touch --no-create --date="${ACCESS_TIME}" --time=atime "$FILE_PATH$FILE_NAME"
	touch --no-create --date="${MODIFIED_TIME}" --time=mtime "$FILE_PATH$FILE_NAME"
fi
. ./write_log.sh "Updated file access time ($ACCESS_TIME) and modified time ($MODIFIED_TIME)"

# echo $FILE_NAME
# echo $FILE_PATH
# echo $ACCESS_TIME
# echo $MODIFIED_TIME
# echo $CHANGE_TIME
# echo $CREATION_TIME
# echo $SIZE
# echo $DUMP_OFFSET
# echo $SHA256SUM
printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_OBJECT_ID_FILENAME"
. ./write_log.sh "Finished $OBJECT_ID at \"$FILE_PATH$FILE_NAME\""
else
printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$SKIP_LOG"
fi # Dump process is skiped
