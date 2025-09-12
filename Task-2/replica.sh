#!/bin/bash

# consts
binaryDirectory=$HOME/Documents/builds/REL_16_1/bin
masterDataDirectory=$HOME/Documents/MasterDB
slaveDataDirectory=$HOME/Documents/ReplicaDB
masterPort=3000
slavePort=3001
repuser=repuser

removeAndCreate() {
    if [ -d $1 ];then
        rm -rf $1
        mkdir $1
    fi
}
removeAndCreate $masterDataDirectory
removeAndCreate $slaveDataDirectory

chmod 0700 $slaveDataDirectory

databaseName=postgres
hba_confLine="host  replication $repuser   127.0.0.1/32     trust"

initdb=$binaryDirectory/initdb
pg_ctl=$binaryDirectory/pg_ctl
psql=$binaryDirectory/psql
pg_backup=$binaryDirectory/pg_basebackup
echo "Initializing master Directory : $masterDataDirectory"
$initdb -D $masterDataDirectory

echo "Master Starting server"
if ! $pg_ctl -D $masterDataDirectory -o "-p $masterPort" start;then 
    echo "Master Server starting failed"
    exit 1
fi

if ! $psql --port=$masterPort -c "CREATE USER $repuser replication" $databaseName;then
    echo "Create user failed"
    exit 1
fi

hba_conf_file=$masterDataDirectory/pg_hba.conf
echo "$hba_confLine" >> $hba_conf_file

echo "Restarting master server"

if ! $pg_ctl -D $masterDataDirectory reload;then
    echo "Restarting of master server failed"
    exit 1
fi

# --slot is for telling the primary that i am connecting throug this name 
# without this primary doesn't know how much this standby has read 
# -R -> replica
# -C is for create that slot automatically
# --port -> the data incoming port

if ! $pg_backup -h localhost -U $repuser --checkpoint=fast -D $slaveDataDirectory -R --slot=replica_slot -C --port=$masterPort;then
    echo "Running pg_backup failed"
    exit 1;
fi

if ! $pg_ctl -D $slaveDataDirectory -o "-p $slavePort" start; then
    echo "Slave server running failed"
fi