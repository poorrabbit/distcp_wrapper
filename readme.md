distcp.sh is a wrapper for the "hadoop distcp" command on Cloudera 5.4.7 clusters.

On cluster running HA Namenodes (active plus standby), distcp requires that you 
know which namenode is active on the target cluster. This is particularly true
if the nameservice on each cluster has the same name (often: nameservice1). 
When cluster services on different clusters, they cannot share configs which
would tell each cluster where the appropriate namenodes are for each cluter.

So, you get stuck having to figure out which namenode is live when you want
to copy files via distcp from one cluster to the other. This makes running
automated tasks difficult. This script aims to alleviate the issue.

It is very quick and dirty. It also has repeated code that should be functioned
or looped. It does, however, work.

To make it work for you, you will need to edit the distcp.sh script file
and change the IP addresses to match those of YOUR namenodes. The script
currently supports up to 3 "environments", named DEV, TEST, and PROD.

How to change that should be fairly obvious.

If you are NOT using this script on an environment that is using regulated
resource pools, then the name of the resource pool can be anything, though
if would be wise to consistent in your usage. If you ARE using regulated resource
pools, then the resource pool specified must be one on which the user calling the
script has job submission permissions.

It may work on other distributions. 
It may work on other versions.
As this is developed against CDH 5.4.7, there are no guarantees of either.

All arguments are required.

Usage:

distcp.sh resourcepool sourcecluster targetcluster sourcefiles targetdirectory

resourcepool: A Resource pool on which you have job submission privileges

sourcecluster: The source cluster for the distcp operation (DEV, TEST, PROD)

targetcluster: The target cluster for the distcp operation (DEV, TEST, PROD)
If sourcefiles and targetpath are DIFFERENT, then source and target clusters may be the same

sourcefiles: Valid HDFS path pointing to files to be copied

/path/to/file_name  will copy a single file called filename to the TARGET DIRECTORY
/path/to/file_name* will copy files starting with file_name

WILDCARDS SHOULD BE USED WHEN COPYING DIRECTORIES:

/path/to/files HAS TWO POSSIBILITIES:
	If the TARGET DIRECTORY ALREADY EXISTS then the SOURCE DIRECTORY will be CREATED
	within the TARGET DIRECTORY

	If the TARGET DIRECOTRY DOES NOT EXIST, then the CONTENTS of the SOURCE DIRECTORY
	will be copied INTO the TARGET DIRECTORY

To CONSISTENTLY copy the contents of a directory you should use "*" to copy all files 
in the source path, like so:
distcp.sh testpoolname SOURCECLUSTER TARGETCLUSTER /path/to/source/files/* /path/to/target/directory

targetdirectory: Valid HDFS path pointing to where files should be copied on target cluster
If the target directory does not exist, the full path to it will be created.
