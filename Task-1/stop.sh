#! /bin/bash

ParentBuildDirectory="$HOME/Documents/builds"

read -p "Enter the build version of pg (e.g : REL_16_0): " version

echo "Selected version $version"

buildDirectory=$ParentBuildDirectory/$version
if [ ! -d $buildDirectory ];then
    echo "The specified version is not in the build directory"
    exit 1
fi

pg_ctl="$buildDirectory/bin/pg_ctl"
dataDir="$buildDirectory/data"
logFileLocatoin="$buildDirectory/data/logfile"

echo "Stopping the specified version of PG"

if ! $pg_ctl -D $dataDir -l $logFileLocatoin status;then
    echo "The given version is not started use the start script to start the server"
    exit 0
fi

if $pg_ctl -D $dataDir -l $logFileLocatoin stop;then
    echo "Postgres version : $version has been stopped successfully"
else 
    echo "Error in stopping the server"
    exit 1
fi
