#!/bin/bash

# ATIME=$(stat --format=%x $FILE_PATH/$FILE_NAME)
# MTIME=$(stat --format=%y $FILE_PATH/$FILE_NAME)
# CTIME=$(stat --format=%z $FILE_PATH/$FILE_NAME)
# CRTIME=$(stat --format=%w $FILE_PATH/$FILE_NAME)

# echo $ATIME
# echo $MTIME
# echo $CTIME
# echo $CRTIME

touch --no-create --date="${ACCESS_TIME}" --time=atime $FILE_PATH/$FILE_NAME
touch --no-create --date="${MODIFIED_TIME}" --time=mtime $FILE_PATH/$FILE_NAME

# ATIME=$(stat --format=%x $FILE_PATH/$FILE_NAME)
# MTIME=$(stat --format=%y $FILE_PATH/$FILE_NAME)
# CTIME=$(stat --format=%z $FILE_PATH/$FILE_NAME)
# CRTIME=$(stat --format=%w $FILE_PATH/$FILE_NAME)

# echo $ATIME
# echo $MTIME
# echo $CTIME
# echo $CRTIME
