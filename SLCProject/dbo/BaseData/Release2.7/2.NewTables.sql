CREATE TABLE [dbo].[LuHeaderFooterDocumentType](
	[DocumentTypeId] [int] IDENTITY(1,1) NOT NULL,
	[DocumentTypeName] [nvarchar](100) NULL,
PRIMARY KEY CLUSTERED 
(
	[DocumentTypeId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 80) ON [PRIMARY]
) ON [PRIMARY]
GO

CREATE TABLE LuProjectAccessType
(
ProjectAccessTypeId  INT IDENTITY(1,1),
[Name] NVARCHAR(100) NOT NULL,
[Description] NVARCHAR(500) NULL,
IsActive BIT NOT NULL
 CONSTRAINT [PK_LuProjectAccessType] PRIMARY KEY CLUSTERED 
(
	ProjectAccessTypeId ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

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

CREATE TABLE [dbo].[ProjectPrintSetting](
	[ProjectPrintSettingId] [int] IDENTITY(1,1) NOT NULL,
	[ProjectId] [int] NULL,
	[CustomerId] [int] NULL,
	[CreatedBy] [int] NULL,
	[CreateDate] [datetime2](7) NULL,
	[ModifiedBy] [int] NULL,
	[ModifiedDate] [datetime2](7) NULL,
	[IsExportInMultipleFiles] [bit] NOT NULL,
	[IsBeginSectionOnOddPage] [bit] NOT NULL,
	[IsIncludeAuthorInFileName] [bit] NOT NULL,
	[TCPrintModeId] [int] NOT NULL,
 CONSTRAINT [PK_ProjectPrintSetting] PRIMARY KEY CLUSTERED 
(
	[ProjectPrintSettingId] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]
GO

ALTER TABLE [dbo].[ProjectPrintSetting] ADD  DEFAULT ((1)) FOR [IsExportInMultipleFiles]
GO

ALTER TABLE [dbo].[ProjectPrintSetting] ADD  DEFAULT ((1)) FOR [IsBeginSectionOnOddPage]
GO

ALTER TABLE [dbo].[ProjectPrintSetting] ADD  DEFAULT ((1)) FOR [IsIncludeAuthorInFileName]
GO

ALTER TABLE [dbo].[ProjectPrintSetting] ADD  DEFAULT ((1)) FOR [TCPrintModeId]
GO

ALTER TABLE [dbo].[ProjectPrintSetting]  WITH CHECK ADD  CONSTRAINT [FK_ProjectPrintSetting_LuTCPrintMode] FOREIGN KEY([TCPrintModeId])
REFERENCES [dbo].[LuTCPrintMode] ([TCPrintModeId])
GO

ALTER TABLE [dbo].[ProjectPrintSetting] CHECK CONSTRAINT [FK_ProjectPrintSetting_LuTCPrintMode]
GO

CREATE TABLE [dbo].[UserProjectAccessMapping] (
    [MappingId]    INT           IDENTITY (1, 1) NOT NULL,
    [ProjectId]    INT           NOT NULL,
    [UserId]       INT           NOT NULL,
	[CustomerId]	INT			 NOT NULL,
    [CreatedBy]    INT           NULL,
    [CreateDate]   DATETIME2 (7) NULL,
    [ModifiedBy]   INT           NULL,
    [ModifiedDate] DATETIME2 (7) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1, 
    CONSTRAINT [PK_UserProjectAccessMapping] PRIMARY KEY CLUSTERED ([MappingId] ASC),
    CONSTRAINT [FK_UserProjectAccessMapping_Project] FOREIGN KEY ([ProjectId]) REFERENCES [dbo].[Project] ([ProjectId])
)
GO