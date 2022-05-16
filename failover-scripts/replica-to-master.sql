-- Script to swap replica-01 to master.
STOP REPLICA IO_THREAD;
-- SHOW PROCESSLIST until you see Has read all relay log.

-- Promote replica to master.
STOP REPLICA;
RESET MASTER;

-- Warning: You may have super-read-only or read-only 
-- enabled. Make sure to turn those off and restart the mysql service.
-- or else you won't be able to write to the new main db.