# Task 1
- Install postgres from source
- write a script to automate an installation process
- Should be able to give a version (branch name) and corressponding branch should be installed 
- Should check whether its already installed and prompt the user to ask to leave it or overwrite it
- Write an alias to run the pgsql that's been installed


## Task 1.1 - Installation of postgres

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

## Task 2