#!/bin/bash
postgres_source_directory=$HOME/dev/ZohoTasks/Task-1/postgres

declare -A mappedTags

tags=$(git -C $postgres_source_directory tag | grep "^REL")


# This function creates map with major version as key and relavent versions as array for that key
# Now we can show only the major version and make them request it
maptags() {
    for tag in $@;
    do 
        clean=${tag#REL_}
        clean=${clean#REL}

        IFS='_' read -r major minor patch <<< "$clean"

        mappedTags[$major]+="$tag "
    done
}

selectTag() {
    echo "Select major version:"
    select major in "${!mappedTags[@]}"; do
        if [ -n "$major" ]; then
            echo "You selected major=${mappedTags[$major]}"
            break
        fi
    done
}




maptags ${tags[@]}
selectTag
