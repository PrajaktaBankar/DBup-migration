CREATE TABLE BIM360AccessKey
(
AccessKeyId INT IDENTITY(1,1) NOT NULL,
CustomerId INT NOT NULL,
ClientId nvarchar(255) NOT NULL,
ClientSecret nvarchar(255) NOT NULL,
IsActive BIT NOT NULL default 0,
CreatedDate datetime2 NOT NULL DEFAULT GETUTCDATE(),
CreatedBy int NOT NULL,
ModifiedDate datetime2 NULL,
ModifiedBy int NULL,
CONSTRAINT [PK_BIM360AccessKey] PRIMARY KEY CLUSTERED ([AccessKeyId] ASC)
)

