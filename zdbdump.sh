#!/bin/bash
# Dump file by Object ID
# Todos: 用正则表达式拿OBJECT_ID和其他内容

ZDB="/usr/local/sbin/zdb"
DUMP_DIR="./"
POOLNAME="hdd-1T"
DATASET="smbfiles"

OBJECT_ID="227078"

FILE_NAME=""
FILE_PATH="./testdumpfile.md"
SIZE="681"
ACCESS_TIME=""
MODIFIED_TIME=""
CHANGE_TIME=""
CREATION_TIME=""
DUMP_OFFSET="0:2f2ea8000:1000"

echo "[$(date "+%Y%m%d %H:%M:%S")] Start processing $OBJECT_ID"
START_TIME=$(date +%s%3N)

# REGX_OFFSET="\s+.*\s+L0\s+(0:[^:]*):([^:]*)\s+(\d+)L"
REGX_OFFSET='Indirect blocks:\s+.* L0 (0:[^ ]*)'

OBJECT_INFO=$($ZDB -e -AAA -ddddd "${POOLNAME}/${DATASET}" $OBJECT_ID)

if [[ $OBJECT_INFO =~ $REGX_OFFSET ]]
	then 
		DUMP_OFFSET=${BASH_REMATCH[1]}
	else 
		echo "Nothing found"
fi


$ZDB -R -e $POOLNAME "${DUMP_OFFSET}:r" > $FILE_PATH

truncate --size=$SIZE $FILE_PATH

echo $1 $2 
echo $@

ELAPSED_TIME=$(expr $(date +%s%3N) - $START_TIME)
echo "Command finished in $ELAPSED_TIME milliseconds"
