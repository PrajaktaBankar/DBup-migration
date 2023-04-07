CREATE FUNCTION [dbo].[fnGetSegmentDescriptionTextForRSAndGT_ForDataLoad]
(
	@segmentID bigint=null,
	@segmentDescription NVARCHAR(MAX),
	@projectID int =null
)	
RETURNS NVARCHAR(MAX)
AS	
BEGIN
	set @projectID=nullif(@projectID,0)
	SELECT @segmentDescription=REPLACE(@segmentDescription,
	CONCAT('{RS#',CONVERT(NVARCHAR(MAX),RefStdCode),'}'),RefStdName) FROM [SLCMaster].[dbo].[ReferenceStandard]  WITH (NOLOCK)
	--where IsObsolete=0
	
	SELECT @segmentDescription=REPLACE(@segmentDescription,
	CONCAT('{RS#',CONVERT(NVARCHAR(MAX),RefStdCode),'}'),RefStdName) FROM [ReferenceStandard]  WITH (NOLOCK)
	--where IsObsolete=0

	SELECT @segmentDescription= REPLACE(@segmentDescription,
	CONCAT('{GT#',CONVERT(NVARCHAR(MAX),GlobalTermCode),'}'),[Value])
	FROM ProjectGlobalTerm  WITH (NOLOCK)
	where projectId=iif(@projectID is null,projectID,@projectId)
	AND ISNULL(IsDeleted,0) = 0

	RETURN @segmentDescription;

END
GO


