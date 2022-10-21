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

$ZDB -e -AAA -ddddd "${POOLNAME}/${DATASET}" $OBJECT_ID

$ZDB -R -e $POOLNAME "${DUMP_OFFSET}:r" > ./testdumpfile.md

truncate --size=$SIZE $FILE_PATH

echo $1 $2 
echo $@


