#!/bin/bash

. ./common.sh

DRYRUN="0"

CHECKPOINT_FILE="./dump_checkpoint.txt"
DUMP_FILELIST="./plainfilelist.txt"

if [[ $LOGFILE != "" ]] || [[ $ERRORFILE != "" ]] 
then
	. ./archive_logfile.sh $OBJECT_ID
	# rm "$LOGFILE" # && rm "$ERRORFILE"
fi

DUMPFILE_START_TIME=$(date +%s%3N)
. ./write_log.sh "Start to dump all files"

# Default 4
if [ -e $CHECKPOINT_FILE ]
then
	LINE_START=$(sed -n 1p $CHECKPOINT_FILE)
	if [[ $LINE_START =~ [0-9]+ ]]
	then
		. ./write_log.sh "Checkpoint found, setting start line to $LINE_START"
	else
		. ./write_log.sh WARN "Checkpoint invalid"
		exit
	fi
else
	LINE_START="4"
fi

LINE_INDEX=$LINE_START
LINE_COUNT=$(wc --lines < "$DUMP_FILELIST")
REGX_OBJECT_ID="^\s+([0-9]+).*ZFS.*"

. ./write_log.sh "Get total lines $LINE_COUNT"
# while IFS= read -r line; do
#     echo "Text read from file: $line"
# done < "$DUMP_FILENAME"
while [[ $LINE_INDEX -le $LINE_COUNT ]]
do
	LINE=$(sed -n ${LINE_INDEX}p $DUMP_FILELIST)
	if [[ $LINE = "" ]]
	then
		. ./write_log.sh WARN "Empty line found at $LINE_INDEX"
		LINE_INDEX=$((LINE_INDEX+1))
		continue
	fi
	# LINE=$(head -n $LINE file | tail -1)
	if [[ $LINE =~ $REGX_OBJECT_ID ]]
	then
		OBJECT_ID=${BASH_REMATCH[1]}
		. ./write_log.sh "Processing $OBJECT_ID at $((LINE_INDEX))/$((LINE_COUNT))"
		[[ $DRYRUN -ne 1 ]] && ./zdbdump.sh $OBJECT_ID
		echo $((LINE_INDEX+1)) > $CHECKPOINT_FILE
	else
		. ./write_log.sh WARN "No object id found at $LINE_INDEX"
	fi

	if [[ $((LINE_INDEX%100)) -eq 0 ]]
	then
		DUMPFILE_ELAPSED_TIME=$(expr $(date +%s%3N) - $DUMPFILE_START_TIME)
		. ./write_log.sh "Processing line $LINE_INDEX/$LINE_COUNT, $(echo "scale=3; $DUMPFILE_ELAPSED_TIME / 1000" | bc) s elapsed"
		. ./write_log.sh "appx. $(echo "scale=3; $DUMPFILE_ELAPSED_TIME/$((LINE_INDEX-LINE_START))/1000" | bc) s per object, estimate $(echo "scale=3; $((LINE_COUNT-LINE_INDEX))*$DUMPFILE_ELAPSED_TIME/$((LINE_INDEX-LINE_START))/60000" | bc) min"
	fi

	if [[ $((LINE_INDEX%1000)) -eq 0 ]]
	then
		if [[ $LOGFILE != "" ]] || [[ $ERRORFILE != "" ]] 
		then
			. ./archive_logfile.sh $OBJECT_ID
			# rm "$LOGFILE" # && rm "$ERRORFILE"
		fi
	fi

	DISK_USAGE=$(df --output=pcent $DUMP_DIR | tail -n 1 | tr -d '[:space:]|%')
	if [[ $DISK_USAGE -gt 90 ]]
	then
		. ./write_log.sh WARN "Disk usage over 90%, exiting"
		exit
	else
		. ./write_log.sh "Current disk usage: $DISK_USAGE%"
	fi
	LINE_INDEX=$((LINE_INDEX+1))
done

DUMPFILE_ELAPSED_TIME=$(expr $(date +%s%3N) - $DUMPFILE_START_TIME)
. ./write_log.sh "Done dumping $((LINE_COUNT-LINE_START)) objects in $(echo "scale=3; $DUMPFILE_ELAPSED_TIME/1000" | bc) s, appx. $(echo "scale=3; $DUMPFILE_ELAPSED_TIME/$((LINE_COUNT-LINE_START))/1000" | bc) s per object"

