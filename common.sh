ZDB="/usr/local/sbin/zdb"
# DUMP_DIR="/mnt/ankha/zdbdump"
DUMP_DIR="./zdbdump"
TEMP_FILENAME="dump.tmp"
POOLNAME="hdd-1T"
DATASET="smbfiles"
QUIET="0"
LOGFILE="./dumpinfo.log"
ERRORFILE="./dumperr.log"
LOGARCHIVE_PATH="./log/"

# param 1: file
# param 2: offset
# param 3: value
# function replaceByte() {
#     printf "$(printf '\\x%02X' $3)" | dd of="$1" bs=1 seek=$2 count=1 conv=notrunc &> /dev/null
# }

# Usage:
# replaceByte 'thefile' $offset 95
