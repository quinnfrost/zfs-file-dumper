#!/bin/bash
# This file takes in an object id and output parsed file info
. ./common.sh

[ "$OBJECT_INFO" = "" ] && [ "$1" != "" ] && OBJECT_INFO=$($ZDB -e -AAA -ddddd "${POOLNAME}/${DATASET}" ${1-'227078'})

if [ "$OBJECT_INFO" = "" ]
then
	./write_log.sh WARN "($OBJECT_ID)No object in scope"
	exit
fi

if [[ $OBJECT_INFO == *"ZFS plain file"* ]]
then
	./write_log.sh "Object type ZFS plain file"
else
	./write_log.sh WARN "$OBJECT_INFO"
	./write_log.sh WARN "($OBJECT_ID)Object is not a file"
	exit
fi

if [ $(echo "$OBJECT_INFO" |wc -l) -le 5 ]
then
	./write_log.sh WARN "($OBJECT_ID)Object is too 1 short"
	exit
fi

# REGX='Indirect blocks:\s+.* L0 (0:[^ ]*)'
REGX='path\s+(/[^
]*).*atime\s+([^
]+).*mtime\s+([^
]+).*ctime\s+([^
]+).*crtime\s+([^
]+).*size\s+([^
]+).*Indirect blocks:\s+.* (0 +L0.*)'

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
	exit
fi

REGX_NAME='/([^/]*)$'
[[ $FILE_PATH =~ $REGX_NAME ]]
	FILE_NAME=${BASH_REMATCH[1]}

REGX_PATH='(.*/)[^/]+$'
[[ $FILE_PATH =~ $REGX_PATH ]]
	FILE_PATH=${BASH_REMATCH[1]}

REGX_OFFSET='.*L0 (0:[^ ]*)'
REGX_INDEX='0'
while [[ $DUMP_OFFSET =~ $REGX_OFFSET ]]
do
	CURRENT=$(printf "$DUMP_OFFSET" | sed -n '1p')
	[[ $CURRENT =~ $REGX_OFFSET ]]
		OFFSETS[$REGX_INDEX]=${BASH_REMATCH[1]}
		# printf "${BASH_REMATCH[1]}\n"
		DUMP_OFFSET=$(printf "$DUMP_OFFSET" | sed '1d')
		REGX_INDEX=$((REGX_INDEX+1))
done
OFFSET_LEN=$REGX_INDEX

# Check if something is missing
if [[ $FILE_NAME = "" ]] \
|| [[ $FILE_PATH = "" ]] \
|| [[ $ACCESS_TIME = "" ]] \
|| [[ $MODIFIED_TIME = "" ]] \
|| [[ $CHANGE_TIME = "" ]] \
|| [[ $CREATION_TIME = "" ]] \
|| [[ $SIZE = "" ]] \
|| [[ $DUMP_OFFSET = "" ]]
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
	# echo $DUMP_OFFSET
