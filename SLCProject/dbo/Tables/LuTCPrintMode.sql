CREATE TABLE [dbo].[LuTCPrintMode](
	[TCPrintModeId] [int] IDENTITY(1,1) NOT NULL,
	[Name] [nvarchar](100) NOT NULL,
	[Description] [nvarchar](100) NOT NULL,
	[CreatedBy] [int] NULL,
	[ModifiedBy] [int] NULL,
	[CreateDate] [datetime2](7) NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[IsActive] [bit] NOT NULL,
 CONSTRAINT [PK_LuTCPrintMode] PRIMARY KEY CLUSTERED 
(
	[TCPrintModeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[LuTCPrintMode] ADD  DEFAULT ((1)) FOR [IsActive]
GO