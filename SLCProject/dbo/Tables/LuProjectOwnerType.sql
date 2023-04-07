create table LuProjectOwnerType(
ProjectOwnerTypeId int identity(1,1),
[Name] nvarchar(100) NOT NULL,
[Description] nvarchar(100) NULL,
IsActive bit NOT NULL,
SortOrder int NOT NULL,
CONSTRAINT [PK_LUPROJECTOWNERTYPE] PRIMARY KEY CLUSTERED ([ProjectOwnerTypeId] ASC)
)