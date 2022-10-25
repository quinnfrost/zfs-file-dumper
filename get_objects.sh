#!/bin/bash
. ./common.sh

FORCEDUMPID="1"

DUMP_OBJECT_LIST="0"
DUMP_OBJECT_ID_LIST="1"

DUMP_FILENAME="./plainfilelist.txt"
DUMP_OBJECT_ID_FILENAME="./objects.txt"

. ./archive_logfile.sh
[[ -e $LOGFILE ]] && rm $LOGFILE

[[ $DUMP_OBJECT_LIST = "1" ]] && $ZDB -e -AAA -d "${POOLNAME}/${DATASET}" 0:-1:f > "${DUMP_FILENAME}"

if [[ $DUMP_OBJECT_ID_LIST = "1" ]]
then
	if [[ -e $DUMP_OBJECT_ID_FILENAME ]] && [[ $FORCEDUMPID -eq 0 ]]
	then 
		. ./write_log.sh WARN "Object file exists"
		exit
	fi

	FINDID_START_TIME=$(date +%s%3N)
	. ./write_log.sh "Start to list all plain file objects"

	# Default 4
	LINE_START="4"
	LINE_INDEX=$LINE_START
	LINE_COUNT=$(wc --lines < "$DUMP_FILENAME")
	REGX_OBJECT_ID="^\s+([0-9]+).*ZFS.*"
	. ./write_log.sh "Get total lines $LINE_COUNT"
	# while IFS= read -r line; do
	#     echo "Text read from file: $line"
	# done < "$DUMP_FILENAME"
	while [[ $LINE_INDEX -le $LINE_COUNT ]]
	do
		LINE=$(sed -n ${LINE_INDEX}p $DUMP_FILENAME)
		# LINE=$(head -n $LINE file | tail -1)
		if [[ $LINE =~ $REGX_OBJECT_ID ]]
		then
			OBJECT_ID=${BASH_REMATCH[1]}
			. ./object_parser.sh $OBJECT_ID
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
				. ./write_log.sh WARN "Something is missing in $OBJECT_ID at ${FILE_PATH:-'no_path'}${FILE_NAME:-'no_name'}"
				LINE_INDEX=$((LINE_INDEX+1))
				continue
			fi
			printf '%s\n' "$OBJECT_ID				$(numfmt --to=iec-i $SIZE)				\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_OBJECT_ID_FILENAME"
			# echo ${BASH_REMATCH[0]}
			# echo ${BASH_REMATCH[1]}
			# DUMP_OBJECT_LIST[$((LINE_INDEX-LINE_START))]=${BASH_REMATCH[1]}
		fi

		if [[ $((LINE_INDEX%100)) -eq 0 ]]
		then
			FINDID_ELAPSED_TIME=$(expr $(date +%s%3N) - $FINDID_START_TIME)
			. ./write_log.sh "Processing line $LINE_INDEX/$((LINE_COUNT-LINE_START)), $(echo "scale=3; $FINDID_ELAPSED_TIME / 1000" | bc) s elapsed"
		fi
		LINE_INDEX=$((LINE_INDEX+1))
	done
	
	OBJECT_COUNT=$(wc --lines < "$DUMP_OBJECT_ID_FILENAME")
	FINDID_ELAPSED_TIME=$(expr $(date +%s%3N) - $FINDID_START_TIME)
	. ./write_log.sh "Done listing $((LINE_COUNT-LINE_START)) objects in $(echo "scale=3; $FINDID_ELAPSED_TIME/1000" | bc) s, appx. $(echo "scale=3; $FINDID_ELAPSED_TIME/$((LINE_COUNT-LINE_START))/1000" | bc) s per object"
fi
