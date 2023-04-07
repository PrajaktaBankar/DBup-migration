create table ProjectDefaultPrivacySetting(
Id int identity(1,1),
CustomerId int NOT NULL,
ProjectAccessTypeId int NOT NULL,
ProjectOwnerTypeId int NOT NULL, 
ProjectOriginTypeId int NOT NULL,
IsOfficeMaster bit NOT NULL,
CreatedBy Int NULL,
CreatedDate DATETIME2 NULL,
ModifiedBy Int NULL,
ModifiedDate DateTime2 NULL,
CONSTRAINT [PK_ProjectDefaultPrivacySetting] PRIMARY KEY CLUSTERED ([Id] ASC),
CONSTRAINT [FK_ProjectDefaultPrivacySetting_LuProjectAccessType] FOREIGN KEY (ProjectAccessTypeId) REFERENCES LuProjectAccessType(ProjectAccessTypeId),
CONSTRAINT [FK_ProjectDefaultPrivacySetting_LuProjectOwnerType]FOREIGN KEY (ProjectOwnerTypeId) REFERENCES LuProjectOwnerType(ProjectOwnerTypeId),
CONSTRAINT [FK_ProjectDefaultPrivacySetting_LuProjectOriginType] FOREIGN KEY (ProjectOriginTypeId) REFERENCES LuProjectOriginType(ProjectOriginTypeId)
)

