#!/bin/bash

. ./common.sh

DRYRUN="0"

BATCH_SIZE="8"

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
		exit 1
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
#! 开始逐行读取并dump
while [[ $LINE_INDEX -le $LINE_COUNT ]]
do
	BATCH_INDEX="0"
	while [[ $BATCH_INDEX -lt $BATCH_SIZE ]]
	do
		LINE=$(sed -n $((LINE_INDEX+BATCH_INDEX))p $DUMP_FILELIST)
		# LINE=$(head -n $LINE file | tail -1)
		if [[ $LINE =~ $REGX_OBJECT_ID ]]
		then
			OBJECT_IDS[$BATCH_INDEX]=${BASH_REMATCH[1]}
		else
			. ./write_log.sh WARN "No object id found at $LINE_INDEX"
			break
		fi
		BATCH_INDEX=$((BATCH_INDEX+1))
	done # Batch

	. ./write_log.sh "----Processing ${OBJECT_IDS[@]} at ($LINE_INDEX~$((LINE_INDEX+BATCH_SIZE-1)))/$((LINE_COUNT))----"
	[[ $DRYRUN -ne 1 ]] && parallel -j${BATCH_SIZE} --line-buffer --halt soon,fail=1 ./zdbdump.sh {} ::: ${OBJECT_IDS[@]}
	if [[ $? -ne 0 ]] && [[ $DRYRUN -ne 1 ]]
	then
		. ./write_log.sh WARN "Parallel job failed at ($LINE_INDEX~$((LINE_INDEX+BATCH_SIZE-1)))/$((LINE_COUNT)), processing ${OBJECT_IDS[@]}"
		exit 1
	fi
	echo $((LINE_INDEX+BATCH_SIZE)) > $CHECKPOINT_FILE

	if [[ $((LINE_INDEX%100)) -lt $BATCH_SIZE ]]
	then
		DUMPFILE_ELAPSED_TIME=$(expr $(date +%s%3N) - $DUMPFILE_START_TIME)
		. ./write_log.sh "Processing line $LINE_INDEX/$LINE_COUNT, $(echo "scale=3; $DUMPFILE_ELAPSED_TIME / 1000" | bc) s elapsed"
		. ./write_log.sh "appx. $(echo "scale=3; $DUMPFILE_ELAPSED_TIME/$((LINE_INDEX-LINE_START))/1000" | bc) s per object, estimate $(echo "scale=3; $((LINE_COUNT-LINE_INDEX))*$DUMPFILE_ELAPSED_TIME/$((LINE_INDEX-LINE_START))/60000" | bc) min"
	fi

	if [[ $((LINE_INDEX%2000)) -lt $BATCH_SIZE ]]
	then
		if [[ $LOGFILE != "" ]] || [[ $ERRORFILE != "" ]] 
		then
			. ./archive_logfile.sh ${OBJECT_IDS[0]}
			# rm "$LOGFILE" # && rm "$ERRORFILE"
		fi
	fi

	DISK_USAGE=$(df --output=pcent $DUMP_DIR | tail -n 1 | tr -d '[:space:]|%')
	if [[ $DISK_USAGE -gt 90 ]]
	then
		. ./write_log.sh WARN "Disk usage over 90%, exiting"
		exit 1
	else
		. ./write_log.sh "Current disk usage: $DISK_USAGE%"
	fi
	LINE_INDEX=$((LINE_INDEX+BATCH_SIZE))

	read -t 0.01 -N 1 input
    if [[ $input = "q" ]] || [[ $input = "Q" ]] 
        then exit 1
	fi
done

DUMPFILE_ELAPSED_TIME=$(expr $(date +%s%3N) - $DUMPFILE_START_TIME)
. ./write_log.sh "Done dumping $((LINE_COUNT-LINE_START)) objects in $(echo "scale=3; $DUMPFILE_ELAPSED_TIME/1000" | bc) s, appx. $(echo "scale=3; $DUMPFILE_ELAPSED_TIME/$((LINE_COUNT-LINE_START))/1000" | bc) s per object"

exit 0
