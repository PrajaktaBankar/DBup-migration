CREATE PROCEDURE [dbo].[usp_GetAccessibleProjects]              
   @CustomerId INT NULL                       
  ,@UserId INT NULL = NULL                       
  ,@IsOfficeMasterTab BIT NULL = NULL                       
  ,@IsSystemManager BIT NULL = 0                         
AS              
BEGIN              
 IF(@IsSystemManager=1)              
 BEGIN              
    INSERT INTO #accessibleProjectIds(ProjectId, ProjectAccessTypeId, IsProjectAccessible,ProjectAccessTypeName)                
    SELECT  DISTINCT 
    P.ProjectId        
   ,PSM.ProjectAccessTypeId      
   ,1 AS IsProjectAccessible           
   ,'' As ProjectAccessTypeName                                   
   FROM dbo.Project AS P WITH (NOLOCK)                   
    INNER JOIN [dbo].[ProjectSummary] PSM WITH (NOLOCK)             
    ON PSM.ProjectId = p.ProjectId               
   WHERE P.customerId = @CustomerId                                                
   AND ISNULL(P.IsDeleted,0) = 0                                                                
   --and ISNULL(P.IsArchived,0)= 0                                                                  
   AND P.IsOfficeMaster = @IsOfficeMasterTab                                                             
   --AND ISNULL( P.IsIncomingProject , 0)=0                                                               
 END              
 ELSE              
 BEGIN              
          
  ---Get all public,private and owned projects                 
  INSERT INTO #accessibleProjectIds(Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)                                                              
  SELECT ps.Projectid,ps.ProjectAccessTypeId,0,'',iif(ps.OwnerId=@UserId,1,0)         
  FROM ProjectSummary ps WITH(NOLOCK)                
  where  (ps.ProjectAccessTypeId in(1,2) or ps.OwnerId=@UserId)                 
  AND ps.CustomerId=@CustomerId                                           
                                     
  --Update all public Projects as accessible                 
  UPDATE t                 
  set t.IsProjectAccessible=1                 
  from #accessibleProjectIds t                  
  where t.ProjectAccessTypeId=1                 
                 
  --Update all private Projects if they are accessible                 
  UPDATE t        set t.IsProjectAccessible=1                 
  from #accessibleProjectIds t                  
  inner join UserProjectAccessMapping u WITH(NOLOCK)                 
  ON t.Projectid=u.ProjectId                       
  where u.IsActive=1                  
  and u.UserId=@UserId and t.ProjectAccessTypeId=2                 
  AND u.CustomerId=@CustomerId                     
                 
  --Get all accessible projects                 
  INSERT INTO #accessibleProjectIds  (Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)                                                              
  SELECT ps.Projectid,ps.ProjectAccessTypeId,1,'',iif(ps.OwnerId=@UserId,1,0) FROM ProjectSummary ps WITH(NOLOCK)                  
  INNER JOIN UserProjectAccessMapping upam WITH(NOLOCK)                                                             
  ON upam.ProjectId=ps.ProjectId                                                                  
  LEFT outer JOIN #accessibleProjectIds t                 
  ON t.Projectid=ps.ProjectId                 
  where ps.ProjectAccessTypeId=3 AND upam.UserId=@UserId and t.Projectid is null AND ps.CustomerId=@CustomerId                 
  AND(  upam.IsActive=1 OR ps.OwnerId=@UserId)                    
                 
  UPDATE t                                       
  set t.IsProjectAccessible=t.IsProjectOwner                                                      
  from #accessibleProjectIds t                  
  where t.IsProjectOwner=1               
                      
 END              
END  
  