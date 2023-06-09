CREATE PROCEDURE [dbo].[usp_GetMasterReferenceStandards]    
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


SELECT
	MREF.RefStdId
   ,MREF.RefStdName
   ,MREF.ReplaceRefStdId
   ,MREF.IsObsolete
   ,MREF.RefStdCode
   ,0 AS RefStdEditionId
   ,'' AS RefEdition
   ,'' AS RefStdTitle
   ,'' AS LinkTarget
   ,'M' AS RefStdSource INTO #TmpRefStd
FROM SLCMaster..ReferenceStandard MREF WITH (NOLOCK)

SELECT
	MRSE.RefStdEditionId
   ,MRSE.RefEdition
   ,MRSE.RefStdTitle
   ,MRSE.LinkTarget
FROM #TmpRefStd MREF WITH (NOLOCK)
INNER JOIN SLCMaster..ReferenceStandardEdition AS MRSE WITH (NOLOCK)
	ON MREF.RefStdId = MRSE.RefStdId;


/*
SELECT
	* INTO #TmpRefStd
FROM (SELECT
		MREF.RefStdId
	   ,MREF.RefStdName
	   ,MREF.ReplaceRefStdId
	   ,MREF.IsObsolete
	   ,MREF.RefStdCode
	   ,M.RefStdEditionId
	   ,M.RefEdition
	   ,M.RefStdTitle
	   ,M.LinkTarget
	   ,'M' AS RefStdSource
	FROM SLCMaster..ReferenceStandard MREF WITH (NOLOCK)
	CROSS APPLY (SELECT TOP 1
			*
		FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)
		WHERE MREFEDN.RefStdId = MREF.RefStdId
		ORDER BY MREFEDN.RefStdEditionId DESC) AS M )   AS X OPTION (FORCE ORDER) 

--NOW UPDATE EDITION ID ACCORDING TO ProjectReferenceStandard        
UPDATE TMP
SET TMP.RefStdEditionId = EDN.RefStdEditionId
   ,TMP.RefEdition = EDN.RefEdition
   ,TMP.RefStdTitle = EDN.RefStdTitle
   ,TMP.LinkTarget = EDN.LinkTarget
FROM #TmpRefStd TMP
INNER JOIN ProjectReferenceStandard PRSTD WITH (NOLOCK)
	ON TMP.RefStdId = PRSTD.RefStandardId
	AND PRSTD.ProjectId = @PProjectId
	--AND PRSTD.SectionId = @PSectionId        
	AND PRSTD.CustomerId = @PCustomerId
	AND TMP.RefStdSource = 'M'
INNER JOIN SLCMaster..ReferenceStandardEdition EDN WITH (NOLOCK)
	ON PRSTD.RefStdEditionId = EDN.RefStdEditionId
WHERE TMP.RefStdSource = 'M'
	*/
SELECT
	*
FROM #TmpRefStd;

END

GO
