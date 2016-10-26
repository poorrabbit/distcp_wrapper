#usage distcp.sh resourcepool sourcecluster targetcluster sourcefiles targetpath
#sourcecluster and targetcluster options are: DEV, TEST, and PROD

#This does very little in the way of error checking. 
#If the arguments are invalid in any way, the script will fail.
#For example if you put something other than DEV, TEST or PROD as the source/target
#the script will error out.

#check to make sure we have arguments
norun="0"
if  [[ -z $1  ||  -z $2  ||  -z $3  ||  -z $4   ||  -z $5 ]];
	then 
	norun="1";
fi

if [[ $1 == "help" || $1 == "-help" || $1 == "--help" || $1 == "-?" ]];
then
 norun="1"
fi

if [ $norun == "1" ]
then
	echo "
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

To CONSISTENTLY copy the contents of a directory you should use \"*\" to copy all files 
in the source path, like so:
distcp.sh testpoolname SOURCECLUSTER TARGETCLUSTER /path/to/source/files/* /path/to/target/directory

targetdirectory: Valid HDFS path pointing to where files should be copied on target cluster
If the target directory does not exist, the full path to it will be created.
"

	exit;
fi

resource_pool=$1
source_cluster=$2
target_cluster=$3
source_files=$4
target_path=$5
distcp_rp_config="-Dmapreduce.job.queuename=$resource_pool"

#Edit the following to match the IP of your HA namenodes in each environment.
devNN1="127.0.0.1"
devNN2="127.0.0.1"
testNN1="127.0.0.1"
testNN2="127.0.0.1"
prodNN1="127.0.0.1"
prodNN2="127.0.0.1"


echo "Going to distcp hdfs files with the following options:"
echo ""
echo "Source cluster is $source_cluster"
echo "Target cluster is $target_cluster"
echo "Source files are $source_files"
echo "Target Path is $target_path"
echo "Resource pool is $resource_pool"
echo "distcp resource pool config is $distcp_rp_config"
echo ""
echo "If these options are incorrect, press control-c now. Waiting 5 seconds."
sleep 5


#SOME ERROR CHECKING
if [ $source_cluster == $target_cluster ]
then

	if [ $sourcefiles== $targetpath ]
	then
	echo "Source Cluster and sourcefiles path and  Target Cluster source files path are the same. Exiting."
	echo "EXITING"
	exit;
	fi
fi


#figure out which namenode to use for source and set beeline command
echo "Checking source data namenode status"
source_namenode="0"
if [ $source_cluster == "DEV" ]
then
nntest=`curl -s -S http://${devNN1}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode1=`echo $nntest | grep -c active`
nntest=`curl -s -S http://${devNN2}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode2=`echo $nntest | grep -c active`
nn1_ip=$devNN1
nn2_ip=$devNN2
fi

if [ $source_cluster == "TEST" ]
then
nntest=`curl -s -S http://${testNN1}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode1=`echo $nntest | grep -c active`
nntest=`curl -s -S http://${testNN2}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode2=`echo $nntest | grep -c active`
nn1_ip=$testNN1
nn2_ip=$testNN2
fi

if [ $source_cluster == "PROD" ]
then
nntest=`curl -s -S http://${prodNN1}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode1=`echo $nntest | grep -c active`
nntest=`curl -s -S http://${prodNN2}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode2=`echo $nntest | grep -c active`
nn1_ip=$prodNN1
nn2_ip=$prodNN2
fi

if [ $namenode1 -eq "1" ] 
then
 source_namenode=$nn1_ip
 fi 
if [ $namenode2 -eq "1" ]
 then
 source_namenode=$nn2_ip
 fi

if [ $source_namenode == "0" ] 
then 
echo "No namenodes up for source, exiting"
exit
fi

echo "Source namenode is $source_namenode"

echo ""
echo ""
echo ""

#figure out which namenode to use for source
target_namenode="0"
echo "Checking target data namenode status"
if [ $target_cluster == "DEV" ]
then
nntest=`curl -s -S http://${devNN1}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode1=`echo $nntest | grep -c active`
nntest=`curl -s -S http://${devNN2}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode2=`echo $nntest | grep -c active`
nn1_ip=$devNN1;
nn2_ip=$defNN2;
fi

if [ $target_cluster == "TEST" ]
then
nntest=`curl -s -S http://${testNN1}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode1=`echo $nntest | grep -c active`
nntest=`curl -s -S http://${testNN2}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode2=`echo $nntest | grep -c active`
nn1_ip=$testNN1;
nn2_ip=$testNN2;
fi

if [ $target_cluster == "PROD" ]
then
nntest=`curl -s -S http://${prodNN1}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode1=`echo $nntest | grep -c active`
nntest=`curl -s -S http://${prodNN2}:50070/jmx?qry=Hadoop:service=NameNode,name=NameNodeStatus`
namenode2=`echo $nntest | grep -c active`
nn1_ip=$prodNN1
nn2_ip=$prodNN2
fi

if [ $namenode1 -eq "1" ]
then
 target_namenode=$nn1_ip
 fi
if [ $namenode2 -eq "1" ]
 then
 target_namenode=$nn2_ip
 fi

if [ $target_namenode == "0" ]
then
echo "No namenodes up for target, exiting"
exit
fi

echo "Target namenode is $target_namenode"
echo ""
echo ""
echo ""


target_hdfs="hdfs://$target_namenode:8020"
source_hdfs="hdfs://$source_namenode:8020"

#DISTCP THE DATA TO THE TARGET CLUSTER
echo "Copying data from source cluster to target cluster"
copy_source_to_target="hadoop distcp $distcp_rp_config hdfs://$source_namenode:8020/$source_files  hdfs://$target_namenode:8020/$target_path"
echo $copy_source_to_target
eval $copy_source_to_target
echo ""
echo ""

