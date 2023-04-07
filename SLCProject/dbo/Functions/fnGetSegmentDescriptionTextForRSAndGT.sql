CREATE FUNCTION [dbo].[fnGetSegmentDescriptionTextForRSAndGT]    
(    
 @ProjectId int,    
 @CustomerId int,    
 @segmentDescription NVARCHAR(MAX)    
)RETURNS NVARCHAR(MAX)    
AS    
BEGIN    
	IF(@segmentDescription like '%{RS#%')
	BEGIN
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{RS#', CONVERT(NVARCHAR(MAX), prs.RefStdCode), '}'), rs.RefStdName)    
		FROM [dbo].[ProjectReferenceStandard] prs WITH(NOLOCK)  Inner JOIN ReferenceStandard rs WITH(NOLOCK)  
		ON prs.RefStandardId=rs.RefStdId  
		WHERE prs.ProjectId=@ProjectId and prs.CustomerId=@CustomerId  
  
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{RS#', CONVERT(NVARCHAR(MAX), RefStdCode), '}'), RefStdName)    
		FROM [SLCMaster].[dbo].[ReferenceStandard] WITH(NOLOCK)    
    END 
	IF @segmentDescription LIKE '%{RSTEMP#%'    
	BEGIN    
		  DECLARE @RSCode INT = 0;    
		  SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)     
		  FROM (SELECT SUBSTRING(@segmentDescription, PATINDEX('%[0-9]%', @segmentDescription), LEN(@segmentDescription)) Val) RSCode    
    
		  SELECT @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
		  FROM (SELECT TOP 1    
			   RSE.RefStdTitle    
			  ,RSE.RefEdition    
			  ,RS.RefStdName    
			  ,RS.RefStdCode    
		   FROM [SLCMaster].[dbo].[ReferenceStandard] RS WITH(NOLOCK)    
		   INNER JOIN [SLCMaster].[dbo].[ReferenceStandardEdition] RSE WITH(NOLOCK)    
		   ON RS.RefStdId = RSE.RefStdId    
		   WHERE RS.RefStdCode = @RSCode    
		   ORDER BY RSE.RefStdEditionId DESC) RSEdition    
    
		  SELECT @segmentDescription = CONCAT(RSEdition.RefStdName, ' - ', RSEdition.RefStdTitle + '; ' + RSEdition.RefEdition + '.')    
		  FROM (SELECT TOP 1    
			RSE.RefStdTitle    
			  ,RSE.RefEdition    
			  ,RS.RefStdName    
			  ,RS.RefStdCode    
		 FROM [ReferenceStandard] RS WITH(NOLOCK)    
		 INNER JOIN [ReferenceStandardEdition] RSE WITH(NOLOCK)    
		 ON RS.RefStdId = RSE.RefStdId    
		 WHERE RS.RefStdCode = @RSCode    
		 ORDER BY RSE.RefStdEditionId DESC) RSEdition    
	END    
    
	--Commented for Bug: Location related GT are not appearing with Project Value in "Submittals Log Report  
	--SELECT    
	-- @segmentDescription = REPLACE(@segmentDescription,    
	-- CONCAT('{GT#', CONVERT(NVARCHAR(MAX), GlobalTermCode), '}'), [Value])    
	--FROM [SLCMaster].[dbo].[GlobalTerm] WITH(NOLOCK)    
  
    IF(@segmentDescription like '%{GT#%')
	BEGIN
		SELECT @segmentDescription = REPLACE(@segmentDescription,    
		CONCAT('{GT#', CONVERT(NVARCHAR(MAX), GlobalTermCode), '}'), [Value])    
		FROM [dbo].[ProjectGlobalTerm] WITH(NOLOCK)    
		WHERE ProjectId = @ProjectId    
		AND CustomerId = @CustomerId    
		AND ISNULL(IsDeleted,0) = 0    
    END
	RETURN @segmentDescription;    
END