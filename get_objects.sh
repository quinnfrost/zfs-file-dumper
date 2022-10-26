#!/bin/bash
. ./common.sh

FORCEDUMPID="1"

DUMP_OBJECT_LIST="0"
DUMP_OBJECT_ID_LIST="1"
DUMP_OBJECT_FILE="0"

DUMP_FILENAME="./plainfiledump.txt"
DUMP_OBJECT_ID_FILENAME="./objects.txt"
DUMP_EMBEDDED_FILENAME="./embedded_objects.txt"
DUMP_ZEROED_FILENAME="./zero_sized_objects.txt"

. ./archive_logfile.sh
# [[ -e $LOGFILE ]] && rm $LOGFILE

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

	# Default 3
	LAST_DIVIDE_LINE="144810"
	LINE_START=$((LAST_DIVIDE_LINE+1))
	LINE_INDEX=$LINE_START
	LINE_COUNT=$(wc --lines < "$DUMP_FILENAME")
	# REGX_OBJECT_ID="^\s+([0-9]+).*ZFS.*"
	REGX_DIVIDE="^\s+Object\s+"
	. ./write_log.sh "Get total lines $LINE_COUNT"
	# while IFS= read -r line; do
	#     echo "Text read from file: $line"
	# done < "$DUMP_FILENAME"
	while [[ $LINE_INDEX -le $LINE_COUNT ]]
	do
		LINE=$(sed -n ${LINE_INDEX}p $DUMP_FILENAME)
		echo "Looking $LINE_INDEX"
		# LINE=$(head -n $LINE file | tail -1)
		if [[ $LINE =~ $REGX_DIVIDE ]]
		then
			OBJECT_INFO=$(sed -n $LAST_DIVIDE_LINE,$((LINE_INDEX-1))p $DUMP_FILENAME)
			echo "$OBJECT_INFO"
			LAST_DIVIDE_LINE=$LINE_INDEX
			. ./object_parser.sh

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
					. ./write_log.sh WARN "Embedded file \"${FILE_PATH}${FILE_NAME}\" found at $OBJECT_ID"
					printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_EMBEDDED_FILENAME"
				elif [[ $SIZE -eq 0 ]]
				then
					. ./write_log.sh WARN "Zero sized file \"${FILE_PATH}${FILE_NAME}\" found at $OBJECT_ID"
					printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_ZEROED_FILENAME"
				else
					. ./write_log.sh WARN "Something is missing in $OBJECT_ID at \"${FILE_PATH:-'no_path'}${FILE_NAME:-'no_name'}\""
				fi
				LINE_INDEX=$((LINE_INDEX+1))
				continue
			fi
			printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_OBJECT_ID_FILENAME"
			. ./write_log.sh "Parsed $LAST_DIVIDE_LINE to $((LINE_INDEX-1))"
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

	OBJECT_INFO=$(sed -n $LAST_DIVIDE_LINE,$((LINE_INDEX-1))p $DUMP_FILENAME)
	LAST_DIVIDE_LINE=$LINE_INDEX
	. ./object_parser.sh

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
			. ./write_log.sh WARN "Embedded file \"${FILE_PATH}${FILE_NAME}\" found at $OBJECT_ID"
			printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_EMBEDDED_FILENAME"
		elif [[ $SIZE -eq 0 ]]
		then
			. ./write_log.sh WARN "Zero sized file \"${FILE_PATH}${FILE_NAME}\" found at $OBJECT_ID"
			printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_ZEROED_FILENAME"
		else
			. ./write_log.sh WARN "Something is missing in $OBJECT_ID at \"${FILE_PATH:-'no_path'}${FILE_NAME:-'no_name'}\""
		fi
		LINE_INDEX=$((LINE_INDEX+1))
		continue
	fi
	printf '%-14s%-12s%s\n' "$OBJECT_ID" "$(numfmt --to=iec-i $SIZE)" "\"${FILE_PATH}${FILE_NAME}\"" >> "$DUMP_OBJECT_ID_FILENAME"
	
	OBJECT_COUNT=$(wc --lines < "$DUMP_OBJECT_ID_FILENAME")
	FINDID_ELAPSED_TIME=$(expr $(date +%s%3N) - $FINDID_START_TIME)
	. ./write_log.sh "Done listing $((LINE_COUNT-LINE_START)) objects in $(echo "scale=3; $FINDID_ELAPSED_TIME/1000" | bc) s, appx. $(echo "scale=3; $FINDID_ELAPSED_TIME/$((LINE_COUNT-LINE_START))/1000" | bc) s per object"
	exit
fi

if [[ $DUMP_OBJECT_FILE -eq 1 ]]
then
	echo $DUMP_OBJECT_FILE
	declare -a REGX_EX_PATH=("^/.recycle/*","*/.git/*")
	for ITEM in "${REGX_EX_PATH[@]}"
	do
		if [[ "$FILE_PATH" =~ $ITEM ]]
		then
			. ./write_log.sh WARN "Object file \"$FILE_PATH$FILE_NAME\" match exclude rule $ITEM, skipping"
			continue
		fi
	done
fi
