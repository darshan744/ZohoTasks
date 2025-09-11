#!/bin/bash

targetParentDirectory="$HOME/Documents/builds"

port=5432


read -p "Enter the build version of pg (e.g : REL_16_0): " version

echo $version


handlePort(){
    while true; do
        read -p "Enter a valid port number to run the server : " localPort
        if lsof -i :$localPort;then
            echo "Please enter a port that is free"
        else
            port=${localPort}
            break
        fi
    done
}

if lsof -i :$port > /dev/null 2>&1;then
    echo "It seems the port is already in use : $port"
    handlePort
fi


buildDirectory="$targetParentDirectory/$version/"

if [ ! -d $buildDirectory ];then
    echo "No such build found build path : $buildDirectory"
    echo "Run build script to build the version"
    exit 1
fi

binPath="$buildDirectory/bin"
if [ ! -d $binPath ];then
    echo "Bin folder not found in the build directory : $binPath"
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

dirExist() {
    if [ ! -f $1 ];then   
        echo "The binary $1 not found in the folder please cross check it"
        exit 1
    fi
}

pg_ctl="$binPath/pg_ctl"
createDB="$binPath/createdb"
psql="$binPath/psql"

dirExist $pg_ctl
dirExist $createDB
dirExist $psql

logFileLocation="$pgdataDirectory/logfile"

if $pg_ctl -D $pgdataDirectory status;then
    echo "This version is already running in another port"
    echo "Do you want to stop this and bind to the given port : $port"
    while true; do
        read -p "Specify the choice (y/n)" doStopCurrentPgCtl
        case "$doStopCurrentPgCtl" in
            y|Y)
                echo "Stopping the current server"
                $pg_ctl -D $pgdataDirectory -l $logFileLocation stop
                break
                ;;
            *)
                echo "Then please build another version and run this script"
                exit 1
                ;;
        esac
    done
fi

echo "Setting the logfile"
if  $pg_ctl -D $pgdataDirectory -l $logFileLocation -o "-p $port" start ; then
    echo "Successfully setted up the logfile and server is started"
else 
    echo "Logfile assignment failed"
    exit 1
fi

read -p "Enter a db name to create : " dbname
if  $createDB -p $port $dbname ; then
    echo "Created a $dbname database in the postgres"
else 
    echo "Database already exist"
fi

echo "Exiting dir"

echo "Setting the alias in the .bashrc"

if ./set_alias.sh "$version" "$buildDirectory";then
    echo ".bashrc alias is set"
    source ~/.bashrc
else
    echo "Couldn't set alias in bashrc"
fi
cleanVersion=${version#REL_}
cleanVersion=${cleanVersion#REL}

IFS="_" read -r major minor path <<< $cleanVersion

echo "Run  source ~/.bashrc and then run 'pgsql_${major}_${minor} $dbname' to run the postgres command line tool"