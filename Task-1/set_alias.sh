#!/bin/bash

version=$1
binaryLocation=$2

if [ -z $version ];then 
    echo "Please provide the version"
    exit 1
fi


if [ -z $binaryLocation ];then 
    echo "The binary location is not given"
    exit 1
fi

cleanVersion=${version#REL_}
cleanVersion=${cleanVersion#REL};

echo "CleanVersion : $cleanVersion"
IFS="_" read -r major minor path <<< $cleanVersion


pgsqlAlias="pgsql_${major}_${minor}"
unset IFS
startPgsql="${pgsqlAlias}_start"
stopPgsql="${pgsqlAlias}_stop"
statusPgsql="${pgsqlAlias}_status"
echo "Setting path parameters"
dataFolder="$binaryLocation/data"
echo "alias $startPgsql=\"$binaryLocation/bin/pg_ctl -D $dataFolder -l $dataFolder/logfile start\"" >> "$HOME/.bashrc"
echo "alias $stopPgsql=\"$binaryLocation/bin/pg_ctl -D $dataFolder -l $dataFolder/logfile stop\"" >> "$HOME/.bashrc"
echo "alias $pgsqlAlias=\"$binaryLocation/bin/psql\"" >> "$HOME/.bashrc"
echo "alias $statusPgsql=\"$binaryLocation/bin/pg_ctl -D $dataFolder status\"" >> "$HOME/.bashrc"

echo "Run source ~/.bashrc to setup path params"

echo "After sourcing you can start pg server using $startPgsql"
echo "After sourcing you can stop pg server using $stopPgsql"
echo "Server is already running use $pgsqlAlias (Note use after sourcing bashrc) test to run the database"

exit 0