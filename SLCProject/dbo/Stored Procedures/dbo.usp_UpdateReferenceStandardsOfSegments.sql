CREATE PROCEDURE [dbo].[usp_UpdateReferenceStandardsOfSegments]            
(            
 @ProjectId INT,            
 @SectionId INT,              
 @CustomerId INT,
 @MasterDataTypeId INT =NULL      
)            
AS    
                   
BEGIN
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PSectionId INT = @SectionId;
 DECLARE @PCustomerId INT = @CustomerId;
 DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;

DROP TABLE IF EXISTS #RefStdTbl
SELECT MAX(RSE.RefStdEditionId) as RefStdEditionId,RSE.RefStdId
INTO #RefStdTbl	FROM [SLCMaster].dbo.ReferenceStandardEdition RSE  WITH (NOLOCK)
GROUP BY RSE.RefStdId

DROP TABLE IF EXISTS #RefStdProj
SELECT MAX(PRSE.RefStdEditionId) as RefStdEditionId,PRSE.RefStdId
INTO #RefStdProj FROM ReferenceStandardEdition PRSE WITH (NOLOCK)
GROUP BY PRSE.RefStdId

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
	inner join #RefStdTbl R on R.RefStdId = MREF.RefStdId AND MREF.MasterDataTypeId = @PMasterDataTypeId
	inner join [SLCMaster].dbo.ReferenceStandardEdition M WITH (NOLOCK) on R.RefStdEditionId = M.RefStdEditionId
	where M.MasterDataTypeId = @PMasterDataTypeId 

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
	inner join #RefStdProj R on R.RefStdId = PREF.RefStdId
	inner join ReferenceStandardEdition U WITH (NOLOCK) on R.RefStdEditionId = U.RefStdEditionId

	WHERE PREF.CustomerId = @PCustomerId) AS X
OPTION (FORCE ORDER)


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
	AND PRSTD.IsDeleted = 0
	AND TMP.RefStdSource = 'M'
INNER JOIN SLCMaster..ReferenceStandardEdition EDN WITH (NOLOCK)
	ON PRSTD.RefStdEditionId = EDN.RefStdEditionId
WHERE TMP.RefStdSource = 'M';

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
	AND PRSTD.IsDeleted = 0
	AND TMP.RefStdSource = 'U'
INNER JOIN ReferenceStandardEdition EDN WITH (NOLOCK)
	ON PRSTD.RefStdEditionId = EDN.RefStdEditionId
WHERE TMP.RefStdSource = 'U';

SELECT
	*
FROM #TmpRefStd;

END

GO
