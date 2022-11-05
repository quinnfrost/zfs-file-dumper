# zfs-file-dumper
A simple shell script to dump file from unimportable zfs pools.
It uses the zfs debug util (zdb) to perform all the operation on the zfs pools and datasets. The script simply automated the process.
Used on an unencrypted, lz4 compressed, deadlist failed single striped vdev datapool.

# note
There is something wrong when dumping files with holes like disk image, ISOs and partial complete downloads though some of them can be opened and working but the hash wont match the orignal file so it better be discarded and download again. The script was meant to deal with that but I mess it up somehow.

# usage
1. Set pool, dataset name, and other stuff in *common.sh*

2. Use
	```
	zdb -e -AAA -ddddd "POOLNAME/DATASETNAME" 0:-1:f > "./plainfiledump.txt"
	```
	to grab a list of all file objects in the dataset, search file name for the desired file, get the numerical ID under the OBJECT.
	Note that the list can be very large (GBs).

3. ./zdbdump.sh $OBJECT_ID
