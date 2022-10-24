#!/bin/bash
. ./common.sh

OBJECT_INFO=$(cat reg17.txt)

REGX='path\s+(/[^
]*).*atime\s+([^
]+).*mtime\s+([^
]+).*ctime\s+([^
]+).*crtime\s+([^
]+).*size\s+([^
]+).*Indirect blocks:\s+.*(L0.*)'
# Todo: 中文导致正则无匹配
echo -e "$OBJECT_INFO"
echo -e "$REGX"
[[ $OBJECT_INFO =~ $REGX ]]
	for((i=1;i<10;i++));
	do
		echo ${BASH_REMATCH[$i]}
	done
	echo ${#BASH_REMATCH[@]}

	FILE_PATH=${BASH_REMATCH[1]}
	ACCESS_TIME=${BASH_REMATCH[2]}
	MODIFIED_TIME=${BASH_REMATCH[3]}
	CHANGE_TIME=${BASH_REMATCH[4]}
	CREATION_TIME=${BASH_REMATCH[5]}
	SIZE=${BASH_REMATCH[6]}
	DUMP_OFFSET=${BASH_REMATCH[7]}

# else
# 	./write_log.sh WARN "($OBJECT_ID)No Object info found"
# 	./write_log.sh WARN $OBJECT_INFO
# 	exit
# fi