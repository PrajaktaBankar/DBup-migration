USE [SLCProject]
GO

/****** Object:  Index [CIX_ProjectSegment_SegmentStatusId]    Script Date: 1/21/2020 1:43:04 AM ******/
DROP INDEX [CIX_ProjectSegment_SegmentStatusId] ON [dbo].[ProjectSegment]
GO

/****** Object:  Index [CIX_ProjectSegment_SegmentStatusId]    Script Date: 1/21/2020 1:43:04 AM ******/
CREATE NONCLUSTERED INDEX [CIX_ProjectSegment_SegmentStatusId] ON [dbo].[ProjectSegment]
(
	[SegmentStatusId] DESC,
	[SectionId] DESC,
	[ProjectId] DESC
)
INCLUDE ( 
	SegmentCode, Isdeleted
	)
WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 90) ON [PRIMARY]
GO
