USE slcproject
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ApplyTitleStyleToEOS' AND Object_ID = Object_ID(N'[dbo].[Template]'))
BEGIN
	ALTER TABLE [dbo].[Template] ADD ApplyTitleStyleToEOS BIT DEFAULT ((0)) NULL ;
	
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'ImageStyle' AND Object_ID = Object_ID(N'[dbo].[ProjectSegmentImage]'))
BEGIN
	ALTER TABLE ProjectSegmentImage ADD  ImageStyle NVARCHAR(200) NULL;
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'KeepWithNext' AND Object_ID = Object_ID(N'[dbo].[ProjectPrintSetting]'))
BEGIN
	ALTER TABLE [ProjectPrintSetting] ADD [KeepWithNext] BIT DEFAULT ((1)) NOT NULL

END
GO


IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsShowLineAboveHeader' AND Object_ID = Object_ID(N'[dbo].[Header]'))
BEGIN
	ALTER TABLE [dbo].[Header] ADD IsShowLineAboveHeader bit DEFAULT 0 NOT NULL;
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsShowLineBelowHeader' AND Object_ID = Object_ID(N'[dbo].[Header]'))
BEGIN
	ALTER TABLE [dbo].[Header] ADD IsShowLineBelowHeader bit DEFAULT 0 NOT NULL;
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsShowLineAboveFooter' AND Object_ID = Object_ID(N'[dbo].[Footer]'))
BEGIN
	ALTER TABLE [dbo].[Footer] ADD IsShowLineAboveFooter bit DEFAULT 0 NOT NULL;
END
GO

IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsShowLineBelowFooter' AND Object_ID = Object_ID(N'[dbo].[Footer]'))
BEGIN
	ALTER TABLE [dbo].[Footer] ADD IsShowLineBelowFooter bit DEFAULT 0 NOT NULL;
END
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ImportProjectRequest'))
BEGIN
CREATE TABLE [dbo].[ImportProjectRequest] (
    [RequestId]           INT             IDENTITY (1, 1) NOT NULL,
    [SourceProjectId]     INT             NULL,
    [TargetProjectId]     INT             NOT NULL,
    [SourceSectionId]     INT             NULL,
    [TargetSectionId]     INT             NULL,
    [CreatedById]         INT             NOT NULL,
    [CustomerId]          INT             NOT NULL,
    [CreatedDate]         DATETIME2 (7)   NOT NULL,
    [ModifiedDate]        DATETIME2 (7)   NULL,
    [StatusId]            TINYINT         NULL,
    [CompletedPercentage] TINYINT         NOT NULL,
    [Source]              NVARCHAR (200)  NOT NULL,
    [IsNotify]            BIT             NULL,
    [DocumentFilePath]    NVARCHAR (1000) NULL,
    PRIMARY KEY CLUSTERED ([RequestId] ASC) ON [PRIMARY]
) ON [PRIMARY];

END
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'ImportProjectHistory'))
BEGIN

CREATE TABLE [dbo].[ImportProjectHistory] (
    [Id]          INT            IDENTITY (1, 1) NOT NULL,
    [ProjectId]   INT            NULL,
    [StepName]    NVARCHAR (500) NOT NULL,
    [Description] NVARCHAR (500) NOT NULL,
    [IsCompleted] BIT            NULL,
    [CreatedDate] DATETIME2 (7)  NOT NULL,
    [Step]        TINYINT        NULL,
    [RequestId]   INT            NOT NULL,
    PRIMARY KEY CLUSTERED ([Id] ASC) ON [PRIMARY],
    FOREIGN KEY ([RequestId]) REFERENCES [dbo].[ImportProjectRequest] ([RequestId])
) ON [PRIMARY];

END


UPDATE s   
SET IncludePrevious=0,HangingIndent=576
FROM Style s WITH (NOLOCK)
WHERE StyleId=40 AND [Name]='AIA Format Level 3'

-- For Level 2: The Text Position is set to .4, and needs to be changed to .6:
UPDATE s   
SET HangingIndent=864
FROM Style s WITH (NOLOCK)
WHERE StyleId=39 AND [Name] ='AIA Format Level 2'
GO

IF NOT EXISTS (SELECT 1 FROM LuProjectImageSourceType WHERE ImageSourceType = 'HeaderFooter')
BEGIN
	INSERT INTO LuProjectImageSourceType VALUES('HeaderFooter')
END
GO
IF NOT EXISTS(SELECT 1 FROM sys.columns WHERE Name = N'IsExternalExport' AND Object_ID = Object_ID(N'[dbo].[PrintRequestDetails]'))
BEGIN
	ALTER TABLE  PrintRequestDetails  ADD IsExternalExport BIT not null DEFAULT (0);
END
GO