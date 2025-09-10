#!/bin/bash

targetParentDirectory="$HOME/Documents/build"

if lsof -i :5432 > /dev/null 2>&1;then
    echo "Postgres is running in port 5432"
    echo "Please stop the server for further installation"
    exit 1
fi

read -p "Enter the build version of pg (e.g : REL_16_0): " version

echo $version

buildDirectory="$targetParentDirectory/$version/"

if [ ! -d $buildDirectory ];then
    echo "No such build found"
    exit 1
fi

bin="$buildDirectory/bin"
if [ ! -d $bin ];then
    echo "Bin folder not found in the build directory"
    exit 1
fi

pgdataDirectory="$buildDirectory/data"

echo "Creating data directory for Postgres version  : $version"

if mkdir -p "$pgdataDirectory";then
    echo "Directory created successfully"
else 
    echo "Directory creation failed"
    exit 1
fi

pg_ctl="$binPath/pg_ctl"
createDB="$binPath/createdb"
psql="$binPath/psql"

logFileLocation="$pgdataDirectory/logfile"


echo "Setting the logfile"
if  $pg_ctl -D $pgdataDirectory -l $logFileLocation start ; then
    echo "Successfully setted up the logfile and server is started"
else 
    echo "Logfile assignment failed"
    exit 1
fi

read -p "Enter a db name to create" dbname
if  $createDB $dbname ; then
    echo "Created a $dbname database in the postgres"
else 
    echo "Setting up database failed"
    exit 1
fi

echo "Exiting dir"
cd "$currentDir"

echo $(pwd)
echo "Setting the alias in the .bashrc"

if ./set_alias.sh "$version" "$buildDirectory";then
    echo ".bashrc alias is set"
    echo "Running source"
    source $HOME/.bashrc
    echo "Sourced the file"
else
    echo "Couldn't set alias in bashrc"
fi

echo "Run 'pgsql $dbname' to run the postgres command line tool"