
GO
ALTER TABLE Project
ADD LockedBy NVARCHAR(500) Default Null;

GO
ALTER TABLE Project
ADD LockedDate DATETIME2 Default Null;

GO
ALTER TABLE Project
ADD LockedById int Default Null;