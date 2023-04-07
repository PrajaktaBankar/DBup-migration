CREATE Procedure usp_DeleteUserTag        
(            
  @UserTagId INT    
 ,@IsDeleteProjectUserTag BIT =1
)            
AS             
BEGIN           
DECLARE @UserTagCount INT=0;  
DECLARE @UserArchiveCount Int=0; 
SELECT @UserArchiveCount=COUNT(PSU.UserTagId) FROM ProjectSegmentUserTag PSU WITH (NOLOCK)
	inner join ProjectSection PS WITH (NOLOCK) ON PS.SectionId=PSU.SectionId 
	inner join Project P  WITH (NOLOCK) ON PSU.ProjectId=P.ProjectId AND ISNULL (P.IsArchived,0)=0 
	WHERE UserTagId=@UserTagId
	AND ISNULL (PSU.IsDeleted,0) = 0 
	AND ISNULL (PS.IsDeleted,0) = 0
	AND IsNull (P.IsDeleted,0) = 0

IF(@UserArchiveCount > 0)
BEGIN
SELECT  @UserTagCount=COUNT(PSU.UserTagId) FROM ProjectSegmentUserTag PSU WITH (NOLOCK)
 WHERE PSU.UserTagId=@UserTagId 
END
     
CREATE TABLE #TempUserReportTag(        
ProjectID int,        
SectionId int,        
ProjectName nvarchar(max),        
SectionName nvarchar(max),        
SequenceNumber decimal)        
        
        
IF(@UserTagCount>0)        
BEGIN        
INSERT INTO #TempUserReportTag (P.ProjectId, PSS.SectionId,ProjectName,SectionName,PSU.SequenceNumber)         
Select P.ProjectId,PSS.SectionId,CONCAT(P.ProjectId,'                 ', P.Name) As ProjectName,CONCAT(PSS.SourceTag,' - ',  PSS.Author, ' - ', PSS.Description) As SectionName,PSU.SequenceNumber        
from         
ProjectSegmentUserTag PST WITH (NOLOCK)          
INNER JOIN ProjectSegmentStatus PSU WITH (NOLOCK)          
ON PST.SegmentStatusId=PSU.SegmentStatusId
INNER JOIN ProjectSection PSS WITH (NOLOCK)          
ON PSS.SectionId=PST.SectionId
INNER JOIN Project P  WITH (NOLOCK)     
ON P.ProjectId=PST.ProjectId
WHERE ISNULL (p.IsArchived,0) = 0  
AND PST.UserTagId = @UserTagId
AND ISNULL (PST.IsDeleted,0) = 0
AND ISNULL (PSS.IsDeleted,0) = 0
AND ISNULL (P.IsDeleted,0) = 0
order by PSU.SequenceNumber       
END        
ELSE        
BEGIN        
   if(@IsDeleteProjectUserTag = 1)    
   BEGIN     
   Update PUT             
   set PUT.IsDeleted = 1           
   from ProjectUserTag  PUT WITH (NOLOCK) where PUT.UserTagId = @UserTagId     
  END           
   END         
    
    
   Select DISTINCT @UserTagCount As UserTagCount ,* from #TempUserReportTag        
END; 