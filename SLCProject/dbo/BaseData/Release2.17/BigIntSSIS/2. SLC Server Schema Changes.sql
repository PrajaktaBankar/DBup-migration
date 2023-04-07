

--Drop Indexes

DROP INDEX [CIX_ProjectSegmentStatus_ProjectId_CustomerId] ON [dbo].[ProjectSegmentStatus]
DROP INDEX [CIX_ProjectSegmentStatus_SectionId_ProjectId_CustomerId] ON [dbo].[ProjectSegmentStatus]
DROP INDEX [CIX_ProjectSegmentStatus_SegmentId_SectionId] ON [dbo].[ProjectSegmentStatus]
DROP INDEX [CIX_ProjectSegmentStatus_SegmentStatusTypeId] ON [dbo].[ProjectSegmentStatus]
DROP INDEX [IDX_ProjectSegmentStatus_ProjectId_CustomerId_SegmentStatusTypeId] ON [dbo].[ProjectSegmentStatus]
DROP INDEX [SIX_ProjectSegmentStatus_SegmentStatusCode_ProjectId_CustomerId] ON [dbo].[ProjectSegmentStatus]
DROP INDEX [IX_ProjectReferenceStandard_All_Required] ON [dbo].[ProjectReferenceStandard]
DROP INDEX [CIX_ProjectSegmentChoice_SectionId_ProjectId_CustomerId] ON [dbo].[ProjectSegmentChoice]
DROP INDEX [NCIX_ProjectSegmentChoice] ON [dbo].[ProjectSegmentChoice]
DROP INDEX [CIX_ProjectSegment_SegmentStatusId] ON [dbo].[ProjectSegment]
DROP INDEX [IX_ProjectSegmentRequirementTag_SectionId_SegmentStatusId_ProjectId] ON [dbo].[ProjectSegmentRequirementTag]
DROP INDEX [IX_PSRT_SegmentStatusId_RequirementTagId] ON [dbo].[ProjectSegmentRequirementTag]
DROP INDEX [NCIX_ProjectSegmentLink_CustomerId] ON [dbo].[ProjectSegmentLink]
DROP INDEX [NCIX_ProjectSegmentLink_ProjectId] ON [dbo].[ProjectSegmentLink]
DROP INDEX [NCIX_ProjectSegmentLink_SegmentLinkCode] ON [dbo].[ProjectSegmentLink]
DROP INDEX [NCIX_ProjectSegmentLink_SourceSectionCode_SourceSegmentStatusCode_LinkSource] ON [dbo].[ProjectSegmentLink]
DROP INDEX [NCIX_ProjectSegmentLink_TargetSectionCode_TargetSegmentStatusCode_LinkTarget] ON [dbo].[ProjectSegmentLink]
DROP INDEX [IX__ProjectHyperLink_ProjectId_SectionId_SegmentStatusId] ON [dbo].[ProjectHyperLink]
DROP INDEX [NCI_ProjectId_SegmentId_SectionId_SegmentStatusId] ON [dbo].[ProjectSegmentUserTag]
DROP INDEX [NCIx_ProjectNote_ProjectId] ON [dbo].[ProjectNote]
DROP INDEX [CIX_TrackSegmentStatusType_SegmentStatusId] ON [dbo].[TrackSegmentStatusType]
DROP INDEX [CIX_TrackSegmentStatusType_SegmentStatusId] ON [BsdLogging].[dbo].[TrackSegmentStatusTypeHistory]

------SegmentStatusId

--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectSegmentChoiceStaging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectSegmentStaging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentUserTag_Staging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentTab_Staging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentRequirementTag_Staging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentChoice_Staging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegment_Staging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectNote_Staging] ALTER COLUMN SegmentStatusId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectHyperLink_Staging] ALTER COLUMN SegmentStatusId BIGINT

--DROP CONSTRAINT
ALTER TABLE [dbo].[ProjectSegmentRequirementTag] DROP CONSTRAINT [FK_ProjectSegmentRequirementTag_ProjectSegmentStatus]
ALTER TABLE [dbo].[ProjectSegmentTab] DROP CONSTRAINT [FK_ProjectTab_ProjectSegmentStatus]
ALTER TABLE [dbo].[ProjectSegmentUserTag] DROP CONSTRAINT [FK_ProjectSegmentUserTag_ProjectSegmentStatus]
ALTER TABLE [dbo].[TrackSegmentStatusType] DROP CONSTRAINT [FK_SegmentStatusId]
ALTER TABLE [dbo].[ProjectHyperLink] DROP CONSTRAINT [FK_ProjectHyperLink_ProjectSegmentStatus]
ALTER TABLE [dbo].[ProjectMigrationException] DROP CONSTRAINT [FK_ProjectMigrationException_ProjectSegmentStatus]
ALTER TABLE [dbo].[ProjectNote] DROP CONSTRAINT [FK_ProjectNote_ProjectSegmentStatus]
ALTER TABLE [dbo].[ProjectSegment] DROP CONSTRAINT [FK_ProjectSegments_ProjectSegmentStatus]
ALTER TABLE [dbo].[ProjectSegmentChoice] DROP CONSTRAINT [FK_ProjectSegmentChoice_ProjectSegmentStatus]


