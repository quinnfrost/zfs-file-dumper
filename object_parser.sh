#!/bin/bash
# This file takes in an object id and output parsed file info
. ./common.sh

PARSE_START_TIME=$(date +%s%3N)

if [[ ${1} != "" ]]
then
	OBJECT_ID=${1}
elif [[ $OBJECT_ID = "" ]]
then
	./write_log WARN "No object id given"
	exit
fi
./write_log.sh "Starting to parse object $OBJECT_ID"
[ "$OBJECT_INFO" = "" ] && OBJECT_INFO=$($ZDB -e -AAA -ddddd "${POOLNAME}/${DATASET}" $OBJECT_ID)

if [ "$OBJECT_INFO" = "" ]
then
	./write_log.sh WARN "($OBJECT_ID)No object in scope"
	exit
fi

if [[ $OBJECT_INFO != *"ZFS plain file"* ]]
then
	./write_log.sh WARN "$OBJECT_INFO"
	./write_log.sh WARN "($OBJECT_ID)Object is not a file"
	exit
fi

if [ $(echo "$OBJECT_INFO" |wc -l) -le 5 ]
then
	./write_log.sh WARN "($OBJECT_ID)Object is too short"
	exit
fi

# REGX='Indirect blocks:\s+.* L0 (0:[^ ]*)'
REGX='path\s+(/[^
]*).*atime\s+([^
]+).*mtime\s+([^
]+).*ctime\s+([^
]+).*crtime\s+([^
]+).*size\s+([^
]+).*Indirect blocks:
(.*)segment*'
if [[ $OBJECT_INFO =~ $REGX ]]
then
	# for((i=1;i<10;i++));
	# do
	# 	echo ${BASH_REMATCH[$i]}
	# done
	# echo ${#BASH_REMATCH[@]}

	FILE_PATH=${BASH_REMATCH[1]}
	ACCESS_TIME=${BASH_REMATCH[2]}
	MODIFIED_TIME=${BASH_REMATCH[3]}
	CHANGE_TIME=${BASH_REMATCH[4]}
	CREATION_TIME=${BASH_REMATCH[5]}
	SIZE=${BASH_REMATCH[6]}
	DUMP_OFFSET=${BASH_REMATCH[7]}

else
	./write_log.sh WARN "($OBJECT_ID)No Object info found"
	./write_log.sh WARN $OBJECT_INFO
	exit
fi

REGX_NAME='/([^/]*)$'
[[ $FILE_PATH =~ $REGX_NAME ]]
	FILE_NAME=${BASH_REMATCH[1]}

REGX_PATH='(.*/)[^/]+$'
[[ $FILE_PATH =~ $REGX_PATH ]]
	FILE_PATH=${BASH_REMATCH[1]}

REGX_OFFSET='\sL0 (0:[^ ]*)'
REGX_INDEX='0'

# DUMP_LINE_COUNT=$(echo "$OBJECT_INFO" |wc -l)
CURRENT=$(printf "$DUMP_OFFSET" | sed -n '1p')
# printf "$DUMP_OFFSET\n"
# printf "Current line $CURRENT\n"
# printf "Line count $DUMP_LINE_COUNT\n"

while IFS= read -r CURRENT; do
	if [[ $CURRENT =~ $REGX_OFFSET ]]
	then
		OFFSETS[$REGX_INDEX]=${BASH_REMATCH[1]}
		# printf "${BASH_REMATCH[0]}\n"	
		# printf "${BASH_REMATCH[1]}\n"
		# DUMP_OFFSET=$(printf "$DUMP_OFFSET" | sed '1d')
		# CURRENT=$(printf "$DUMP_OFFSET" | sed -n '1p')
		REGX_INDEX=$((REGX_INDEX+1))
	fi
done < <(printf '%s\n' "$DUMP_OFFSET")

# while [[ $CURRENT =~ $REGX_OFFSET ]]
# do

# done
OFFSET_LEN=$REGX_INDEX

# Check if something is missing
if [[ $FILE_NAME = "" ]] \
|| [[ $FILE_PATH = "" ]] \
|| [[ $ACCESS_TIME = "" ]] \
|| [[ $MODIFIED_TIME = "" ]] \
|| [[ $CHANGE_TIME = "" ]] \
|| [[ $CREATION_TIME = "" ]] \
|| [[ $SIZE = "" ]] \
|| [[ $OFFSET_LEN -eq 0 ]]
then
	./write_log.sh WARN "($OBJECT_ID)Fail to grip some attribute"
	echo $FILE_NAME
	echo $FILE_PATH
	echo $ACCESS_TIME
	echo $MODIFIED_TIME
	echo $CHANGE_TIME
	echo $CREATION_TIME
	echo $SIZE
	echo $DUMP_OFFSET
	exit
fi

	# echo $FILE_NAME
	# echo $FILE_PATH
	# echo $ACCESS_TIME
	# echo $MODIFIED_TIME
	# echo $CHANGE_TIME
	# echo $CREATION_TIME
	# echo $SIZE
	# echo ${OFFSETS[@]}
	# echo $OFFSET_LEN

PARSE_ELAPSED_TIME=$(expr $(date +%s%3N) - $PARSE_START_TIME)
./write_log.sh "Finished parsing $OBJECT_ID at \"$FILE_PATH$FILE_NAME\" in $((PARSE_ELAPSED_TIME / 1000)).$((PARSE_ELAPSED_TIME % 1000)) s"
