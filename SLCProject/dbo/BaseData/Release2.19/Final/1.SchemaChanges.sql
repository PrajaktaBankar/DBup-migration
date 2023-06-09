USE SLCProject
GO

IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'LuSpecSheetPaperSize'))
BEGIN
CREATE TABLE [LuSpecSheetPaperSize] (
[SpecSheetPaperId]  INT             IDENTITY (1, 1) NOT NULL,
[Description]       NVARCHAR(200)   NOT NULL,
[Name]              NVARCHAR(200)   NOT NULL,
[Width]             NVARCHAR(200)   NOT NULL,
[Height]             NVARCHAR(200)   NOT NULL,
[IsActive]          BIT             NOT NULL DEFAULT(1), 
[SortOrder]         INT             NOT NULL,
    CONSTRAINT [PK_LuSpecSheetPaperSize] PRIMARY KEY ([SpecSheetPaperId])
)
PRINT 'LuSpecSheetPaperSize table created successfully.';
END
ELSE
PRINT 'LuSpecSheetPaperSize table already exists.';


GO


IF (NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA = 'dbo' AND  TABLE_NAME = 'SheetSpecsPageSettings'))
BEGIN

CREATE TABLE [SheetSpecsPageSettings] (
[ProjectSheetSpecsId]			INT IDENTITY(1,1) NOT NULL,
[PaperSettingKey] INT NOT NULL,
[ProjectId]		INT NOT NULL,
[CustomerId]	INT NOT NULL,
[Name]			NVARCHAR(50) NOT NULL,
[Value]			NVARCHAR(MAX) NOT NULL,
[CreatedDate]	DATETIME2(7) NOT NULL,
[CreatedBy]		INT NOT NULL,
[ModifiedDate]	DATETIME2(7) NULL,
[ModifiedBy]	INT default NULL,
[IsActive]      BIT NULL,
[IsDeleted]     BIT NULL
CONSTRAINT [FK_SheetSpecsPageSettings_ProjectId] FOREIGN KEY ([ProjectId]) REFERENCES [Project] ([ProjectId]), 
CONSTRAINT [FK_SheetSpecsPageSettings_PaperSettingKey] FOREIGN KEY ([PaperSettingKey]) REFERENCES [LuSpecSheetPaperSize] ([SpecSheetPaperId]), 
CONSTRAINT [PK_SheetSpecsPageSettings] PRIMARY KEY ([ProjectSheetSpecsId]))

PRINT 'SheetSpecsPageSettings table created successfully.';
END
ELSE
PRINT 'SheetSpecsPageSettings table already exists.';


--------------------------------------------------------------------------
GO