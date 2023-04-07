CREATE TABLE [dbo].[ProjectTransferGlobalDataAuditLog](
	[GlobaDataAuditLogId] [int] IDENTITY(1,1) NOT NULL,
	[SourceCustomerId] [int] NOT NULL,
	[SourceProjectId] [int] NOT NULL,
	[SourceServerId] [int] NOT NULL,
	[TargetCustomerId] [int] NOT NULL,
	[TargetProjectId] [int] NULL,
	[TargetServerId] [int] NOT NULL,
	[ItemTypeId] [int] NOT NULL,
	[SourceItemId] [int] NOT NULL,
	[SourceDescription] [nvarchar](500) NOT NULL,
	[TargetItemId] [int] NOT NULL,
	[TargetDescription] [nvarchar](500) NOT NULL,
	[CreatedDate] [datetime] NULL,
	[RequestId] [int] NOT NULL,
 CONSTRAINT [PK_ProjectTransferGlobalDataAuditLog] PRIMARY KEY CLUSTERED 
(
	[GlobaDataAuditLogId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO


