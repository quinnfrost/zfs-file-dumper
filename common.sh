ZDB="/usr/local/sbin/zdb"
DUMP_DIR="./zdbdump"
# TEMP_FILENAME="dump.tmp"
POOLNAME="poolname"
DATASET="dataset"
QUIET="0"
# LOGFILE="./dumpinfo.log"
# ERRORFILE="./dumperr.log"
LOGARCHIVE_PATH="./log/"
SKIP_LOG="./skipped_file_downloads.txt"

DUMP_OBJECT_ID_FILENAME="./objects_downloads.txt"
DUMP_EMBEDDED_FILENAME="./embedded_objects_downloads.txt"
DUMP_ZEROED_FILENAME="./zero_sized_objects_downloads.txt"
# param 1: file
# param 2: offset
# param 3: value
# function replaceByte() {
#     printf "$(printf '\\x%02X' $3)" | dd of="$1" bs=1 seek=$2 count=1 conv=notrunc &> /dev/null
# }

# Usage:
# replaceByte 'thefile' $offset 95
