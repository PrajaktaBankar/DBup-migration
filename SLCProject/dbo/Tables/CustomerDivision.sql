CREATE TABLE CustomerDivision(          
[DivisionId]		BIGINT IDENTITY(10000000,1),        
[DivisionCode]		NVARCHAR(100),
[DivisionTitle]		NVARCHAR(4000),
[IsActive]			BIT,         
[MasterDataTypeId]	INT,
[FormatTypeId]		INT,
[IsDeleted]			BIT,
[CustomerId]		INT,
[CreatedBy]			INT NULL, 
[CreatedDate]		DATETIME2 NULL, 
[ModifiedBy]		INT NULL, 
[ModifiedDate]		DATETIME2 NULL,
CONSTRAINT [PK_CustomerDivision] PRIMARY KEY CLUSTERED ([DivisionId] ASC),
CONSTRAINT [FK_CustomerDivision_LuMasterDataType] FOREIGN KEY (MasterDataTypeId) REFERENCES LuMasterDataType (MasterDataTypeId),
CONSTRAINT [FK_CustomerDivision_LuFormatType] FOREIGN KEY (FormatTypeId) REFERENCES LuFormatType (FormatTypeId)
)