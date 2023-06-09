CREATE PROCEDURE [dbo].[usp_GetReferenceStandardsOfSegments]      
(      
 @ProjectId INT,      
 @SectionId INT,      
 @FIND VARCHAR(50) = '%{RS#%}%',      
 @REPLACE VARCHAR(50) = 'RS#',      
 @REPLACERSPara VARCHAR(50) = 'RSTEMP#',  
 @CustomerId INT  
)      
AS             
BEGIN
  
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PFIND VARCHAR(50) = @FIND;
 DECLARE @PREPLACE VARCHAR(50) = @REPLACE;
 DECLARE @PREPLACERSPara VARCHAR(50) = @REPLACERSPara;
 DECLARE @PCustomerId INT = @CustomerId;
--Set Nocount On
SET NOCOUNT ON;

  DECLARE @MasterSectionId AS INT;
SET @MasterSectionId = (SELECT TOP 1
		mSectionId
	FROM ProjectSection WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId
	AND SectionId = @PSectionId);
  
  
 DECLARE @segmentDesc VARCHAR(max)
SET @segmentDesc = '';
  
      
 DECLARE @msegmentDesc VARCHAR(max)
SET @msegmentDesc = '';

SELECT
	@segmentDesc = @segmentDesc + COALESCE(PS.SegmentDescription + ',', ' ')
FROM ProjectSegment AS PS (NOLOCK)
WHERE PS.SectionId = @PSectionId
AND PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId
AND PS.SegmentSource = 'U'
AND CONTAINS(PS.SegmentDescription, '{RS OR {RSTEMP')

SELECT
	@msegmentDesc = @msegmentDesc + COALESCE(S.SegmentDescription + ',', ' ')
FROM SLCMaster.dbo.Segment AS S  WITH(NOLOCK)
WHERE S.SectionId = @MasterSectionId
AND CONTAINS(S.SegmentDescription, '{RS OR {RSTEMP')

SELECT
	RS.RefStdId
   ,RS.RefStdName
   ,RS.ReplaceRefStdId
   ,RS.IsObsolete
   ,RS.RefStdCode
   ,RefEdition.RefStdEditionId
   ,RefEdition.RefEdition
   ,RefEdition.RefStdTitle
   ,RefEdition.LinkTarget
FROM [SLCMaster].dbo.ReferenceStandard RS (NOLOCK)
CROSS APPLY (SELECT TOP 1
		RSE.RefStdEditionId
	   ,RSE.RefEdition
	   ,RSE.RefStdTitle
	   ,RSE.LinkTarget
	FROM [SLCMaster].dbo.ReferenceStandardEdition RSE (NOLOCK)
	WHERE RSE.RefStdId = RS.RefStdCode
	ORDER BY RSE.RefStdEditionId DESC) RefEdition
WHERE RS.RefStdCode IN (SELECT DISTINCT
		CONVERT(INT, Ids) AS RefStdCode
	FROM dbo.fn_GetIdSegmentDescription(@segmentDesc + @msegmentDesc, @PREPLACE)
	UNION
	SELECT DISTINCT
		CONVERT(INT, Ids) AS RefStdCode
	FROM dbo.fn_GetIdSegmentDescription(@segmentDesc + @msegmentDesc, @PREPLACERSPara))
ORDER BY RS.RefStdName;
END

GO
