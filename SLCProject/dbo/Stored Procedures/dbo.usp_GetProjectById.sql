CREATE PROC [dbo].[usp_GetProjectById]
(
	@ProjectId INT
)
AS
BEGIN
SELECT
	p.ProjectId
   ,p.Name
   ,p.IsOfficeMaster
   ,ISNULL(p.TemplateId, 0) AS TemplateId
   ,p.MasterDataTypeId
   ,p.UserId
   ,p.CustomerId
   ,ps.SpecViewModeId
   ,ISNULL(p.CreateDate, GETUTCDATE()) AS CreateDate
   ,ISNULL(p.CreatedBy, 0) AS CreatedBy
   ,ISNULL(p.ModifiedBy, 0) AS ModifiedBy
   ,ISNULL(p.ModifiedDate, GETUTCDATE()) AS ModifiedDate
   ,ISNULL(p.IsDeleted, 0) AS IsDeleted
   ,ISNULL(p.IsMigrated, 0) AS IsMigrated
   ,ISNULL(p.IsLocked,0) AS IsLocked  
   ,ISNULL(p.IsPermanentDeleted, 0) AS IsPermanentDeleted
   ,ISNULL(p.ModifiedByFullName,'') As ModifiedByFullName
   ,ISNULL(PS.IsLinkEngineEnabled,0) AS IsLinkEngineServiceEnabled  
FROM Project p WITH(NOLOCK) inner join ProjectSummary ps with(nolock)
ON p.ProjectId=ps.ProjectId
WHERE p.ProjectId = @ProjectId
END
GO
