
-- set "Result to Text" mode by pressing Ctrl+T
SET NOCOUNT ON

DECLARE @sqlToRun VARCHAR(1000), @searchFor VARCHAR(100), @replaceWith VARCHAR(100)

-- text to search for
SET @searchFor = 'SLCProject..'
-- text to replace with
SET @replaceWith = ''

-- this will hold stored procedures text
DECLARE @temp TABLE (spText VARCHAR(MAX))

DECLARE curHelp CURSOR FAST_FORWARD
FOR
-- get text of all stored procedures that contain search string
-- I am using custom escape character here since i need to espape [ and ] in search string
SELECT DISTINCT 'sp_helptext '''+OBJECT_SCHEMA_NAME(id)+'.'+OBJECT_NAME(id)+''' ' 
FROM syscomments WHERE TEXT LIKE '%' + REPLACE(REPLACE(@searchFor,']','\]'),'[','\[') + '%' ESCAPE '\'
ORDER BY 'sp_helptext '''+OBJECT_SCHEMA_NAME(id)+'.'+OBJECT_NAME(id)+''' '

OPEN curHelp

FETCH next FROM curHelp INTO @sqlToRun

WHILE @@FETCH_STATUS = 0
BEGIN
   --insert stored procedure text into a temporary table
   INSERT INTO @temp
   EXEC (@sqlToRun)

   -- add GO after each stored procedure
   INSERT INTO @temp
   VALUES ('GO')

   FETCH next FROM curHelp INTO @sqlToRun
END

CLOSE curHelp
DEALLOCATE curHelp

-- find and replace search string in stored procedures 
-- also replace CREATE PROCEDURE with ALTER PROCEDURE
UPDATE @temp
SET spText = REPLACE(REPLACE(spText,'CREATE PROCEDURE', 'ALTER PROCEDURE'),@searchFor,@replaceWith)

SELECT spText FROM @temp
-- now copy and paste result into new window
-- then make sure everything looks good and run
GO