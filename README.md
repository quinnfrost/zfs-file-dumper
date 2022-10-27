# zfs-file-dumper
A simple shell script to dump file from zfs pools.
It uses the zfs debug util (zdb) to perform all the operation on the zfs pools and datasets. The script simply automated the process.

# What this script can do
* Dump regular files in zfs dataset by object id
	- File types that are tested (by myself): normal and compressed files (lz4, but others should work), large files that occupy mutiple blocks (either blocks are consistent or not), files with holes in the middle (.iso or partial downloads)
* Dump and parse file info and automatically apply to the dump file
	- File info that can be extracted and apply to the dump file: file name, relative path in its dataset, change time, original size

# What this script can't do
* Get your pool back alive
* Dump files that has zero in size
* Dump files that is embedded in its parent dnode, mostly some very small files
* Extract and apply file extended attribute (user.xattr field)
