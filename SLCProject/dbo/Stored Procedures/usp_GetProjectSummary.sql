CREATE PROCEDURE usp_GetProjectSummary
(  
 @ProjectId INT  
)  
AS  
BEGIN  
SET NOCOUNT ON    
   SELECT   
   PS.ProjectId,    
   PS.IsIncludeRsInSection,    
   PS.IsIncludeReInSection,    
   ISNULL(PS.IsPrintReferenceEditionDate, 0) AS IsPrintReferenceEditionDate    
   FROM ProjectSummary PS WITH (NOLOCK)    
   WHERE PS.ProjectId = @ProjectId;

	DECLARE @DateFormat NVARCHAR(50) = NULL,@TimeFormat NVARCHAR(50) = NULL;
	DECLARE @MasterDataTypeId INT = (SELECT TOP 1 MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @ProjectId);

	SELECT @DateFormat = [DateFormat], @TimeFormat = [ClockFormat]
	FROM ProjectDateFormat WITH(NOLOCK)
	WHERE ProjectId = @ProjectId;

	IF (@DateFormat IS NULL)
	BEGIN
		SELECT TOP 1 @DateFormat = [DateFormat], @TimeFormat = [ClockFormat] 
		FROM ProjectDateFormat WITH(NOLOCK) 
		WHERE MasterDataTypeId = @MasterDataTypeId AND ProjectId IS NULL AND CustomerId IS NULL AND UserId IS NULL;
	END

	SELECT @DateFormat AS [DateFormat], @TimeFormat AS ClockFormat;

END