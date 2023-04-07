
USE SLCProject
GO

ALTER DATABASE SLCProject
SET RECOVERY SIMPLE
GO

DBCC SHRINKFILE (SLCProject_log, 1)
GO

DROP INDEX [NCIX_ProjectSegmentLink_SourceLinks] ON [dbo].[ProjectSegmentLink]

DROP INDEX [NCIX_ProjectSegmentLink_TargetLinks] ON [dbo].[ProjectSegmentLink]


CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_SourceLinks] ON [dbo].[ProjectSegmentLink]
(
	[ProjectId] ASC,
	[SourceSectionCode] ASC,
	[SourceSegmentStatusCode] ASC,
	[LinkSource] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]


CREATE NONCLUSTERED INDEX [NCIX_ProjectSegmentLink_TargetLinks] ON [dbo].[ProjectSegmentLink]
(
	[ProjectId] ASC,
	[TargetSectionCode] ASC,
	[TargetSegmentStatusCode] ASC,
	[LinkTarget] ASC	
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]



DBCC SHRINKFILE (SLCProject_log, 1)
GO
ALTER DATABASE SLCProject
SET RECOVERY FULL
