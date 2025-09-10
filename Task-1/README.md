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

#### The script:
- There are some predefined variables like postgres location and build directory
- It first requests the user to select a major version
- Then again the corressponding tags for Release is listed to select
- After selection a pre built exist in the declared directory then prompts the user to overwrite or not 
- If needed to overwrite then the server is stopped and then its built from the source
- Then after installing and setup aliases are set in the .bashrc file based on the version selected 
ex:`pgsql_16_0` for version `REL_16_0`
- We are responsible for sourcing the file to be able to use path.