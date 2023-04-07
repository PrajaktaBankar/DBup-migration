CREATE TABLE [dbo].[ImportProjectHistory](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NULL,
	[StepName] [nvarchar](500) NOT NULL,
	[Description] [nvarchar](500) NOT NULL,
	[IsCompleted] [bit] NULL,
	[CreatedDate] [datetime2](7) NOT NULL,
	[Step] [tinyint] NULL,
	[RequestId] [int] NOT NULL,
PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ImportProjectHistory]  WITH CHECK ADD FOREIGN KEY([RequestId])
REFERENCES [dbo].[ImportProjectRequest] ([RequestId])
GO


