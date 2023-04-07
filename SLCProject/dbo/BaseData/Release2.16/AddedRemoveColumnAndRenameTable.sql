USE SLCProject

--Added column for FileNameFormatSetting table

ALTER TABLE FileNameFormatSetting
ADD CreatedBy INT;

ALTER TABLE FileNameFormatSetting
ADD CreatedDate DATETIME2;

ALTER TABLE FileNameFormatSetting
ADD ModifiedBy INT;

ALTER TABLE FileNameFormatSetting
ADD ModifiedDate DATETIME2;


--remove column for FileNameFormatProperties table

ALTER TABLE FileNameFormatProperties
DROP COLUMN ProjectId,CustomerId,CreatedBy,CreateDate,ModifiedBy,ModifiedDate;


---- FileNameFormatProperties table name rename as LuFileNamePlaceHolder 

EXEC sp_rename 'FileNameFormatProperties', 'LuFileNamePlaceHolder'; 

