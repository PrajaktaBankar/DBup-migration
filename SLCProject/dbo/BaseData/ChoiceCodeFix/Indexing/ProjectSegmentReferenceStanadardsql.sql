USE [SLCProject]
GO

/****** Object:  Index [NCI_ProjectId_SegmentId_RefStdCode]    Script Date: 1/22/2020 2:07:02 AM ******/
DROP INDEX [NCI_ProjectId_SegmentId_RefStdCode] ON [dbo].[ProjectSegmentReferenceStandard]
GO

/****** Object:  Index [NCI_ProjectId_SegmentId_RefStdCode]    Script Date: 1/22/2020 2:07:02 AM ******/
CREATE NONCLUSTERED INDEX [NCI_ProjectId_SegmentId_RefStdCode] ON [dbo].[ProjectSegmentReferenceStandard]
(
	[SegmentId] DESC,
	[ProjectId] DESC,
	[RefStdCode] DESC,
	[SectionId] DESC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO


