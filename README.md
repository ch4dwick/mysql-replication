# MySQL Replication with newer Global Transaction Identifiers (GTID)

## Requirements:

- MySQL 8.x or higher.
- 1 Main DB
- N Replica DB

## Basic Main DB Config:

```
[mysqld]
# Must be unique for each instance even across networks.
server-id=1 
# DB to replicate. Comment out to replicate all dbs & tables.
#binlog_do_db=portal 
#binlog_format = row
# Uses newer GTID replication.
gtid-mode = ON 
enforce-gtid-consistency 
log-replica-updates
```

## All Replicas config

```
[mysqld]
server-id=2 # change with every replica
# DB to replicate
#binlog_do_db=portal

log-bin = mysql-bin
relay-log = relay-log-server
# Makes the replica read-only for both regular and super user.
read-only = ON
super-read-only = ON
gtid-mode = ON
enforce-gtid-consistency
log-replica-updates
```

## Create Replication-specific user (can be host specific):

```sql
CREATE USER 'replica_user'@'%' IDENTIFIED WITH mysql_native_password BY 'password'; 
GRANT REPLICATION SLAVE ON *.* TO 'replica_user'@'%'; 
FLUSH PRIVILEGES;
```

## Mandatory dump of main db:

Before dumping files, lock the database first. **DO NOT** close your mysql console or connection. It will unlock the tables. 

```bash
mysqldump --all-databases -flush-privileges --single-transaction --flush-logs --triggers --routines --events -hex-blob --host=x.x.x.x --port=3306 --user=root --password=XXXXXXXX > mysqlbackup_dump.sql
```

Optional: If your main db is currently used, execute the following to ensure all active transactions are completed/terminated and switch to read-only.

```sql
FLUSH TABLES WITH READ LOCK; 
```

## Copy dump file to replica instance OR execute remotely

```bash
mysql -h <remote replica> -u root -P 3306 -p < mysqlbackup_dump.sql 
```

### Optional
```sql
-- To retrieve master details (note file and position) 
-- Not needed when using GTID auto positioning below (MASTER_AUTO_POSITION) 
SHOW MASTER STATUS \G
```

## Configure replicas to source

```sql
CHANGE MASTER TO 
MASTER_HOST = 'x.x.x.x', 
MASTER_PORT = 3306, 
MASTER_USER = 'user', 
MASTER_PASSWORD = 'pass', 
MASTER_AUTO_POSITION = 1; 

START SLAVE USER='username' PASSWORD='password'; 
SHOW SLAVE STATUS \G
```

Execute this (if locked from earlier) on the main db.

```sql
UNLOCK TABLES; 
```

### Docker config (optional)

```bash
docker run --name main-db -p 3306:3306 -v /home/data/main:/var/lib/mysql -v master-my.cnf:/etc/mysql/conf.d/my.cnf -e MYSQL_ROOT_PASSWORD=pass --restart always -d mysql:latest 
 
docker run --name main-db-replica-01 -p 3306:3306 -v /home/data/replica-01:/var/lib/mysql -v replica-my.cnf:/etc/mysql/conf.d/my.cnf -e MYSQL_ROOT_PASSWORD=pass --restart always -d mysql:latest

# Optional 3rd replica
docker run --name main-db-replica-02 -p 3306:3306 -v /home/data/replica-02:/var/lib/mysql -v replica-my.cnf:/etc/mysql/conf.d/my.cnf -e MYSQL_ROOT_PASSWORD=pass --restart always -d mysql:latest 
```
