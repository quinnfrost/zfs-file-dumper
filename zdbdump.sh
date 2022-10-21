#!/bin/bash
# Dump file by Object ID
# Todos: 

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

$ZDB -e -AAA -ddddd "${POOLNAME}/${DATASET}" $OBJECT_ID 

$ZDB -R -e $POOLNAME "${DUMP_OFFSET}:r" > $FILE_PATH

truncate --size=$SIZE $FILE_PATH

echo $1 $2 
echo $@

ELAPSED_TIME=$(expr $(date +%s%3N) - $START_TIME)
echo "Command finished in $ELAPSED_TIME milliseconds"
