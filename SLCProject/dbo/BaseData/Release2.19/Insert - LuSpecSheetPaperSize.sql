
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
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ARCH A: 9 in x 12 in', 'ARCH A: 9 in x 12 in', 12,9,1,1)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ARCH B: 12 in x 18 in', 'ARCH B: 12 in x 18 in', 18,12,1,2)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ARCH C: 18 in x 24 in', 'ARCH C: 18 in x 24 in', 24,18,1,3)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ARCH D: 24 in x 36 in', 'ARCH D: 24 in x 36 in', 36,24,1,4)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ARCH E: 36 in x 48 in', 'ARCH E: 36 in x 48 in', 48,36,1,5)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ANSI A: 8.5 in x 11 in', 'ANSI A: 8.5 in x 11 in', 11,8.5,1,6)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ANSI B: 11 in x 17 in', 'ANSI B: 11 in x 17 in', 17,11,1,7)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ANSI C: 17 in x 22 in', 'ANSI C: 17 in x 22 in', 22,17,1,8)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ANSI D: 22 in x 34 in', 'ANSI D: 22 in x 34 in', 34,22,1,9)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('ANSI E: 34 in x 44 in', 'ANSI E: 34 in x 44 in', 44,34,1,10)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('22 in x 30 in', '22 in x 30 in', 30,22,1,11)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('32 in x 40 in', '32 in x 40 in', 40,32,1,12)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('30 in x 42 in', '30 in x 42 in', 42,30,1,13)
INSERT INTO LuSpecSheetPaperSize ([Description],[Name],[Width],[Height],[IsActive],[SortOrder]) VALUES ('Custom','Custom',0,0,1,14)

-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
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
CONSTRAINT [PK_SheetSpecsPageSettings] PRIMARY KEY ([ProjectSheetSpecsId])
)