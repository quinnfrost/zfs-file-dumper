#!/bin/bash

OBJECT_INFO=$(cat 'reg.txt')

if [ "$OBJECT_INFO" = "" ]
then
	echo "No object in scope"
	exit
fi

if [ $(echo "$OBJECT_INFO" |wc -l) -le 1 ]
then
	echo "Object is only 1 line"
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

[[ $OBJECT_INFO =~ $REGX ]]

	echo ${BASH_REMATCH[0]}
	echo '----------------'
	for((i=1;i<10;i++));
	do
		echo ${BASH_REMATCH[$i]}
	done

	FILE_PATH=${BASH_REMATCH[1]}
	ACCESS_TIME=${BASH_REMATCH[2]}
	MODIFIED_TIME=${BASH_REMATCH[3]}
	CHANGE_TIME=${BASH_REMATCH[4]}
	CREATION_TIME=${BASH_REMATCH[5]}
	SIZE=${BASH_REMATCH[6]}
	DUMP_OFFSET=${BASH_REMATCH[7]}


REGX_NAME='/([^/]*)$'
if [[ $FILE_PATH =~ $REGX_NAME ]]
then
	FILE_NAME=${BASH_REMATCH[1]}
else
	echo "Nothing found"
fi

echo $FILE_NAME
echo $FILE_PATH
echo $ACCESS_TIME
echo $MODIFIED_TIME
echo $CHANGE_TIME
echo $CREATION_TIME
echo $SIZE
echo $DUMP_OFFSET
