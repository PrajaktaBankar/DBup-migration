--HANDLE LEGACY DATA FOR NEW TABLE ProjectPrintSetting
DECLARE @UserId INT = 1;

INSERT INTO ProjectPrintSetting (ProjectId, CustomerId, CreatedBy, CreateDate,
IsExportInMultipleFiles, IsBeginSectionOnOddPage, IsIncludeAuthorInFileName)
	SELECT
		X.*
	   ,Y.*
	FROM (SELECT DISTINCT
			PGE.ProjectId
		   ,PGE.CustomerId
		   ,@UserId AS CreatedBy
		   ,GETUTCDATE() AS CreateDate
		   ,PRN.IsExportInMultipleFiles
		   ,PRN.IsIncludeAuthorInFileName
		FROM ProjectPageSetting PGE
		INNER JOIN ProjectPrintSetting PRN
			ON PRN.ProjectId IS NULL
			AND PRN.CustomerId IS NULL
		LEFT JOIN ProjectPrintSetting PRN_TEMP
			ON PGE.ProjectId = PRN_TEMP.ProjectId
		WHERE PRN_TEMP.ProjectPrintSettingId IS NULL) AS X
	CROSS APPLY (SELECT TOP 1
			PGE.IsStartOnOddPage
		FROM ProjectPageSetting PGE
		WHERE PGE.ProjectId = X.ProjectId
		AND PGE.CustomerId = X.CustomerId
		ORDER BY PGE.ProjectPageSettingId DESC) AS Y
	ORDER BY X.ProjectId