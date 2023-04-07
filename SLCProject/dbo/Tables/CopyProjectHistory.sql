CREATE TABLE [dbo].[CopyProjectHistory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NOT NULL,
	[StepName] [nvarchar](500) NULL,
	[Description] [nvarchar](500) NULL,
	[IsCompleted] [bit] NOT NULL,
	[CreatedDate] [datetime2](7) NULL,
	[Step] [int] NULL,
	[RequestId] [int] NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[CopyProjectHistory] ADD  DEFAULT ((0)) FOR [IsCompleted]
GO

ALTER TABLE [dbo].[CopyProjectHistory]  WITH NOCHECK ADD  CONSTRAINT [FK_CopyProjectHistory_CopyProjectRequest] FOREIGN KEY([RequestId])
REFERENCES [dbo].[CopyProjectRequest] ([RequestId])
GO

ALTER TABLE [dbo].[CopyProjectHistory] CHECK CONSTRAINT [FK_CopyProjectHistory_CopyProjectRequest]
GO

CREATE NONCLUSTERED INDEX [NCI_Step_RequestId]
    ON [dbo].[CopyProjectHistory]([Step] ASC, [RequestId] ASC, [CreatedDate] ASC) WITH (FILLFACTOR = 90);
GO

