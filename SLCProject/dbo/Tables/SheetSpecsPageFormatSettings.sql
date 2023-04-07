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
    CONSTRAINT [PK_SheetSpecsPageSettings] PRIMARY KEY ([ProjectSheetSpecsId])
)