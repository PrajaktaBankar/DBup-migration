
/****** Object:  Index [NCIX_ProjectSegmentLink_LinkEngineProcess]    Script Date: 6/10/2021 2:45:30 PM ******/
CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_LinkEngineProcess] ON [dbo].[ProjectSegmentLink]
(
	[ProjectId] ASC
	,[CustomerId] ASC
	,[TargetSectionCode] ASC
	,[TargetSegmentStatusCode] ASC
	,[TargetSegmentCode] ASC
	,[LinkTarget] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO


