
USE SLCProject
GO

ALTER DATABASE SLCProject
SET RECOVERY SIMPLE
GO

DBCC SHRINKFILE (SLCProject_log, 1)
GO

--SelectedChoiceOption

DROP INDEX [CIX_SelectedChoiceOption_New_ProjectId_CustomerId] ON [dbo].[SelectedChoiceOption]

DROP INDEX [CSIx_SelectedChoiceOption_New_Include_Id] ON [dbo].[SelectedChoiceOption]


CREATE NONCLUSTERED INDEX [MergedIndex_NonClustered] ON [dbo].[SelectedChoiceOption]
(
[ProjectId] ASC, [CustomerId] ASC, [SectionId] ASC, [SegmentChoiceCode] ASC, [ChoiceOptionCode] ASC
)
INCLUDE([ChoiceOptionSource],[IsSelected],[IsDeleted]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]



--ProjectSegmentLink

DROP INDEX [NCIX_ProjectSegmentLink_SegmentLinkCode] ON [dbo].[ProjectSegmentLink]

DROP INDEX [NCIX_ProjectSegmentLink_CustomerId] ON [dbo].[ProjectSegmentLink]

DROP INDEX [NCIX_ProjectSegmentLink_SourceSectionCode_SourceSegmentStatusCode_LinkSource] ON [dbo].[ProjectSegmentLink]

DROP INDEX [NCIX_ProjectSegmentLink_TargetSectionCode_TargetSegmentStatusCode_LinkTarget] ON [dbo].[ProjectSegmentLink]


CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_SourceLinks] ON [dbo].[ProjectSegmentLink]
(
	[SourceSectionCode] ASC,
	[SourceSegmentStatusCode] ASC,
	[LinkSource] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]


CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_TargetLinks] ON [dbo].[ProjectSegmentLink]
(
	[TargetSectionCode] ASC,
	[TargetSegmentStatusCode] ASC,
	[LinkTarget] ASC	
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]




--ProjectSegmentChoice

DROP INDEX [CIX_ProjectSegmentChoice_SectionId_ProjectId_CustomerId] ON [dbo].[ProjectSegmentChoice]

CREATE NONCLUSTERED INDEX [CIX_ProjectSegmentChoice_ProjectId_CustomerId_SectionId] ON [dbo].[ProjectSegmentChoice]
(
	[ProjectId] ASC,
	[CustomerId] ASC,
	[SectionId] ASC,
	[SegmentChoiceCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



--ProjectSegmentRequirementTag

DROP INDEX [IX_ProjectSegmentRequirementTag_SectionId_SegmentStatusId_ProjectId] ON [dbo].[ProjectSegmentRequirementTag]
GO

CREATE NONCLUSTERED INDEX [IX_ProjectSegmentRequirementTag_ProjectId_SectionId_SegmentStatusId] ON [dbo].[ProjectSegmentRequirementTag]
(
	[ProjectId] ASC,
	[SectionId] ASC,
	[SegmentStatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



--ProjectSegmentReferenceStandard

DROP INDEX [NCI_ProjectId_SegmentId_RefStdCode] ON [dbo].[ProjectSegmentReferenceStandard]
GO

CREATE NONCLUSTERED INDEX [NCI_ProjectId_SegmentId_RefStdCode] ON [dbo].[ProjectSegmentReferenceStandard]
(
	[ProjectId] DESC,
	[SectionId] DESC,
	[SegmentId] DESC,
	[RefStdCode] DESC	
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



--ProjectSegmentGlobalTerm

DROP INDEX [IX_ProjectSegmentGlobalTerm_SegmentId_GlobalTermCode] ON [dbo].[ProjectSegmentGlobalTerm]
GO

/****** Object:  Index [IX_ProjectSegmentGlobalTerm_SegmentId_GlobalTermCode]    Script Date: 12/3/2021 1:58:00 PM ******/
CREATE NONCLUSTERED INDEX [IX_ProjectSegmentGlobalTerm_SegmentId_GlobalTermCode] ON [dbo].[ProjectSegmentGlobalTerm]
(
	[ProjectId] ASC,
	[SectionId] ASC,
	[SegmentId] ASC,
	[GlobalTermCode] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



--ProjectSegmentUserTag

DROP INDEX [NCI_ProjectId_SegmentId_SectionId_SegmentStatusId] ON [dbo].[ProjectSegmentUserTag]
GO

CREATE NONCLUSTERED INDEX [NCI_CustomerId_ProjectId_SectionId_SegmentStatusId] ON [dbo].[ProjectSegmentUserTag]
(
	[CustomerId] DESC,
	[ProjectId] DESC,
	[SectionId] DESC,
	[SegmentStatusId] DESC
)
INCLUDE([UserTagId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO




--ProjectSegmentStatus

DROP INDEX [CIX_ProjectSegmentStatus_SectionId_ProjectId_CustomerId] ON [dbo].[ProjectSegmentStatus]
GO

CREATE NONCLUSTERED INDEX [CIX_ProjectSegmentStatus_SectionId_ProjectId_CustomerId] ON [dbo].[ProjectSegmentStatus]
(
	[ProjectId] ASC,
	[SectionId] ASC,
	[CustomerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO




--ProjectSegment

DROP INDEX [CIX_ProjectSegment_SegmentStatusId] ON [dbo].[ProjectSegment]
GO

CREATE NONCLUSTERED INDEX [CIX_ProjectSegment_SegmentStatusId] ON [dbo].[ProjectSegment]
(
	[ProjectId] DESC,
	[SectionId] DESC,
	[SegmentStatusId] DESC
)
INCLUDE([SegmentCode],[IsDeleted]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO




--ProjectNoteImage

DROP INDEX [NCIx_ProjectNoteImage] ON [dbo].[ProjectNoteImage]
GO

CREATE NONCLUSTERED INDEX [NCIx_ProjectNoteImage] ON [dbo].[ProjectNoteImage]
(
	[ProjectId] ASC,
	[SectionId] ASC,
	[ImageId] ASC,
	[NoteId] ASC
)
INCLUDE([CustomerId]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO



DBCC SHRINKFILE (SLCProject_log, 1)
GO
ALTER DATABASE SLCProject
SET RECOVERY FULL


