CREATE FUNCTION [dbo].[fnGetSegmentDescriptionTextForGT]
(
	@ProjectId int,
	@CustomerId int,
	@segmentDescription NVARCHAR(MAX)
)
RETURNS NVARCHAR(MAX)
AS
BEGIN

	SELECT @segmentDescription= REPLACE(@segmentDescription,
	CONCAT('{GT#',CONVERT(NVARCHAR(MAX),GlobalTermCode),'}'),[Value])
	FROM [SLCMaster].[dbo].[GlobalTerm] with (nolock)

	SELECT @segmentDescription= REPLACE(@segmentDescription,
	CONCAT('{GT#',CONVERT(NVARCHAR(MAX),GlobalTermCode),'}'),[Value])
	FROM [SLCProject].[dbo].[ProjectGlobalTerm] with (nolock)
	 WHERE ProjectId=@ProjectId AND CustomerId=@CustomerId
	 AND ISNULL(IsDeleted,0) = 0
	

	RETURN @segmentDescription;

END
