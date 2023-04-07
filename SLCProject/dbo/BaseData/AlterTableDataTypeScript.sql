/*
Important Note : Please Read all instruction before execution.
1. Execute alter script one by one. Do not execute all script at one go.
2. Please check the log size after execution of every command. If log size is exceeds then you might get error and not allows you to alter the column.

*/
Use SLCProject
Go

Alter table dbo.[Project] alter column Description  nvarchar(500)

Alter table dbo.[Project] alter column GlobalProjectID  nvarchar(36)

Alter table dbo.[ProjectGlobalTerm] alter column GlobalTermSource  char(1)

Alter table dbo.[ProjectPaperSetting] alter column PaperOrientation  char(1)

Alter table dbo.[ProjectPaperSetting] alter column PaperSource  char(1)

Alter table dbo.[ProjectMigrationException] alter column SegmentSource char(1)

Alter table dbo.[ReferenceStandard] alter column RefStdName  nvarchar(100)

Alter table dbo.[ReferenceStandard] alter column RefStdSource  char(1)

Alter table dbo.[ReferenceStandard] alter column ReplaceRefStdSource  char(1)

Alter table dbo.[ReferenceStandardEdition] alter column RefEdition  nvarchar(150)

Alter table dbo.[ReferenceStandardEdition] alter column RefStdTitle  NVARCHAR (512)

Alter table dbo.[ReferenceStandardEdition] alter column [LinkTarget] NVARCHAR (512)

Alter table dbo.[LuSegmentLinkSourceType] alter column SegmentLinkSourceType  char(1)

Alter table dbo.[LuProjectImageSourceType] alter column ImageSourceType  varchar(50)

Alter table dbo.[LuProjectRequirementTagCategory] alter column CategoryName  char(1)

Alter table dbo.[LuProjectSectionIdSeparator] alter column Separator char(1)

Alter table dbo.[LuProjectSegmentStatusType] alter column StatusName  varchar(50)

Alter table dbo.[LuProjectSize] alter column SizeDescription  varchar(100)

Alter table dbo.[LuProjectTabType] alter column Description  varchar(100) not null

Alter table dbo.[LuProjectUoM] alter column Description  varchar(50)

Alter table dbo.[LuSectionIdSeparator] alter column Separator char(1)

Alter table dbo.[Template] alter column Name  varchar(100) not null

Alter table dbo.[ProjectSegment] alter column SegmentSource  char(1) -- time 2 min

Alter table dbo.[ProjectSegmentStatus] alter column SegmentSource  char(1) -- count 162576763 -- time 9:11 min
Alter table dbo.[ProjectSegmentStatus] alter column SegmentOrigin  char(2) -- count 162576763 -- time 7:25 min

Alter table dbo.[ProjectReferenceStandard] alter column RefStdSource  char(1) --count 3904824

Alter table dbo.[ProjectSegmentChoice] alter column SegmentChoiceSource  char(1) -- count 8581126 time 30 sec

Alter table dbo.[ProjectSegmentReferenceStandard] alter column RefStandardSource  char(1) -- count 2683070 11sec

/*
DROP INDEX dbo.[ProjectSection].ProjectSection_ProjectId_CustomerId;

Alter table dbo.[ProjectSection] alter column SourceTag  varchar(10)

CREATE NONCLUSTERED INDEX ProjectSection_ProjectId_CustomerId 
   ON dbo.[ProjectSection] (ProjectId, CustomerId)
*/

/*
ALTER TABLE dbo.[ProjectSummary] DROP CONSTRAINT DF__ProjectSu__Sourc__7D0E9093

Alter table dbo.[ProjectSummary] alter column SourceTagFormat  varchar(10) NOT NULL 

ALTER TABLE dbo.[ProjectSummary]
ADD CONSTRAINT DF__ProjectSu__Sourc__7D0E9093
DEFAULT '99 9999' FOR SourceTagFormat
*/



/*
Alter table dbo.[ProjectChoiceOption] alter column ChoiceOptionSource  char(1) -- count 22376329 Time - 1:53 min
*/
/*
DROP INDEX dbo.[SelectedChoiceOption].CSIx_SelectedChoiceOption_Include;
DROP INDEX dbo.[SelectedChoiceOption].CSIx_SelectedChoiceOption_Include_Id;

Alter table dbo.[SelectedChoiceOption] alter column ChoiceOptionSource  char(1) -- time 9:12 min


CREATE NONCLUSTERED INDEX [CSIx_SelectedChoiceOption_Include_Id]
    ON [dbo].[SelectedChoiceOption]([ChoiceOptionCode] ASC, [ProjectId] ASC, [CustomerId] ASC)
    INCLUDE([SegmentChoiceCode], [ChoiceOptionSource], [IsSelected]) WITH (FILLFACTOR = 90);
GO
   */