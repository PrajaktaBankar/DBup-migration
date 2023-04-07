CREATE PROCEDURE [dbo].[usp_GetMigrationProjectsForPDFGeneration] 
          
AS          
BEGIN 

    SELECT ProjectId,CustomerId,P.Name AS ProjectName,ISNULL(AP.ArchiveProjectId,0) AS ArchiveProjectId, slc_prodprojectid
	FROM [dbo].Project P WITH(NOLOCK)
	LEFT OUTER JOIN	[ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH(NOLOCK) 
		ON P.ProjectId =AP.slc_prodprojectid and P.CustomerId=AP.SLC_CustomerID
	WHERE IsShowMigrationPopup = 1 AND
	ISNULL(PDFGenerationStatusId,0)=0 AND 
	ISNULL(P.IsDeleted,0)=0 
END 
GO