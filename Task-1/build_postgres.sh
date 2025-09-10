#!/bin/bash

# postgres source code
postgres_source_directory=$HOME/dev/ZohoTasks/Task-1/postgres
# all build directory
targetParentDirectory=$HOME/dev/ZohoTasks/Task-1/builds

# array for filtering major version alone
declare -A mappedTags

# since tags is the target 
# in those REL is the one we go for release
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

# echo "-----------------------------------------------------------------------------"
# echo "${selectedMajorVersionTags[@]}" # always refer arrays using ${var[@]}

# TODO : group minor version also
select version in ${selectedMajorVersionTags[@]}; do 
    echo $version
    break
done

# switch to a different tag in the source code
git -C $postgres_source_directory checkout $version

echo "Switched to version $version"