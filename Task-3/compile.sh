#!/bin/bash

postgres_source_directory=$(pwd)/postgres
buildDirectory=$HOME/Documents/Auto

# Logs
distCleanLogs=$(pwd)/distclean.log
configLog=$(pwd)/configure.log
makeLog=$(pwd)/make.log
makeInstallLog=$(pwd)/makeinstall.log

# Master and Replica Directories and port
masterDirectory=$HOME/Documents/Auto/Node
masterPort=3000
baseReplicaDirectoryString=$HOME/Documents/Auto/Node
slavePort=3001

# if source not found clone it
if [ ! -d $postgres_source_directory ];then
    echo "Postgres source directory not found"
    echo "Cloning from github"
    git clone https://github.com/postgres/postgres
fi

if [ ! -d $buildDirectory ];then
    echo "Build directory not found creating directory at location : $buildDirectory"
fi

version=$1
numberOfReplicas=$2
tags=($(git -C $postgres_source_directory tag))


if [ $# -ne 2 ];then
    echo "Illegal number of arguments"
    echo "[USAGE] ./compile.sh <version-tag> <number-of-replicas>" 
    exit
fi


find_if_tag_exist() {
    found=0
    for tag in "${tags[@]}";do
        if [ $version == $tag ];then
            echo $tag
            found=1
        fi
    done

    if [ $found -eq 0 ];then
        echo "[ERROR] The tag $version not found. Please enter a valid tag"
        exit 1
    fi
}

compile_postgres() {
    # check if the tag exist or else stop the program
    find_if_tag_exist
    
    cd $postgres_source_directory

    if git -C $postgres_source_directory checkout $version; then
        echo "Successfully switched $version"
    else
        echo "Couldn't switch branch/ Tags"
    fi

    echo "[INFO] Running make distclean please watch logs at $distCleanLogs"

    if ! make distclean > $distCleanLogs 2>&1;then
        echo "Theres nothing to clean"
    fi

    echo "[INFO] Running ./configure please watch logs at $configLog"
    if ! ./configure --prefix="$buildDirectory/$version" > $configLog 2>&1;then
        echo "[ERROR] Configuring the postgres source failed please verify the logs"
        exit 1;
    fi

    echo "[INFO] Running make please watch logs at $makeLog"
    if ! make > $makeLog 2>&1;then
        echo "[ERROR] Make failed please look at logs"
        exit 1
    fi

    echo "[INFO] Running make install please watch logs at $makeInstallLog"
    if ! make install > $makeInstallLog 2>&1;then
        echo "[ERROR] Make install failed please look at logs"
        exit 1
    fi
}

set_replicas() {

    if [ -d $masterDirectory ];then
        rm -r $masterDirectory
    fi


    initdb=$buildDirectory/$version/bin/initdb
    pg_ctl=$buildDirectory/$version/bin/pg_ctl
    psql=$buildDirectory/$version/bin/psql
    pg_backup=$buildDirectory/$version/bin/pg_basebackup

    # hba_conf
    hba_confLine="host  replication repuser   127.0.0.1/32     trust"
    hba_conf_file=$masterDirectory/pg_hba.conf

    echo "[INFO] Initializing Master Directory"
    
    if ! $initdb -D $masterDirectory> replica.log 2>&1;then
        echo "[ERROR] Couldn't initialize the Master database"
        exit 1
    fi

    echo "[INFO] Starting master server"

    if ! $pg_ctl -D $masterDirectory -o "-p $masterPort" start >> replica.log 2>&1;then
        echo "Starting of master server failed"
        exit 1
    fi
echo "[INFO] Creating a replication user"
    if ! $psql --port=$masterPort -c "create user repuser replication" postgres >> replica.log 2>&1;then
        echo "Couldn't create user repuser"
        exit 1
    fi

    echo $hba_confLine >> $hba_conf_file

    echo "[INFO] Restarting the master server"

    if ! $pg_ctl -D $masterDirectory reload >> replica.log 2>&1;then
        echo "Restarting the master server failed"
        exit 1
    fi

    echo "[INFO] Master server running in port $masterPort"

    echo "[INFO] Configuring standby server"

    for ((i=1 ; i<=$numberOfReplicas;i++));do
        slotName="rep_slot_$i"
        slaveDirectory="${baseReplicaDirectoryString}$i"
        if [ -d $slaveDirectory ];then
            rm -rf $slaveDirectory;
        fi
        if ! $pg_backup -h localhost -U repuser --checkpoint=fast -D $slaveDirectory -R --slot=$slotName -C --port=$masterPort >> replica.log 2>&1;then
            echo "Configuring Standby server for dir : $slaveDirectory , port : $slavePort failed"
            exit 1;
        fi

        if ! $pg_ctl -D $slaveDirectory -o "-p $slavePort" start >> replica.log;then
            echo "Starting the standby server for dir :$slaveDirectory , port : $slavePort failed"
            exit 1;
        fi
        ((slavePort++))
    done
    echo "[SUCCESS] Successfully configured the server for Replicas $numberOfReplicas"
}

compile_postgres
set_replicas