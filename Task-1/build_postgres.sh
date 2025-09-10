#!/bin/bash

# postgres source code
postgres_source_directory=$HOME/dev/ZohoTasks/Task-1/postgres
# all build directory
targetParentDirectory=$HOME/Documents/builds
# executing dir
currentDir=$(pwd)
if [ -d $postgres_source_directory ];then
    echo "Source directory in $postgres_source_directory"
else
    echo "Source directory not found"
    exit 1
fi


if [ ! -d $targetParentDirectory ]; then
    echo "Build directory not found creating it in $targetParentDirectory"
    mkdir -p $targetParentDirectory
fi

# make sure our source code is clean
cd "$postgres_source_directory"

make distclean

cd "$currentDir"

# array for filtering major version alone
declare -A mappedTags

# since tags is the target 
# in those REL is the one we go for as it is release tag
tags=$(git -C $postgres_source_directory tag | grep "^REL")


# This function creates map with major version as key and relavent versions as array for that key
# Now we can show only the major version and make them request it
maptags() {
    # loops through the tags found
    for tag in $@;
    do 
        # in those we remove the `REL` and `REL_`
        clean=${tag#REL_}
        clean=${clean#REL}
        
        # After that we have only the version number
        # specify the split parameter 
        IFS='_' read -r major minor patch <<< "$clean"

        # group the version tags with major version number alone
        mappedTags[$major]+="$tag "
    done
    # need to unset for any other uses 
    unset IFS
}
# To store the filtered tags
selectedMajorVersionTags=()

# select the major version and then show the corressponding versions
selectTag() {
    echo "Select major version:"
    select major in "${!mappedTags[@]}"; do #!associative array takes the keys and prints it
        if [ -n "$major" ]; then
            # echo "You selected major=${mappedTags[$major]}"
            local majorVersionTags=${mappedTags[$major]}
            selectedMajorVersionTags=($majorVersionTags)
            break
        fi
    done
}

maptags ${tags[@]}
selectTag

# TODO : group minor version also
select version in "${selectedMajorVersionTags[@]}"; do  # always refer arrays using ${var[@]}
    echo $version
    break
done

echo "Switching to version $version"
# switch to a different tag in the source code

# like other languages if doesn't check for boolean values
# it executes the given condition command and monitors the exit code of that
if git -C $postgres_source_directory checkout $version; then
    echo "Successfully switched $version"
else
    echo "Couldn't switch branch/ Tags"
    exit 1
fi

echo "Entering $postgres_source_directory"
cd "$postgres_source_directory"

buildDirectory="$targetParentDirectory/$version"
# run the configuration script and pass the target directory for the build
if  ./configure --prefix="buildDirectory"; then
    echo "Configuration of source code completed successfully"
else
    echo "Configuring the source code failed. Please check the error message in above"
    exit 1
fi


echo "Compiling the source code"

# make command compiles the source code to binary
# make install compiles and then moves the compiled binaries to the
# specified location
# But if we do that using this then we may get an error
# So by doing this we can find the error in compilation process or in moving the binaries
if make;then
    echo "Compilation successfull"
else 
    echo "Compilation failed look for error log above"
    exit 1
fi

echo "Running make install command"

# run the make command
# it installs the compiled binary to the directory
# we passed in the --prefix command in ./configure
if make install;then
    echo "Installation successfull"
    echo "Postgres installed in the directory $targetParentDirectory/$version"
else
    echo "Installation failed"
    echo "Please look for error message in the installation process"
    exit 1
fi

binPath="$targetParentDirectory/$version/bin"
pgdataDirectory="$targetParentDirectory/$version/data"

echo "Creating data directory for Postgres version : $version"

if mkdir -p "$pgdataDirectory";then
    echo "Directory created successfully"
else 
    echo "Directory creation failed"
    exit 1
fi

initdb="$binPath/initdb"
pg_ctl="$binPath/pg_ctl"
createDB="$binPath/createdb"
psql="$binPath/psql"

checkBinaryExistOrNot() {
    if [ ! -d $1 ];then
        echo "The binary for $1 Doesn't exist in the location"
        exit 1;
}
# check the existence of the binaries
checkBinaryExistOrNot $initdb
checkBinaryExistOrNot $pg_ctl
checkBinaryExistOrNot $createDB
checkBinaryExistOrNot $psql

logFileLocation="$pgdataDirectory/logfile"
echo "Setting the db storage path"
if $initdb -D $pgdataDirectory;then
    echo "Successfully registered the directory"
else 
    echo "$pgdataDirectory registration to $binPath/initdb failed"
    exit 1
fi

echo "Setting the logfile"
if  $pg_ctl -D $pgdataDirectory -l $logFileLocation start ; then
    echo "Successfully setted up the logfile and server is started"
else 
    echo "Logfile assignment failed"
    exit 1
fi

echo "Creating a test db"
if [ $createDB test ]; then
    echo "Created a test database in the postgres"
else 
    echo "Setting up database failed"
    exit 1
fi

echo "Exiting dir"
cd "$currentDir"

echo "Run `$pgsql test` to run the postgres command line tool"