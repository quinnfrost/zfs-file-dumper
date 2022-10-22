#!/bin/bash

# OBJECT_INFO=$(cat 'reg.txt')
# echo $OBJECT_INFO

if [ "$OBJECT_INFO" = "" ]
then
	./write_log.sh "No object in scope"
	exit
fi

if [ $(echo "$OBJECT_INFO" |wc -l) -le 1 ]
then
	./write_log.sh "Object is only 1 line"
	exit
fi

# REGX='Indirect blocks:\s+.* L0 (0:[^ ]*)'
REGX='path\s+(/[^
]*).*atime\s+([^
]+).*mtime\s+([^
]+).*ctime\s+([^
]+).*crtime\s+([^
]+).*size\s+([^
]+).*Indirect blocks:\s+.* L0 (0:[^ ]*)'

if [[ $OBJECT_INFO =~ $REGX ]]
then
	# for((i=1;i<10;i++));
	# do
	# 	echo ${BASH_REMATCH[$i]}
	# done

	FILE_PATH=${BASH_REMATCH[1]}
	ACCESS_TIME=${BASH_REMATCH[2]}
	MODIFIED_TIME=${BASH_REMATCH[3]}
	CHANGE_TIME=${BASH_REMATCH[4]}
	CREATION_TIME=${BASH_REMATCH[5]}
	SIZE=${BASH_REMATCH[6]}
	DUMP_OFFSET=${BASH_REMATCH[7]}

else
	./write_log.sh "No Object info found"
	exit
fi


REGX_NAME='/([^/]*)$'
[[ $FILE_PATH =~ $REGX_NAME ]]
	FILE_NAME=${BASH_REMATCH[1]}

REGX_PATH='(.*)/[^/]+$'
[[ $FILE_PATH =~ $REGX_PATH ]]
	FILE_PATH=${BASH_REMATCH[1]}


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
	./write_log.sh "Fail to grip some attribute"
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
