#!/bin/bash

ATIME=$(stat --format=%x "$1")
MTIME=$(stat --format=%y "$1")
CTIME=$(stat --format=%z "$1")
CRTIME=$(stat --format=%w "$1")

echo "Accessed at" $ATIME
echo "Modified at" $MTIME
echo "Changed  at" $CTIME
echo "Created  at" $CRTIME

# touch --no-create --date="${ACCESS_TIME}" --time=atime $FILE_PATH/$FILE_NAME
# touch --no-create --date="${MODIFIED_TIME}" --time=mtime $FILE_PATH/$FILE_NAME

# ATIME=$(stat --format=%x $FILE_PATH/$FILE_NAME)
# MTIME=$(stat --format=%y $FILE_PATH/$FILE_NAME)
# CTIME=$(stat --format=%z $FILE_PATH/$FILE_NAME)
# CRTIME=$(stat --format=%w $FILE_PATH/$FILE_NAME)

# echo $ATIME
# echo $MTIME
# echo $CTIME
# echo $CRTIME
