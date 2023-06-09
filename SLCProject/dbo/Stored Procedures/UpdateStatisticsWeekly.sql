
CREATE PROCEDURE [dbo].[UpdateStatisticsWeekly]

AS
BEGIN
	SET NOCOUNT ON;
declare @tablename sysname  
declare @SchemaName Sysname  
declare @sql nvarchar(4000)  
DECLARE @StartTime AS DATETIME
DECLARE @MaxIterator INT
DECLARE @Iterator INT ;  
CREATE TABLE #StatisticTable ( Iterator INT IDENTITY(1, 1),tablename sysname ,SchemaName Sysname  );
   
INSERT INTO #StatisticTable ( Tablename , SchemaName  )
select TABLE_NAME as TableName, QUOTENAME(TABLE_SCHEMA) as SchemaName from INFORMATION_SCHEMA.TABLES where TABLE_TYPE='BASE TABLE'  ;

SELECT @MaxIterator = MAX(Iterator), @Iterator = 1
FROM   #StatisticTable;

WHILE @Iterator <= @MaxIterator
 BEGIN 
 
SELECT @tablename = tablename ,@SchemaName =SchemaName
FROM   #StatisticTable
WHERE  Iterator = @Iterator;
 

set @sql = 'UPDATE STATISTICS '+@SchemaName+ '.' + @tablename 
SET @StartTime = getUTCdate()
insert into  [UpdateStatisticsLog] (TableName,StartTime) values (@tablename,@StartTime )
print('insert Successfully')

exec sp_executesql @sql

set @sql = 'exec sp_recompile '''+@SchemaName+ '.' + @tablename + ''''
exec sp_executesql @sql

update  [UpdateStatisticsLog]  set EndTime = getUTCdate() where EndTime is NULL and TableName =@tablename AND StartTime= @StartTime 
print('Update Successfully')

SET @Iterator  = @Iterator + 1;  
 END;  
DROP TABLE [dbo].[#StatisticTable]; 

END



