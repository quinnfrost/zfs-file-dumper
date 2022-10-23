#!/bin/bash
. ./common.sh

DUMP_OBJECT_LIST="1"

DUMP_FILENAME="plainfilelist.txt"

[[ $DUMP_OBJECT_LIST = "1" ]] && $ZDB -e -AAA -d "${POOLNAME}/${DATASET}" 0:-1:f > ${DUMP_DIR}$DUMP_FILENAME




