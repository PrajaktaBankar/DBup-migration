IF NOT EXISTS (SELECT TOP 1
		*
	FROM ProjectPrintSetting
	WHERE ProjectId IS NULL)
BEGIN
INSERT INTO [dbo].[ProjectPrintSetting] (ProjectId, CustomerId, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsExportInMultipleFiles,
IsBeginSectionOnOddPage, IsIncludeAuthorInFileName, TCPrintModeId)
	SELECT
		NULL AS ProjectId
	   ,NULL AS CustomerId
	   ,NULL AS CreatedBy
	   ,NULL AS CreateDate
	   ,NULL AS ModifiedBy
	   ,NULL AS ModifiedDate
	   ,CAST(0 AS BIT) AS IsExportInMultipleFiles
	   ,CAST(0 AS BIT) AS IsBeginSectionOnOddPage
	   ,CAST(1 AS BIT) AS IsIncludeAuthorInFileName
	   ,CAST(3 AS INT) AS TCPrintModeId;
END
ELSE
BEGIN
UPDATE ProjectPrintSetting
SET IsExportInMultipleFiles = 0
   ,IsBeginSectionOnOddPage = 0
WHERE ProjectId IS NULL
AND CustomerId IS NULL;
END