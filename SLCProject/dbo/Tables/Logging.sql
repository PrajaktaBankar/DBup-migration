CREATE TABLE [dbo].[Logging](
	[LogID] [bigint] IDENTITY(1,1) NOT NULL,
	[ErrorCode] [int] NULL,
	[ErrorStep] [varchar](50) NOT NULL,
	[ErrorMessage] [nvarchar](1024) NULL,
	[Created] [datetime] NOT NULL,
	[CycleID] [bigint] NULL,
 CONSTRAINT [PK_Logging] PRIMARY KEY CLUSTERED 
(
	[LogID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO