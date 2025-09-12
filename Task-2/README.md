# Task 2
- Need to create a master node and a slave node
- create a user with the ability to perform replication to the slave node
- Perform backup from master to slave
- Start the wal logs streaming to the slave node
- Validate the working of the replication

## Steps to complete
- We can use `initdb` to create multiple data directory file
- First create two directories
- Then use `pg_ctl` to start the server with a specific port 
- after starting the master server create a user with replication flag
- After that specify the rule in the pg_hba.conf and restart the primary server
- Then create another node (slave) using `pg_basebackup` with specifying the directory
- Then start the server using `pg_ctl` with specific port

## Automate failover and recovery
- Use `pg_isready` to check the status of the server
- for every 500ms run `pg_isready` for primary and standby
- when primary is down promote the standby and assign a standby for the new primary
- when standby is down create another new standby and assign to primary