 CREATE PROCEDURE [dbo].[usp_GetProjectSegmentReferenceStandards]       
@RefStandardId INT NULL,    
@RefStdCode INT  NULL,    
@CustomerId INT NULL    
AS           
BEGIN  
    
DECLARE @PRefStandardId INT = @RefStandardId;  
DECLARE @PRefStdCode INT = @RefStdCode;  
DECLARE @PCustomerId INT = @CustomerId;  
DROP TABLE IF EXISTS #tmpUserReferenceStandard  
  
SELECT  
 RS.SegmentRefStandardId  
   ,RS.RefStandardId  
   ,RS.ProjectId  
   ,RS.RefStandardSource  
   ,RS.CustomerId  
   INTO #tmpUserReferenceStandard  
FROM [ProjectSegmentReferenceStandard] RS WITH (NOLOCK)  
WHERE RS.RefStandardId = @PRefStandardId  
AND RS.RefStdCode = @PRefStdCode  
AND RS.CustomerId = @PCustomerId  
AND RS.IsDeleted = 0  

-- To check RS is lock/unlock status and check RS use status in any project 
SELECT TOP 1
	refstd.RefStdId
   ,refstd.RefStdSource
   ,refstd.RefStdCode
   ,refstd.CustomerId
   ,refstd.IsDeleted
   ,refstd.IsLocked
   ,refstd.IsLockedByFullName
   ,refstd.IsLockedById
   ,RS.*
FROM ReferenceStandard refstd WITH (NOLOCK)
LEFT JOin #tmpUserReferenceStandard RS ON refstd.RefStdId = RS.RefStandardId
LEFT JOIN Project P with (nolock)   ON P.ProjectId = RS.ProjectId and (ISNULL(P.IsPermanentDeleted,0) = 0  OR ISNULL(P.IsDeleted,0) = 0 )
WHERE refstd.RefStdId = @PRefStandardId;

/*  
--Added this change to filter used Reference from Permanently Deleted Projects  
SELECT  
 RS.*  
FROM #tmpUserReferenceStandard RS  
INNER JOIN Project P with (nolock)  
 ON P.ProjectId = RS.ProjectId  
WHERE ISNULL(P.IsPermanentDeleted,0) = 0  
OR ISNULL(P.IsDeleted,0) = 0  
ORDER BY RS.RefStandardId;  */
  
END  