
--Drop all old tables
DROP TABLE [dbo].[ProjectSegmentChoice_Old]
DROP TABLE [dbo].[ProjectSegment_Old]
DROP TABLE [dbo].[ProjectSegmentRequirementTag_Old]
DROP TABLE [dbo].[ProjectReferenceStandard_Old]
DROP TABLE [dbo].[ProjectChoiceOption_Old]
DROP TABLE [dbo].[ProjectSegmentStatus_Old]
DROP TABLE [dbo].[SelectedChoiceOption_Old]
DROP TABLE [dbo].[ProjectSegmentLink_Old]


--SELECT 
--   OBJECT_NAME(f.parent_object_id) TableName,
--   COL_NAME(fc.parent_object_id,fc.parent_column_id) ColName
--FROM 
--   sys.foreign_keys AS f
--INNER JOIN 
--   sys.foreign_key_columns AS fc 
--      ON f.OBJECT_ID = fc.constraint_object_id
--INNER JOIN 
--   sys.tables t 
--      ON t.OBJECT_ID = fc.referenced_object_id
--WHERE 
--   OBJECT_NAME (f.referenced_object_id) = 'ProjectSegmentStatus_Old'
