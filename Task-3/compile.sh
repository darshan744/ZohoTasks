#!/bin/bash

postgres_source_directory=$(pwd)/postgres
buildDirectory=$HOME/Documents/Auto

# Logs
distCleanLogs=$(pwd)/distclean.log
configLog=$(pwd)/configure.log
makeLog=$(pwd)/make.log
makeInstallLog=$(pwd)/makeinstall.log

# Master and Replica Directories and port
masterDirectory=$HOME/Documents/Auto/Node1
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
    
}

# compile_postgres