# Task 1

## Task 1.1 - Installation of postgres
- Install postgres from source (1.1)


- Clone the repo
```sh
    git clone https://github.com/postgres/postgres.git
```

- Initialize and configure the installation proces
```sh
    cd postgres
    ./configure
```

- It will throw errors for not found pacakges install them
```sh
    sudo apt install -y libicu-dev bison flex libreadline-dev zlib1g-dev
    # These pacakages where not available for me
```
- Install

```sh
    sudo make install
    # installs in /usr/local/bin/pgsql
```
- Setup pgsql
```sh
    /usr/local/bin/pgsql/initdb -D your_pg_directory
    /usr/local/bin/pgsql/pg_ctl -D your_pg_directory -l your_log_file_directory start
    /usr/local/bin/pgsql/createdb your_db_name
    /usr/local/bin/pgsql/psql your_created_db_name
```

## Task 1.2
- write a script to automate the installation process
- Should be able to give a version (tag name) and corressponding tag should be installed 
- Should check whether its already installed and prompt the user to ask to leave it or overwrite it
- Write an alias to run the pgsql that's been installed

- `build_postgres.sh` 
    - builds the source.
    - source is declared as current directory 
        - to modify change the `postgres_source_directory`
    - build directory is  `~/Documents/build`
        - to modify change the `targetParentDirectory`
    - initializes the directories needed like data directory
- `start.sh`
    - checks whether already pg is running 
    - if not then starts the server 
    - then asks the user for a database name
    - sets a alias in .bashrc for us
    - then we can call pgsql 'dbname' to run pgsql
    - before that we need to source our .bashrc file (because every script runs in a subshell meaning its sourced in that session(shell) so to source it completely to entire system we have to source it mannualy)
