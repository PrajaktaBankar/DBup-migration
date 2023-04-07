create table LuProjectOriginType
(
ProjectOriginTypeId int identity(1,1),
[Name] nvarchar(100),
[Description] nvarchar(100),
IsActive BIT,
CONSTRAINT [PK_LUPROJECTORIGINTYPE] PRIMARY KEY CLUSTERED ([ProjectOriginTypeId] ASC)
)