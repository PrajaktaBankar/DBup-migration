DROP TABLE IF EXISTS  #CopyRequestTemp;

--insert copyrequest data into temp table
SELECT * INTO #CopyRequestTemp FROM 
[dbo].[CopyProjectRequest]

--drop existing copyrequest table
DROP TABLE [dbo].[CopyProjectRequest]
GO

CREATE TABLE [dbo].[CopyProjectRequest](
	[RequestId] [int] IDENTITY(1,1) NOT NULL,
	[SourceProjectId] [int] NULL,
	[TargetProjectId] [int] NULL,
	[CreatedById] [int] NULL,
	[CustomerId] [int] NULL,
	[CreatedDate] [datetime2](7) NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[StatusId] [int] NOT NULL,
	[IsNotify] [bit] NOT NULL,
	[CompletedPercentage] [float] NULL,
	[IsDeleted] [bit] NOT NULL,
	[IsEmailSent] [bit] NULL,
	[CustomerName] [nvarchar](200) NULL,
	[UserName] [nvarchar](200) NULL,
PRIMARY KEY CLUSTERED 
(
	[RequestId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[CopyProjectRequest] ADD  DEFAULT ((0)) FOR [IsNotify]
GO

ALTER TABLE [dbo].[CopyProjectRequest] ADD  DEFAULT ((0)) FOR [IsDeleted]
GO

ALTER TABLE [dbo].[CopyProjectRequest]  WITH NOCHECK ADD  CONSTRAINT [FK_CopyProjectRequest_LuCopyStatus] FOREIGN KEY([StatusId])
REFERENCES [dbo].[LuCopyStatus] ([CopyStatusId])
GO

ALTER TABLE [dbo].[CopyProjectRequest] CHECK CONSTRAINT [FK_CopyProjectRequest_LuCopyStatus]
GO

INSERT into [dbo].[CopyProjectRequest]
 (CPR.SourceProjectId
,CPR.TargetProjectId
,CPR.CreatedById
,CPR.CustomerId
,CPR.CreatedDate
,CPR.ModifiedDate
,CPR.StatusId
,CPR.IsNotify
,CPR.CompletedPercentage
,IsEmailSent
)
 SELECT
 CRT.SourceProjectId
,CRT.TargetProjectId
,CRT.CreatedById
,CRT.CustomerId
,CRT.CreatedDate
,CRT.ModifiedDate
,CRT.Status
,CRT.IsNotify
,CRT.CompletedPercentage
,1
FROM #CopyRequestTemp CRT


