/** ****************************
*	CSC-621 Assignment 6 
*	Giannina Flamiano
***************************** */

/* **************************************************************************************** */
-- when set, it prevents potentially dangerous updates and deletes
set SQL_SAFE_UPDATES=0;

-- when set, it disables the enforcement of foreign key constraints.
set FOREIGN_KEY_CHECKS=0;

/* **************************************************************************************** 
-- These control:
--     the maximum time (in seconds) that the client will wait while trying to establish a 
	   connection to the MySQL server 
--     how long the client will wait for a response from the server once a request has 
       been sent over
**************************************************************************************** */
SHOW SESSION VARIABLES LIKE '%timeout%';       
SET GLOBAL mysqlx_connect_timeout = 600;
SET GLOBAL mysqlx_read_timeout = 600;

/* **************************************************************************************** */
-- The DB where the accounts table is created
use hw6;

/*************************************************************************************************
 *	1) Similar to what we did in class, use a stored procedure (generate_accounts) to create the 
 *	accounts table with the following columns:
 *		▪ account_num (Primary Key): 6-digit account number
 *		▪ branch_name: The branch name where the account is located.
 *		▪ balance: The balance of the account.
 *		▪ account_type: The type of the account (e.g., Checking, Savings).
 ************************************************************************************************/
CREATE TABLE accounts (
  account_num CHAR(6) PRIMARY KEY,    -- 6-digit account number (e.g., 00001, 00002, ...)
  branch_name VARCHAR(50),            -- Branch name (e.g., Brighton, Downtown, etc.)
  balance DECIMAL(10, 2),             -- Account balance, with two decimal places (e.g., 1000.50)
  account_type VARCHAR(50)            -- Type of the account (e.g., Savings, Checking)
);

/* *********************************************************************************************************
 * 	2) For timing analysis,  you will need to populate the table with 50,000, 100,000, and 150,000 records.
 *
 *	This procedure generates records for the accounts table using an input variable, num_records.
 *		account_num padded to 6 digits.
 * 		branch_name is randomly selected from one of the six predefined branches.
 *		balance is generated randomly, between 0 and 100,000, rounded to two decimal places.
 ******************************************************************************************************** */
-- Change delimiter to allow semicolons inside the procedure
DELIMITER $$

CREATE PROCEDURE generate_accounts(IN num_records INT)
BEGIN
  DECLARE i INT DEFAULT 1;
  DECLARE branch_name VARCHAR(50);
  DECLARE account_type VARCHAR(50);
  
  -- Loop to generate x account records
  WHILE i <= num_records DO
    -- Randomly select a branch from the list of branches
    SET branch_name = ELT(FLOOR(1 + (RAND() * 6)), 'Brighton', 'Downtown', 'Mianus', 'Perryridge', 'Redwood', 'RoundHill');
    
    -- Randomly select an account type
    SET account_type = ELT(FLOOR(1 + (RAND() * 2)), 'Savings', 'Checking');
    
    -- Insert account record
    INSERT INTO accounts (account_num, branch_name, balance, account_type)
    VALUES (
      LPAD(i, 6, '0'),                   -- Account number as just digits, padded to 6 digits (e.g., 00001, 00002, ...)
      branch_name,                       -- Randomly selected branch name
      ROUND((RAND() * 100000), 2),       -- Random balance between 0 and 100,000, rounded to 2 decimal places
      account_type                       -- Randomly selected account type (Savings/Checking)
    );

    SET i = i + 1;
  END WHILE;
END$$

-- Reset the delimiter back to the default semicolon
DELIMITER ;

CALL generate_accounts(50000); -- 50,000 records
CALL generate_accounts(100000); -- 100,000 records
CALL generate_accounts(150000); -- 150,000 records

SELECT COUNT(*) FROM accounts; -- Check number of records in account

/*********************************************************************************************************************
 *	3) Create indexes on the branch_name and account_type columns to optimize query performance. 
 * 	You should also experiment with creating indexes on other columns based on your chosen queries (e.g., balance).
 ********************************************************************************************************************/
