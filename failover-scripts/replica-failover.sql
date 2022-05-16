-- Script to update all replicas to new replica.
STOP REPLICA IO_THREAD;
-- SHOW PROCESSLIST until you see Has read all relay log.

-- Update other replicas to new master
STOP REPLICA;
CHANGE MASTER TO
MASTER_HOST = '172.17.0.1',
MASTER_PORT = 3307,
MASTER_USER = '',
MASTER_PASSWORD = '',
MASTER_AUTO_POSITION = 1; 
START REPLICA USER='' PASSWORD='';