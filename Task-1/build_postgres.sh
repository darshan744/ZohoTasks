#!/bin/bash

# postgres source code
postgres_source_directory=$HOME/dev/ZohoTasks/Task-1/postgres

# all build directory
targetParentDirectory=$HOME/Documents/builds

# executing dir
currentDir=$(pwd)

# If source doesn't exist
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

buildDirectory="$targetParentDirectory/$version"

compileSourceCode() {
    echo "Removing build directory if exist"

    logfile="$buildDriectory/data/logfile"

    # This only works if the overwriting build is the one running 
    # "$buildDirectory/bin/pg_ctl" -D "$buildDirectory/data" stop
    # So we have predefined a bunch of variable in the .bashrc file 
    # we can use that to start stop status of the pgsql 

    # echo "Stopping pgdata"
    if [ -d $buildDirectory ];then
        rm -rf "$buildDirectory"
    fi


    # make sure our source code is clean
    cd "$postgres_source_directory"
    distCleanLogLocation="$currentDir/distclean.log"
    echo "Running make distclean please watch logs in $distCleanLogLocation"

    make distclean >> "$distCleanLogLocation"

    cd "$currentDir"

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

    configureLogLocation="$currentDir/configure.log"
    echo "Running configure script please watch the logs in the $configureLogLocation"
    # run the configuration script and pass the target directory for the build
    if  ./configure --prefix="$buildDirectory" > $configureLogLocation 2>&1 ; then
        echo "Configuration of source code completed successfully"
    else
        echo "Configuring the source code failed. Please check the error message in above"
        exit 1
    fi

    echo "Compiling the source code"
    makeLog="$currentDir/make.log"
    # make command compiles the source code to binary
    # make install compiles and then moves the compiled binaries to the
    # specified location
    # But if we do that using this then we may get an error
    # So by doing this we can find the error in compilation process or in moving the binaries
    if make > "$makeLog" 2>&1;then
        echo "Compilation successfull"
    else 
        echo "Compilation failed look for error log above"
        exit 1
    fi

    echo "Running make install command"

    makeInstallLogLocation="$currentDir/makeinstall.log"
    # run the make command
    # it installs the compiled binary to the directory
    # we passed in the --prefix command in ./configure
    if make install > $makeInstallLogLocation 2>&1;then
        echo "Installation successfull"
        echo "Postgres installed in the directory $targetParentDirectory/$version"
    else
        echo "Installation failed"
        echo "Please look for error message in the installation process"
        exit 1
    fi
}
compiled=0
askUserInputForExistinBuild() {
    while true; do
        read -p "Do you want to re-install the built source (y/n)? " choice
        case "$choice" in
            y|Y)
                # echo "Yes command"
                compileSourceCode
                break
                ;;
            n|N)
                echo "Skipping compilation process"
                compiled=1
                break
                ;;
            *)
                echo "Invalid option please enter y or n"
                ;;
        esac
    done
}

if [ -d $buildDirectory ]; then
    echo "Build Directory already exist"
    askUserInputForExistinBuild
else 
   compileSourceCode
fi


binPath="$targetParentDirectory/$version/bin"
pgdataDirectory="$buildDirectory/data"


initdb="$binPath/initdb"

checkBinaryExistOrNot() {
    if [ ! -f $1 ];then
        echo "The binary for $1 Doesn't exist in the location"
        exit 1;
    fi
}

# check the existence of the binaries
checkBinaryExistOrNot $initdb

echo "Setting the db storage path"
if $initdb -D $pgdataDirectory;then
    echo "Successfully registered the directory"
else 
    echo "$pgdataDirectory registration to $binPath/initdb failed"
    exit 1
fi

echo "Postgres version : $version has been compiled and instaled in the $binPath"
echo "Run the start script to initialize postgres and run the server"