CREATE INDEX idx_branch_name_account ON accounts(branch_name, `account`); -- Creating indexes on branch_name & account_type
DROP INDEX idx_branch_name_account ON accounts; -- Dropping indexes on branch_name & account_type

CREATE INDEX idx_branch_name_balance ON accounts(branch_name, balance); -- Creating indexes on branch_name & balance
DROP INDEX idx_branch_name_balance ON accounts; -- Dropping indexes on branch_name & balance

CREATE INDEX idx_account_type_balance ON accounts(account_type, balance); -- Creating indexes on account_type & balance
DROP INDEX idx_account_type_balance ON accounts; -- Dropping indexes on account_type & balance

/******************************************************************************************************************************
 *	4) You will compare point queries and range queries
 *****************************************************************************************************************************/
-- Point Query 1
SELECT COUNT(*) 
FROM accounts 
WHERE branch_name = 'Redwood' AND balance = 25000;

-- Range Query 1
SELECT COUNT(*) 
FROM accounts 
WHERE branch_name = 'Redwood' AND balance BETWEEN 10000 AND 25000;

-- Point Query 2
SELECT COUNT(*)
FROM accounts
WHERE account_type = 'Checking' AND balance = 50000;

-- Range Query 2
SELECT COUNT(*)
FROM accounts
WHERE account_type = 'Checking' AND balance BETWEEN 50000 AND 100000; 

/*******************************************************************************************************************************
 *	5) Experiment with the following dataset sizes: 50K, 100K, 150K
 *	6) For each dataset size, execute both point queries and range queries 10 times and record the execution time for each run.
 ******************************************************************************************************************************/
-- Step 1: Capture the start time with microsecond precision (6)
SET @start_time = NOW(6);

-- Step 2: Run the query you want to measure (copy & paste queries from above)
-- Range Query 2
SELECT COUNT(*)
FROM accounts
WHERE account_type = 'Checking' AND balance BETWEEN 50000 AND 100000; 

-- Step 3: Capture the end time with microsecond precision
SET @end_time = NOW(6);

-- Step 4: Calculate the difference in microseconds
SELECT 
    TIMESTAMPDIFF(MICROSECOND, @start_time, @end_time) AS execution_time_microseconds,
    TIMESTAMPDIFF(SECOND, @start_time, @end_time) AS execution_time_seconds;

/********************************************************************
 * 7) Create a stored procedure to measure average execution times
 *******************************************************************/
DELIMITER $$
CREATE PROCEDURE get_avg_execution_time(IN query_str VARCHAR(100))
BEGIN
    DECLARE i INT DEFAULT 1;
    DECLARE total_time BIGINT DEFAULT 0;
    DECLARE start_time DATETIME(6);
    DECLARE end_time DATETIME(6);
	
    SET @sqlq = query_str;
    PREPARE stmt FROM @sqlq;

    WHILE i <= 10 DO
        SET start_time = NOW(6);
        EXECUTE stmt;
        SET end_time = NOW(6);
        SET total_time = total_time + TIMESTAMPDIFF(MICROSECOND, start_time, end_time);
        SET i = i + 1;
    END WHILE;

    DEALLOCATE PREPARE stmt;

    SELECT total_time / 10 AS avg_execution_time;
END $$
DELIMITER ;

-- Point Query 1
CALL get_avg_execution_time("SELECT COUNT(*) FROM accounts WHERE branch_name = 'Redwood' AND balance = 25000");

-- Range Query 1
CALL get_avg_execution_time("SELECT COUNT(*) FROM accounts WHERE branch_name = 'Redwood' AND balance BETWEEN 10000 AND 25000");

-- Point Query 2
CALL get_avg_execution_time("SELECT COUNT(*) FROM accounts WHERE account_type = 'Checking' AND balance = 50000");

-- Range Query 2
CALL get_avg_execution_time("SELECT COUNT(*) FROM accounts WHERE account_type = 'Checking' AND balance BETWEEN 50000 AND 100000");