--BigInt conversion
ALTER TABLE [BsdLogging].[dbo].[TrackSegmentStatusTypeHistory] ALTER COLUMN SegmentStatusId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectHyperLink] ALTER COLUMN SegmentStatusId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectMigrationException] ALTER COLUMN SegmentStatusId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectNote] ALTER COLUMN SegmentStatusId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectSegmentTab] ALTER COLUMN SegmentStatusId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectSegmentUserTag] ALTER COLUMN SegmentStatusId BIGINT
ALTER TABLE [SLCProject].[dbo].[SegmentComment] ALTER COLUMN SegmentStatusId BIGINT
ALTER TABLE [SLCProject].[dbo].[TrackSegmentStatusType] ALTER COLUMN SegmentStatusId BIGINT


EXEC sp_rename 'ProjectSegmentStatus', 'ProjectSegmentStatus_Old'

EXEC sp_rename 'ProjectSegmentStatus_BigInt', 'ProjectSegmentStatus'




--Create Foreign Key Constraint
ALTER TABLE [dbo].[ProjectSegmentTab]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectTab_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
GO
ALTER TABLE [dbo].[ProjectSegmentTab] CHECK CONSTRAINT [FK_ProjectTab_ProjectSegmentStatus]
GO


ALTER TABLE [dbo].[ProjectSegmentUserTag]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentUserTag_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
GO
ALTER TABLE [dbo].[ProjectSegmentUserTag] CHECK CONSTRAINT [FK_ProjectSegmentUserTag_ProjectSegmentStatus]
GO


ALTER TABLE [dbo].[TrackSegmentStatusType]  WITH NOCHECK ADD  CONSTRAINT [FK_SegmentStatusId_BigInt] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
GO
ALTER TABLE [dbo].[TrackSegmentStatusType] CHECK CONSTRAINT [FK_SegmentStatusId_BigInt]
GO


ALTER TABLE [dbo].[ProjectHyperLink]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectHyperLink_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
GO
ALTER TABLE [dbo].[ProjectHyperLink] CHECK CONSTRAINT [FK_ProjectHyperLink_ProjectSegmentStatus]
GO


ALTER TABLE [dbo].[ProjectMigrationException]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectMigrationException_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
GO
ALTER TABLE [dbo].[ProjectMigrationException] CHECK CONSTRAINT [FK_ProjectMigrationException_ProjectSegmentStatus]
GO


ALTER TABLE [dbo].[ProjectNote]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectNote_ProjectSegmentStatus] FOREIGN KEY([SegmentStatusId])
REFERENCES [dbo].[ProjectSegmentStatus] ([SegmentStatusId])
GO
ALTER TABLE [dbo].[ProjectNote] CHECK CONSTRAINT [FK_ProjectNote_ProjectSegmentStatus]
GO








------SegmentId

--BigInt conversion
ALTER TABLE [BPMCore_Staging_SLC].[dbo].[Stg_ProjectSegments_Cloud] ALTER COLUMN SegmentId BIGINT

--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectSegmentChoiceStaging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectSegmentStaging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentStatus_Staging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentReferenceStandard_Staging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentImage_Staging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentChoice_Staging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegment_Staging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentGlobalTerm_Staging] ALTER COLUMN SegmentId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectHyperLink_Staging] ALTER COLUMN SegmentId BIGINT


--DROP CONSTRAINT
ALTER TABLE [dbo].[ProjectMigrationException] DROP CONSTRAINT [FK_ProjectMigrationException_ProjectSegment]
ALTER TABLE [dbo].[ProjectSegmentChoice] DROP CONSTRAINT [FK_ProjectSegmentChoice_ProjectSegment]
ALTER TABLE [dbo].[ProjectSegmentTracking] DROP CONSTRAINT [FK_ProjectSegmentTrackChanges_ProjectSegments]
ALTER TABLE [dbo].[TrackProjectSegment] DROP CONSTRAINT [FK_TrackProjectSegment_ProjectSegments]


