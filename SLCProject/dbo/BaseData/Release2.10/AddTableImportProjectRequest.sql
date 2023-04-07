CREATE TABLE [dbo].[ImportProjectRequest](
	[RequestId] [int] IDENTITY(1,1) NOT NULL,
	[SourceProjectId] [int] NULL,
	[TargetProjectId] [int] NOT NULL,
	[SourceSectionId] [int] NULL,
	[TargetSectionId] [int] NULL,
	[CreatedById] [int] NOT NULL,
	[CustomerId] [int] NOT NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[StatusId] [tinyint] NULL,
	[CompletedPercentage] [tinyint] NOT NULL,
	[Source] [nvarchar](200) NOT NULL,
	[IsNotify] [bit] NULL,
	[DocumentFilePath] [nvarchar](1000) NULL,
PRIMARY KEY CLUSTERED 
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO


