CREATE PROCEDURE [dbo].[usp_RebuildNonClusterdIndexes]
AS
SET NOCOUNT ON
BEGIN
ALTER INDEX ALL ON LuCity REBUILD
ALTER INDEX ALL ON ProjectChoiceOption REBUILD
ALTER INDEX ALL ON ProjectSection REBUILD
ALTER INDEX ALL ON ProjectSegment REBUILD
ALTER INDEX ALL ON ProjectSegmentChoice REBUILD
ALTER INDEX ALL ON ProjectSegmentStatus REBUILD
--ALTER INDEX ALL ON SegmentRequirementTag REBUILD

--Check Fragmentations level in %
SELECT distinct OBJECT_NAME(OBJECT_ID) as [TableName], index_type_desc,avg_fragmentation_in_percent [Total Fragmentation in %]
FROM sys.dm_db_index_physical_stats (DB_ID(N'SLCProject'), NULL, NULL, NULL , 'SAMPLED')
Where OBJECT_NAME(OBJECT_ID) in ('LuCity','ProjectChoiceOption','ProjectSection','ProjectSegment','ProjectSegmentChoice','ProjectSegmentStatus')
AND index_type_desc LIKE 'NONCLUSTERED INDEX'
ORDER BY avg_fragmentation_in_percent DESC
END
GO