--Drop Index
DROP INDEX [IX_ProjectSegmentGlobalTerm_SegmentId_GlobalTermCode] ON [dbo].[ProjectSegmentGlobalTerm]
DROP INDEX [IX_ProjectSegmentImage_LuImageSourceTypeId_SegmentId] ON [dbo].[ProjectSegmentImage]
DROP INDEX [NCI_ProjectId_SegmentId_RefStdCode] ON [dbo].[ProjectSegmentReferenceStandard]


--BigInt conversion
ALTER TABLE [SLCProject].[dbo].[ProjectHyperLink] ALTER COLUMN SegmentId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectMigrationException] ALTER COLUMN SegmentId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectSegmentGlobalTerm] ALTER COLUMN SegmentId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectSegmentImage] ALTER COLUMN SegmentId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectSegmentReferenceStandard] ALTER COLUMN SegmentId BIGINT
ALTER TABLE [SLCProject].[dbo].[ProjectSegmentTracking] ALTER COLUMN SegmentId BIGINT
ALTER TABLE [SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory] ALTER COLUMN SegmentId BIGINT
ALTER TABLE [SLCProject].[dbo].[TrackProjectSegment] ALTER COLUMN SegmentId BIGINT


EXEC sp_rename 'ProjectSegment', 'ProjectSegment_Old'

EXEC sp_rename 'ProjectSegment_BigInt', 'ProjectSegment'



--Create Foreign Key Constraint
ALTER TABLE [dbo].[ProjectMigrationException]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectMigrationException_ProjectSegment] FOREIGN KEY([SegmentId])
REFERENCES [dbo].[ProjectSegment] ([SegmentId])
GO
ALTER TABLE [dbo].[ProjectMigrationException] CHECK CONSTRAINT [FK_ProjectMigrationException_ProjectSegment]
GO


ALTER TABLE [dbo].[ProjectSegmentTracking]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectSegmentTrackChanges_ProjectSegments] FOREIGN KEY([SegmentId])
REFERENCES [dbo].[ProjectSegment] ([SegmentId])
GO
ALTER TABLE [dbo].[ProjectSegmentTracking] CHECK CONSTRAINT [FK_ProjectSegmentTrackChanges_ProjectSegments]
GO


ALTER TABLE [dbo].[TrackProjectSegment]  WITH CHECK ADD  CONSTRAINT [FK_TrackProjectSegment_ProjectSegments] FOREIGN KEY([SegmentId])
REFERENCES [dbo].[ProjectSegment] ([SegmentId])
GO
ALTER TABLE [dbo].[TrackProjectSegment] CHECK CONSTRAINT [FK_TrackProjectSegment_ProjectSegments]
GO







------A_SegmentId


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegment_Staging] ALTER COLUMN A_SegmentId BIGINT



------SourceSegmentStatusCode


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN SourceSegmentStatusCode BIGINT



------TargetSegmentStatusCode


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN TargetSegmentStatusCode BIGINT



------SegmentStatusCode


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentStatus_Staging] ALTER COLUMN SegmentStatusCode BIGINT



------SegmentLinkCode


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN SegmentLinkCode BIGINT




------SegmentCode


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegment_Staging] ALTER COLUMN SegmentCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN SourceSegmentCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN TargetSegmentCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectSegmentStaging] ALTER COLUMN SegmentCode BIGINT

ALTER TABLE [SLCProject].[dbo].[ProjectMigrationException] ALTER COLUMN SegmentCode BIGINT



------ChoiceOptionCode


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectChoiceOption_Staging] ALTER COLUMN ChoiceOptionCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN SourceChoiceOptionCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN TargetChoiceOptionCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SelectedChoiceOption_Staging] ALTER COLUMN ChoiceOptionCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectChoiceOptionStaging] ALTER COLUMN ChoiceOptionCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCSelectedChoiceOptionStaging] ALTER COLUMN ChoiceOptionCode BIGINT



--Drop Index
DROP INDEX [CIX_ProjectChoiceOption_SegmentChoiceId] ON [dbo].[ProjectChoiceOption]
DROP INDEX [CIX_ProjectChoiceOption_ChoiceOptionCode] ON [dbo].[ProjectChoiceOption]
DROP INDEX [CIX_SelectedChoiceOption_New_ProjectId_CustomerId] ON [dbo].[SelectedChoiceOption]
DROP INDEX [CSIx_SelectedChoiceOption_New_Include_Id] ON [dbo].[SelectedChoiceOption]


--DROP CONSTRAINT
ALTER TABLE [dbo].[ProjectChoiceOption] DROP CONSTRAINT [Default_ProjectChoiceOption_ChoiceOptionCode]



EXEC sp_rename 'ProjectChoiceOption', 'ProjectChoiceOption_Old'

EXEC sp_rename 'ProjectChoiceOption_BigInt', 'ProjectChoiceOption'



EXEC sp_rename 'SelectedChoiceOption', 'SelectedChoiceOption_Old'

