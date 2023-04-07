CREATE TABLE [dbo].[FileNameFormatSetting](
[Id] [int] Primary key IDENTITY(1,1) NOT NULL,
[FileFormatCategoryId] [int] NOT NULL,
[IncludeAutherSectionId] [bit] NULL,
[Separator] [nvarchar](2) NULL,
[FormatJsonWithPlaceHolder] [nvarchar](200) NULL,
[ProjectId] [int] NULL,
[CustomerId] [int] NULL,
[CreatedBy] INT NULL, 
    [CreatedDate] DATETIME2 NULL, 
    [ModifiedBy] INT NULL, 
    [ModifiedDate] DATETIME2 NULL, 
    FOREIGN KEY (FileFormatCategoryId) REFERENCES LuExportFileFormatCategory(Id),
FOREIGN KEY (ProjectId) REFERENCES project(ProjectId)
)
GO