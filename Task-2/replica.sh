#!/bin/bash

# consts
binaryDirectory=$HOME/Documents/builds/REL_16_1/bin
masterDataDirectory=$HOME/Documents/Node1
slaveDataDirectory=$HOME/Documents/Node2
masterPort=3000
slavePort=3001
repuser=repuser
loginUser=darshan
loginPassword=12345
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
if ! $initdb -D $masterDataDirectory >> replica.log 2>&1;then 
    echo "Init db failed"
    exit 1
fi

echo "Master Starting server"
if ! $pg_ctl -D $masterDataDirectory -o "-p $masterPort" start >> replica.log 2>&1;then 
    echo "Master Server starting failed"
    exit 1
fi
echo "Creating login user"
if ! $psql --port=$masterPort -c "create user $loginUser with replication password '$loginPassword' createrole" $databaseName >> replica.log 2>&1;then
    echo "Creation of login user failed"
    exit 1;
fi

if ! $psql --port=$masterPort -U $loginUser -c "CREATE USER $repuser replication" $databaseName >> replica.log 2>&1;then
    echo "Create user failed"
    exit 1
fi

hba_conf_file=$masterDataDirectory/pg_hba.conf
echo "$hba_confLine" >> $hba_conf_file

echo "Restarting master server"

if ! $pg_ctl -D $masterDataDirectory reload >> replica.log 2>&1;then
    echo "Restarting of master server failed"
    exit 1
fi
echo "Master server running in port $masterPort"

# --slot is for telling the primary that i am connecting throug this name 
#   without this primary doesn't know how much this standby has read 
# -R -> replica
# -C is for create that slot automatically
# --port -> the data incoming port

echo "Configuring standby server"
if ! $pg_backup -h localhost -U $repuser --checkpoint=fast -D $slaveDataDirectory -R --slot=replica_slot -C --port=$masterPort >> replica.log 2>&1;then
    echo "Running pg_backup failed"
    exit 1;
fi

echo "Running standby server"
if ! $pg_ctl -D $slaveDataDirectory -o "-p $slavePort" start >> replica.log 2>&1; then
    echo "Slave server running failed"
    exit 1
fi
echo "Standby server running in port $slavePort"