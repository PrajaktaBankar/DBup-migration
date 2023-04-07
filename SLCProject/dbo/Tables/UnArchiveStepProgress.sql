CREATE TABLE UnArchiveStepProgress(
	[UnArchiveStepProgressId] [bigint] IDENTITY(1,1) NOT NULL,
	[StepName] [nvarchar](100) NULL,
	[Description] [nvarchar](500) NULL,
	[IsCompleted] [bit] NOT NULL,
	[Step] [nvarchar](100) NULL,
	[OldCount] [int] NULL,
	[NewCount] [int] NULL,
	[CreatedDate] [datetime] NULL,
	RequestId INT NOT NULL,
 CONSTRAINT [PK_UnArchiveStepProgress] PRIMARY KEY CLUSTERED 
(
	[UnArchiveStepProgressId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE UnArchiveStepProgress  WITH NOCHECK ADD  CONSTRAINT [FK_UnArchiveStepProgress_RequestId] FOREIGN KEY(RequestId)
REFERENCES UnArchiveProjectRequest (RequestId)
GO