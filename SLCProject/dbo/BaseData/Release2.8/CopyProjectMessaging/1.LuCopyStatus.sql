CREATE TABLE [dbo].[LuCopyStatus](
	[CopyStatusId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [varchar](50) NULL,
	[StatusDescription] [varchar](50) NULL,
 CONSTRAINT [PK_LuCopyStatus] PRIMARY KEY CLUSTERED 
(
	[CopyStatusId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

INSERT into  [dbo].[LuCopyStatus] VALUES('Queued','Queued')
INSERT into  [dbo].[LuCopyStatus] VALUES('InProgress','InProgress')
INSERT into  [dbo].[LuCopyStatus] VALUES('Completed','Completed')
INSERT into  [dbo].[LuCopyStatus] VALUES('Failed','Failed')
INSERT into  [dbo].[LuCopyStatus] VALUES('Aborted','Failed')
GO
