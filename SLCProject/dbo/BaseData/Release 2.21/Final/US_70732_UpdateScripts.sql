
USE SLCProject
GO

UPDATE LuMasterDataType
SET Name='RIB Master (USA)',
Description='RIB Master (USA)'
WHERE MasterDataTypeId=1

UPDATE LuMasterDataType
SET Name='RIB Master (Canada)',
Description='RIB Master (Canada)'
WHERE MasterDataTypeId=4