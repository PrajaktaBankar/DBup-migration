CREATE PROCEDURE [dbo].[usp_GetProjectReferenceStandards]    
(              
 @ProjectId INT,              
 @SectionId INT,                
 @CustomerId INT          
)              
AS      
                     
BEGIN
    DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PSectionId INT = @SectionId;
    DECLARE @PCustomerId INT = @CustomerId;

  DECLARE @mSectionid int = ( SELECT
		mSectionId
	FROM ProjectSection WITH (NOLOCK)
	WHERE SectionId = @PSectionId)


IF EXISTS (SELECT
			COUNT(DISTINCT PS.SectionId)
		FROM SLCMaster..SegmentReferenceStandard SRS  WITH(NOLOCK)
		INNER JOIN ProjectSection PS  WITH(NOLOCK)
			ON SRS.SectionId = PS.mSectionId
		WHERE PS.ProjectId = 1
		AND ps.IsDeleted = 0
		AND ps.IsLastLevel = 1
		AND ps.SectionId = @PSectionId)
BEGIN

SELECT
	* INTO #TmpRefStd
FROM (SELECT
		PREF.RefStdId
	   ,PREF.RefStdName
	   ,PREF.ReplaceRefStdId
	   ,PREF.IsObsolete
	   ,PREF.RefStdCode
	   ,U.RefStdEditionId
	   ,U.RefEdition
	   ,U.RefStdTitle
	   ,U.LinkTarget
	   ,'U' AS RefStdSource
	FROM ReferenceStandard PREF WITH (NOLOCK)
	CROSS APPLY (SELECT TOP 1
	    PREFEDN.RefStdEditionId
	   ,PREFEDN.RefEdition
	   ,PREFEDN.RefStdTitle
	   ,PREFEDN.LinkTarget
		FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)
		WHERE PREFEDN.RefStdId = PREF.RefStdId
		ORDER BY PREFEDN.RefStdEditionId DESC) AS U
	WHERE PREF.CustomerId = @PCustomerId) AS X
OPTION (FORCE ORDER)

UPDATE TMP
SET TMP.RefStdEditionId = PRSTD.RefStdEditionId
   ,TMP.RefEdition = EDN.RefEdition
   ,TMP.RefStdTitle = EDN.RefStdTitle
   ,TMP.LinkTarget = EDN.LinkTarget
FROM #TmpRefStd TMP
INNER JOIN ProjectReferenceStandard PRSTD WITH (NOLOCK)
	ON TMP.RefStdId = PRSTD.RefStandardId
	AND PRSTD.ProjectId = @PProjectId
	--AND PRSTD.SectionId = @PSectionId        
	AND PRSTD.CustomerId = @PCustomerId
	AND TMP.RefStdSource = 'U'
	AND PRSTD.IsDeleted = 0
INNER JOIN ReferenceStandardEdition EDN WITH (NOLOCK)
	ON PRSTD.RefStdEditionId = EDN.RefStdEditionId
WHERE TMP.RefStdSource = 'U'
END
SELECT
	*
FROM #TmpRefStd

END

GO
