#!/bin/bash

binaryDirectory=$HOME/Documents/builds/REL_16_1/bin

currentMasterDirectory=$HOME/Documents/Node1
currentMasterPort=3000

currentStandbyDirecotry=$HOME/Documents/Node2
currentStandbyPort=3001

thirdDirectory=$HOME/Documents/Node3
currentFreePort=3002

currentEmptyDirectory=$thirdDirectory

if [ -d $currentEmptyDirectory ];then
    rm -rf $currentEmptyDirectory
fi

pg_isready=$binaryDirectory/pg_isready
pg_ctl=$binaryDirectory/pg_ctl
pg_basebackup=$binaryDirectory/pg_basebackup
psql=$binaryDirectory/psql

if [ ! -f $pg_isready ];then
    echo "pg_isready doesn't exist"
    exit 1;
fi

check_ready() {
    $pg_isready --port=$1 -d postgres >> /dev/null 2>&1;
}


swap_primary_and_standby_ports() {
    local port=$currentMasterPort
    currentMasterPort=$currentStandbyPort
    currentStandbyPort=$currentFreePort
    currentFreePort=$port
}
swap_primary_and_standby_directories() {
    local dir=$currentMasterDirectory;
    currentMasterDirectory=$currentStandbyDirecotry
    currentStandbyDirecotry=$currentEmptyDirectory;
    currentEmptyDirectory=$dir;
}

master_down() {
    echo "Promoting standby....."
    $pg_ctl -D $currentStandbyDirecotry promote
    # change the current master service port to the standby which was promoted
    swap_primary_and_standby_ports

    if [ -d $currentEmptyDirectory ];then
        rm -rf $currentEmptyDirectory
    fi
    
    # since we are swapping there might be a chance that 
    # the replication_name can be in already use
    # so we are deleting that replication name and create with same name
    $psql --port=$currentMasterPort postgres -c "select pg_drop_replication_slot('replica_slot')"
    $pg_basebackup -h localhost -U repuser --checkpoint=fast -D $currentEmptyDirectory -R --slot=replica_slot -C --port=$currentMasterPort
    $pg_ctl -D $currentEmptyDirectory -o "-p $currentStandbyPort" start
    swap_primary_and_standby_directories

    echo "Master : $currentMasterDirectory"
    echo "Standby :  $currentStandbyDirecotry"
    echo "Currently free : $currentEmptyDirectory"

}



standby_down() {
    
    if [ -d $currentEmptyDirectory ];then
        rm -rf $currentEmptyDirectory;
    fi

    $psql --port=$currentMasterPort postgres -c "select pg_drop_replication_slot('replica_slot')"

    $pg_basebackup -h localhost -U repuser --checkpoint=fast -D $currentEmptyDirectory -R --slot=replica_slot -C --port=$currentMasterPort

    local port=$currentStandbyPort;
    currentStandbyPort=$currentFreePort;
    currentFreePort=$port;

    local dir=$currentStandbyDirecotry;
    currentStandbyDirecotry=$currentEmptyDirectory
    currentEmptyDirectory=$currentStandbyDirecotry

    $pg_ctl -D $currentStandbyDirecotry -o "-p $currentStandbyPort" start
}


monitor(){
    while true;do
        check_ready $currentMasterPort
        # $pg_isready --port=$currentMasterPort -d postgres >> /dev/null 2>&1;

        if [ $? -ne 0 ];then
            echo  "$(date) - [ERROR] Master server is down"
            master_down
        fi

        check_ready $currentStandbyPort

        # $pg_isready --port=$currentStandbyPort -d postgres >> /dev/null 2>&1;
        if [ $? -ne 0 ];then
            echo "$(date) - [ERROR] Slave server is down"
            standby_down
        fi
        sleep 0.5
    done
}

monitor