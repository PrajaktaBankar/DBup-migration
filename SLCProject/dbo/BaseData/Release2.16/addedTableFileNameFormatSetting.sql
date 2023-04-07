
CREATE TABLE FileNameFormatSetting  (
Id INT primary key Identity(1,1) NOT NULL,
FileFormatCategoryId INT NOT NULL,
IncludeAutherSectionId BIT,
Separator NVARCHAR(2),
FormatJsonWithPlaceHolder NVARCHAR(200),
ProjectId INT,
CustomerId INT,
FOREIGN KEY (FileFormatCategoryId) REFERENCES LuExportFileFormatCategory(Id),
FOREIGN KEY (ProjectId) REFERENCES project(ProjectId)
);