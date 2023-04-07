use SLCProject
GO

ALTER TABLE dbo.[Project] ALTER COLUMN [Description]  NVARCHAR(500)
GO

ALTER TABLE dbo.[Project] ALTER COLUMN GlobalProjectID  NVARCHAR(36)
GO

ALTER TABLE dbo.[ProjectGlobalTerm] ALTER COLUMN GlobalTermSource  CHAR(1)
GO

ALTER TABLE dbo.[ProjectPaperSetting] ALTER COLUMN PaperOrientation  CHAR(1)
GO

ALTER TABLE dbo.[ProjectPaperSetting] ALTER COLUMN PaperSource  CHAR(1)
GO

ALTER TABLE dbo.[ProjectMigrationException] ALTER COLUMN SegmentSource CHAR(1)
GO

ALTER TABLE dbo.[ReferenceStandard] ALTER COLUMN RefStdSource  CHAR(1)
GO

ALTER TABLE dbo.[ReferenceStandard] ALTER COLUMN ReplaceRefStdSource  CHAR(1)
GO

--ALTER TABLE dbo.[ReferenceStandard] ALTER COLUMN [IsDeleted] BIT DEFAULT ((0)) NOT NULL
--
ALTER TABLE dbo.[ReferenceStandardEdition] ALTER COLUMN RefEdition  NVARCHAR(150)
GO

ALTER TABLE dbo.[ReferenceStandardEdition] ALTER COLUMN RefStdTitle  NVARCHAR (512)
GO

ALTER TABLE dbo.[ReferenceStandardEdition] ALTER COLUMN [LinkTarget] NVARCHAR (512)
GO

ALTER TABLE dbo.[LuSegmentLinkSourceType] ALTER COLUMN SegmentLinkSourceType  CHAR(1)
GO

ALTER TABLE dbo.[LuProjectImageSourceType] ALTER COLUMN ImageSourceType  VARCHAR(50)
GO

ALTER TABLE dbo.[LuProjectRequirementTagCategory] ALTER COLUMN CategoryName  CHAR(1)
GO

ALTER TABLE dbo.[LuProjectSectionIdSeparator] ALTER COLUMN Separator CHAR(1)
GO

ALTER TABLE dbo.[LuProjectSegmentStatusType] ALTER COLUMN StatusName  VARCHAR(50)
GO

ALTER TABLE dbo.[LuProjectSize] ALTER COLUMN SizeDescription  VARCHAR(100)
GO

ALTER TABLE dbo.[LuProjectTabType] ALTER COLUMN [Description]  VARCHAR(100) NOT NULL
GO

ALTER TABLE dbo.[LuProjectUoM] ALTER COLUMN [Description]  VARCHAR(50)
GO

ALTER TABLE dbo.[LuSectionIdSeparator] ALTER COLUMN Separator CHAR(1)
GO

ALTER TABLE dbo.[Template] ALTER COLUMN [Name]  VARCHAR(100) NOT NULL
GO

ALTER TABLE dbo.[ProjectSegment] ALTER COLUMN SegmentSource  CHAR(1) 
GO
--
ALTER TABLE dbo.[ProjectSegmentStatus] ALTER COLUMN SegmentSource  CHAR(1)
GO

ALTER TABLE dbo.[ProjectSegmentStatus] ALTER COLUMN SegmentOrigin  CHAR(1)
GO

ALTER TABLE dbo.[ProjectReferenceStandard] ALTER COLUMN RefStdSource  CHAR(1) 
GO

ALTER TABLE dbo.[ProjectSegmentChoice] ALTER COLUMN SegmentChoiceSource  CHAR(1) 
GO

ALTER TABLE dbo.[ProjectSegmentReferenceStandard] ALTER COLUMN RefStandardSource  CHAR(1) -- count 2683070 11sec
GO

ALTER TABLE [ProjectChoiceOption] ALTER COLUMN [ChoiceOptionSource] CHAR (1)       NULL
GO

--ALTER TABLE [ProjectChoiceOption] ALTER COLUMN [Description] VARCHAR (100) NOT NULL
--GO

DROP INDEX [ProjectSection_ProjectId_CustomerId]
    ON [dbo].[ProjectSection];
GO

Alter table dbo.[ProjectSection] alter column [SourceTag]  VARCHAR (10) 
GO

--Moved to 6.Indexes.sql
--CREATE NONCLUSTERED INDEX [ProjectSection_ProjectId_CustomerId]
--    ON [dbo].[ProjectSection]([ProjectId] ASC, [CustomerId] ASC)
--    INCLUDE([ParentSectionId], [Description], [SourceTag], [Author], [SectionCode]);

ALTER TABLE [dbo].[ProjectSummary] DROP CONSTRAINT [DF__ProjectSu__Sourc__7D0E9093];
GO

ALTER TABLE dbo.[ProjectSummary] ALTER COLUMN [SourceTagFormat]  VARCHAR (10) NOT NULL
GO

ALTER TABLE [dbo].[ProjectSummary]
    ADD CONSTRAINT [DF__ProjectSu__Sourc__7D0E9093] DEFAULT ('99 9999') FOR [SourceTagFormat];
GO

--Alter table dbo.[ReferenceStandard] alter column [RefStdName]  NVARCHAR (100) 
--

DROP INDEX [CSIx_SelectedChoiceOption_Include]
    ON [dbo].[SelectedChoiceOption];
GO

DROP INDEX [CSIx_SelectedChoiceOption_Include_Id]
    ON [dbo].[SelectedChoiceOption];
GO

ALTER TABLE dbo.[SelectedChoiceOption] ALTER COLUMN [ChoiceOptionSource]     CHAR (1)       
GO
--Moved to 6.Indexes.sq;
--CREATE NONCLUSTERED INDEX [CSIx_SelectedChoiceOption_Include]
--    ON [dbo].[SelectedChoiceOption]([ProjectId] ASC, [CustomerId] ASC)
--    INCLUDE([SegmentChoiceCode], [ChoiceOptionCode], [ChoiceOptionSource], [IsSelected]);

	--Removed in  BaseData/AddIndex_SelectedChoiceOption.sql
--CREATE NONCLUSTERED INDEX [CSIx_SelectedChoiceOption_Include_Id]
--    ON [dbo].[SelectedChoiceOption]([ChoiceOptionCode] ASC, [ProjectId] ASC, [CustomerId] ASC)
--    INCLUDE([SegmentChoiceCode], [ChoiceOptionSource], [IsSelected]) WITH (FILLFACTOR = 90);


-- Discuss with Pandurang for data move
--ALTER TABLE [ProjectPageSetting] DROP COLUMN [IsStartOnOddPage]
--

