#!/bin/bash
. ./common.sh

DUMP_OBJECT_LIST="0"
DUMP_OBJECT_ID_LIST="1"

DUMP_FILENAME="plainfilelist.txt"

[[ $DUMP_OBJECT_LIST = "1" ]] && $ZDB -e -AAA -d "${POOLNAME}/${DATASET}" 0:-1:f > ${DUMP_DIR}$DUMP_FILENAME

if [[ $DUMP_OBJECT_ID_LIST = "1"]]
then
	LINE_START="4"
	LINE_INDEX=$LINE_START
	LINE_COUNT=$(wc --lines < "$DUMP_FILENAME")
	REGX_OBJECT_ID="^\s+([0-9]+).*ZFS.*"
	echo "Total lines $LINE_COUNT"
	# while IFS= read -r line; do
	#     echo "Text read from file: $line"
	# done < "$DUMP_FILENAME"
	while [[ $LINE_INDEX -le $LINE_COUNT ]]
	do
		LINE=$(sed -n ${LINE_INDEX}p $DUMP_FILENAME)
		# LINE=$(head -n $LINE file | tail -1)
		if [[ $LINE =~ $REGX_OBJECT_ID ]]
		then
			# echo ${BASH_REMATCH[0]}
			# echo ${BASH_REMATCH[1]}
			DUMP_OBJECT_LIST[$((LINE_INDEX-LINE_START))]=${BASH_REMATCH[1]}
		fi

		LINE_INDEX=$((LINE_INDEX+1))
	done
	OBJECT_COUNT=${#DUMP_OBJECT_LIST[@]}
	echo $OBJECT_COUNT
	./write_log.sh "$OBJECT_COUNT objects found, start with ${DUMP_OBJECT_LIST[0]} to ${DUMP_OBJECT_LIST[$((OBJECT_COUNT-1))]}"
fi
