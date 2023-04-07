
--sp_helptext ProjectView

  
  
CREATE VIEW [dbo].[ProjectView]  
AS  
SELECT  
 P.ProjectId AS ProjectId  
   ,P.CustomerId AS CustomerId  
   ,P.Name AS Name  
   ,P.Description AS Description  
   ,P.IsOfficeMaster AS IsOfficeMaster  
   ,P.MasterDataTypeId AS MasterDataTypeId  
   ,ISNULL(P.IsPermanentDeleted, 0) AS IsPermanentDeleted  
   ,(CASE  
  WHEN P.IsDeleted = 1 AND  
   ISNULL(P.IsPermanentDeleted, 0) = 0 THEN 1  
  ELSE 0  
 END) AS IsSoftDeleted  
   ,(CASE  
  WHEN P.IsDeleted = 1 AND  
   ISNULL(P.IsPermanentDeleted, 0) = 1 THEN 1  
  ELSE 0  
 END) AS IsHardDeleted  
FROM Project P  with (nolock)