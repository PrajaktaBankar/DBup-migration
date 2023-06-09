CREATE Procedure [dbo].[RebuildIndexWeekly]
as
BEGIN
DECLARE @DATABASE NVARCHAR(50)
DECLARE @DbID SMALLINT=DB_ID(@Database)--Get Database ID
DECLARE @ReorgOptions varchar(300)
DECLARE @RebuildOptions varchar(300)
DECLARE @maxreorg decimal= 20.0
DECLARE @maxrebuild decimal  = 30.0
declare @TblName varchar(500) , @InxName varchar(500) , @IndexFrag float, @SchemaName VARCHAR(10);
declare @sql nvarchar(4000) 
declare @sql1 nvarchar(4000) 
DECLARE @StartTime AS DATETIME  --= getUTCdate()
SET @ReorgOptions = 'LOB_COMPACTION=ON'
select @DATABASE = DB_NAME() ;

SET @RebuildOptions = 'PAD_INDEX=OFF, SORT_IN_TEMPDB=OFF, STATISTICS_NORECOMPUTE=OFF, ALLOW_ROW_LOCKS=ON, ALLOW_PAGE_LOCKS=ON'
DECLARE @MaxIterator INT
DECLARE @Iterator INT ;
DECLARE @I TABLE (Iterator INT IDENTITY(1,1),SchemaName NVARCHAR(128),TableName NVARCHAR(128),IndexName NVARCHAR(128),IndexFrag FLOAT)
INSERT INTO @I
EXEC ('SELECT  S.name as SchemaName,
                T.name as TableName,
                I.name as IndexName,
                DDIPS.avg_fragmentation_in_percent IndexFrag
                FROM sys.dm_db_index_physical_stats (DB_ID(), NULL, NULL, NULL, NULL) AS DDIPS
                INNER JOIN sys.tables T on T.object_id = DDIPS.object_id
                INNER JOIN sys.schemas S on T.schema_id = S.schema_id
                INNER JOIN sys.indexes I ON I.object_id = DDIPS.object_id
                AND DDIPS.index_id = I.index_id
                WHERE DDIPS.database_id = DB_ID()
                AND I.name IS NOT NULL
                AND DDIPS.avg_fragmentation_in_percent > 20 
                AND S.name = ''dbo''
				AND I.name NOT LIKE ''%ux:%''
				AND T.object_id!= 2013067499
				AND I.index_id != 28
                ORDER BY DDIPS.avg_fragmentation_in_percent DESC')--Get index data and fragmentation, set the percentage as high or low as you need
select * from @I
SELECT @MaxIterator = MAX(Iterator), @Iterator = 1
FROM   @I;
WHILE @Iterator <= @MaxIterator
 BEGIN 

SELECT @TblName = tablename ,@InxName =IndexName , @IndexFrag=IndexFrag, @SchemaName = SchemaName
FROM   @I
WHERE  Iterator = @Iterator 

begin
if (@IndexFrag >= @maxrebuild )

BEGIN

SET @StartTime = getUTCdate()

INSERT INTO [UpdateStatisticsLog] (TableName,IndexName,StartTime,Jobtype) VALUES (@tblname,@InxName,@StartTime ,'REBUILD')

	SET @SQL = 'ALTER INDEX ' + @InxName + ' ON ' + @tblname + ' REBUILD WITH ( ' + @RebuildOptions + ' ) '
				
END
PRINT (@SQL)
EXEC (@SQL)
UPDATE [UpdateStatisticsLog]  SET EndTime = getUTCdate() 
WHERE EndTime is NULL and TableName = @tblname AND StartTime = @StartTime and IndexName=@InxName and Jobtype='REBUILD'

if (@IndexFrag >= @maxreorg )
BEGIN

SET @StartTime = getUTCdate()
INSERT INTO [UpdateStatisticsLog] (TableName,IndexName,StartTime,Jobtype) VALUES (@tblname,@InxName,@StartTime ,'REORGANIZE')

	SET @SQL = 'ALTER INDEX ' + @InxName + ' ON ' + @tblname + ' REORGANIZE WITH ( ' + @ReorgOptions + ' ) '
				
END
PRINT (@SQL)
EXEC (@SQL)
UPDATE [UpdateStatisticsLog]  SET EndTime = getUTCdate() 
WHERE EndTime is NULL and TableName = @tblname AND StartTime = @StartTime and IndexName=@InxName and Jobtype='REORGANIZE'

SET @Iterator  = @Iterator + 1;

END
END
END