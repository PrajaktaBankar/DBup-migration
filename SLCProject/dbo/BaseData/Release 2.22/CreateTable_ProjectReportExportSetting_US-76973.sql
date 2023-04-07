CREATE TABLE [dbo].[ProjectReportExportSetting](
	[ReportSettingId] [int] IDENTITY(1,1) NOT NULL,
	[CustomerId] [int] NOT NULL,
	[ProjectId] [int] NOT NULL,
	[CreatedBy] [int] NULL,
	[CreatedDate] [datetime2](7) NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[IsIncludeAuthor] [bit] NOT NULL,
	[IsIncludeParagraphText] [bit] NOT NULL,
	[IsDeleted] [bit] NOT NULL,
 CONSTRAINT [PK_ProjectReportExportSetting] PRIMARY KEY CLUSTERED 
(
	[ReportSettingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectReportExportSetting] ADD  CONSTRAINT [DF__ProjectRe__IsInc__4614442D]  DEFAULT ((1)) FOR [IsIncludeAuthor]
GO

ALTER TABLE [dbo].[ProjectReportExportSetting] ADD  CONSTRAINT [DF__ProjectRe__IsInc__47086866]  DEFAULT ((0)) FOR [IsIncludeParagraphText]
GO

ALTER TABLE [dbo].[ProjectReportExportSetting] ADD  CONSTRAINT [DF_ProjectReportExportSetting_IsDeleted]  DEFAULT ((0)) FOR [IsDeleted]
GO

CREATE NONCLUSTERED INDEX [IX_ProjectReportExportSetting_CustId] ON [dbo].[ProjectReportExportSetting]
(
	[CustomerId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

CREATE UNIQUE NONCLUSTERED INDEX [IX_ProjectReportExportSetting_ProjectId] ON [dbo].[ProjectReportExportSetting]
(
	[ProjectId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [PRIMARY]
GO

