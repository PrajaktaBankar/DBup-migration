CREATE PROCEDURE [dbo].[usp_GetReferenceStandard]     
AS       
BEGIN
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
ORDER BY RS.RefStdName;
END

GO
