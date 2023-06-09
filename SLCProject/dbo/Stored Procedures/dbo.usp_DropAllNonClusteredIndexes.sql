CREATE PROCEDURE [dbo].[usp_DropAllNonClusteredIndexes]
AS
BEGIN

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_LuCity_StateProvinceId')
Drop index CIX_LuCity_StateProvinceId ON LuCity

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'ProjectChoiceOption_ProjectId_SectionId_CustomerId')
DROP index ProjectChoiceOption_ProjectId_SectionId_CustomerId ON ProjectChoiceOption

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectChoiceOption_ChoiceOptionCode')
Drop index CIX_ProjectChoiceOption_ChoiceOptionCode ON  ProjectChoiceOption

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectChoiceOption_SegmentChoiceId')
Drop index CIX_ProjectChoiceOption_SegmentChoiceId ON ProjectChoiceOption

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSection_ProjectId_CustomerId')
DROP index CIX_ProjectSection_ProjectId_CustomerId ON ProjectSection

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'ProjectSection_ProjectId_CustomerId')
Drop index ProjectSection_ProjectId_CustomerId ON ProjectSection

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSection_ProjectId_CustomerId_LockedBy')
Drop index CIX_ProjectSection_ProjectId_CustomerId_LockedBy ON ProjectSection

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSection_ProjectId_CustomerId_SectionCode')
Drop index CIX_ProjectSection_ProjectId_CustomerId_SectionCode ON ProjectSection

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSegment_SegmentStatusId')
Drop index CIX_ProjectSegment_SegmentStatusId ON ProjectSegment

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSegmentChoice_SectionId_ProjectId_CustomerId')
Drop index CIX_ProjectSegmentChoice_SectionId_ProjectId_CustomerId ON ProjectSegmentChoice

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSegmentStatus_ProjectId_CustomerId')
Drop index CIX_ProjectSegmentStatus_ProjectId_CustomerId ON ProjectSegmentStatus

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSegmentStatus_SegmentStatusTypeId')
Drop index CIX_ProjectSegmentStatus_SegmentStatusTypeId ON ProjectSegmentStatus

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'CIX_ProjectSegmentStatus_SectionId_ProjectId_CustomerId')
Drop index CIX_ProjectSegmentStatus_SectionId_ProjectId_CustomerId ON ProjectSegmentStatus

IF  EXISTS (SELECT * FROM sys.indexes WHERE name = 'ProjectSegmentStatus_All')
Drop index ProjectSegmentStatus_All ON ProjectSegmentStatus
End
GO
