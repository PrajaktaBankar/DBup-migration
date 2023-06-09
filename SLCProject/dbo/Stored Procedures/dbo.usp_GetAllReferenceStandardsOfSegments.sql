CREATE PROCEDURE [dbo].[usp_GetAllReferenceStandardsOfSegments]        
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
--SELECT RefStdCode  
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
		RefStdEditionId
	   ,RefEdition
	   ,RefStdTitle
	   ,LinkTarget
		FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)
		WHERE MREFEDN.RefStdId = MREF.RefStdId
		ORDER BY MREFEDN.RefStdEditionId DESC) AS M
	UNION
	SELECT
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
	    RefStdEditionId
	   ,RefEdition
	   ,RefStdTitle
	   ,LinkTarget
		FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)
		WHERE PREFEDN.RefStdId = PREF.RefStdId
		ORDER BY PREFEDN.RefStdEditionId DESC) AS U) AS X

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
	AND PRSTD.IsDeleted = 0
INNER JOIN SLCMaster..ReferenceStandardEdition EDN WITH (NOLOCK)
	ON PRSTD.RefStdEditionId = EDN.RefStdEditionId;

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
	ON PRSTD.RefStdEditionId = EDN.RefStdEditionId;

SELECT
		RefStdId
	   ,RefStdName
	   ,ReplaceRefStdId
	   ,IsObsolete
	   ,RefStdCode
	   ,RefStdEditionId
	   ,RefEdition
	   ,RefStdTitle
	   ,LinkTarget
	   ,RefStdSource
FROM #TmpRefStd;

END

GO