EXEC sp_rename 'SelectedChoiceOption_BigInt', 'SelectedChoiceOption'



--Create Foreign Key Constraint
ALTER TABLE [dbo].[ProjectChoiceOption] ADD  CONSTRAINT [Default_ProjectChoiceOption_ChoiceOptionCode]  DEFAULT (NEXT VALUE FOR [seq_ProjectChoiceOption]) FOR [ChoiceOptionCode]







------SegmentChoiceCode


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentChoice_Staging] ALTER COLUMN SegmentChoiceCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN SourceSegmentChoiceCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN TargetSegmentChoiceCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SelectedChoiceOption_Staging] ALTER COLUMN SegmentChoiceCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectSegmentChoiceStaging] ALTER COLUMN SegmentChoiceCode BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCSelectedChoiceOptionStaging] ALTER COLUMN SegmentChoiceCode BIGINT




------SegmentRequirementTagId


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentRequirementTag_Staging] ALTER COLUMN SegmentRequirementTagId BIGINT

EXEC sp_rename 'ProjectSegmentRequirementTag', 'ProjectSegmentRequirementTag_Old'

EXEC sp_rename 'ProjectSegmentRequirementTag_BigInt', 'ProjectSegmentRequirementTag'




------SegmentLinkId


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentLink_Staging] ALTER COLUMN SegmentLinkId BIGINT

EXEC sp_rename 'ProjectSegmentLink', 'ProjectSegmentLink_Old'

EXEC sp_rename 'ProjectSegmentLink_BigInt', 'ProjectSegmentLink'





------A_SegmentChoiceId


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentChoice_Staging] ALTER COLUMN A_SegmentChoiceId BIGINT




------SegmentChoiceId


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectSegmentChoice_Staging] ALTER COLUMN SegmentChoiceId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[SLCProjectChoiceOptionStaging] ALTER COLUMN SegmentChoiceId BIGINT
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectChoiceOption_Staging] ALTER COLUMN SegmentChoiceId BIGINT



EXEC sp_rename 'ProjectSegmentChoice', 'ProjectSegmentChoice_Old'

EXEC sp_rename 'ProjectSegmentChoice_BigInt', 'ProjectSegmentChoice'




--Create Foreign Key Constraint
ALTER TABLE [dbo].[ProjectChoiceOption]  WITH NOCHECK ADD  CONSTRAINT [FK_ProjectChoiceOption_BigInt_ProjectSegmentChoice] FOREIGN KEY([SegmentChoiceId])
REFERENCES [dbo].[ProjectSegmentChoice] ([SegmentChoiceId])
GO

ALTER TABLE [dbo].[ProjectChoiceOption] CHECK CONSTRAINT [FK_ProjectChoiceOption_BigInt_ProjectSegmentChoice]
GO



------ProjRefStdId


--BigInt conversion
--ALTER TABLE [DE_Projects_Staging].[dbo].[ProjectReferenceStandard_Staging] ALTER COLUMN ProjRefStdId BIGINT


EXEC sp_rename 'ProjectReferenceStandard', 'ProjectReferenceStandard_Old'

EXEC sp_rename 'ProjectReferenceStandard_BigInt', 'ProjectReferenceStandard'





------StatusID

ALTER TABLE [BPMCore_Staging_SLC].[dbo].[Stg_ProjectSegments_Cloud] ALTER COLUMN StatusID BIGINT



------ParentID

ALTER TABLE [BPMCore_Staging_SLC].[dbo].[Stg_ProjectSegments_Cloud] ALTER COLUMN ParentID BIGINT




--Drop Constraints from Old Tables
ALTER TABLE [dbo].[ProjectSegmentChoice_Old] DROP CONSTRAINT [Default_ProjectSegmentChoice_SegmentChoiceCode]
ALTER TABLE [dbo].[ProjectChoiceOption_Old] DROP CONSTRAINT [FK_ProjectChoiceOption_ProjectSegmentChoice]
ALTER TABLE [dbo].[ProjectSegment_Old] DROP CONSTRAINT [Default_ProjectSegment_SegmentCode]
ALTER TABLE [dbo].[ProjectSegment_Old] DROP CONSTRAINT [DF__ProjectSe__IsDel__1D314762]
ALTER TABLE [dbo].[ProjectSegmentStatus_Old] DROP CONSTRAINT [Default_ProjectSegmentStatus_SegmentStatusCode]
ALTER TABLE [dbo].[ProjectSegmentStatus_Old] DROP CONSTRAINT [DF__ProjectSe__IsPag__27AED5D5]
ALTER TABLE [dbo].[ProjectSegmentStatus_Old] DROP CONSTRAINT [DF__ProjectSe__IsRef__26BAB19C]
GO