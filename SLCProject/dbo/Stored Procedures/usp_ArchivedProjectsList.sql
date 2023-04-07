CREATE PROCEDURE [dbo].[usp_ArchivedProjectsList]
(          
 @CustomerId INT,
 @UserId INT=0,
 @IsSystemManager BIT=0,          
 @IsOfficeMaster INT=0,          
 @PageNumber INT=1,          
 @PageSize INT=20,          
 @SearchText NVARCHAR(1024)=''          
)          
AS          
BEGIN     
	DECLARE @TRUE BIT=1,@FALSE BIT=0
	SELECT       
	 CONVERT(BIGINT, P.ProjectId) AS ArchiveProjectId,      
	 P.[Name] AS ProjectName,      
	 0 AS SLC_ArchiveProjectId,      
	 P.ProjectId AS SLC_ProdProjectId,      
	 ISNULL(UF.UserId,0) AS SLC_UserId,      
	 P.CustomerId AS SlcCustomerId,      
	 ISNULL(UF.LastAccessed,'') AS ArchivedDate,      
	 ISNULL(UF.LastAccessByFullName,'') AS ModifiedByFullName,      
	 
	 ISNULL(PS.ProjectAccessTypeId,1) AS ProjectAccessTypeId,
	 @FALSE AS IsProjectAccessible,
	 CONVERT(NVARCHAR(100),'') AS ProjectAccessTypeName,
	 IIF(PS.OwnerId=@UserId,@TRUE,@FALSE) as IsProjectOwner 
	  
	 INTO #T FROM Project P WITH(NOLOCK)      
	 LEFT JOIN UserFolder UF WITH(NOLOCK) ON UF.ProjectId = P.ProjectId      
	 LEFT JOIN ProjectSummary PS WITH(NOLOCK) ON PS.ProjectId = P.ProjectId      
	 WHERE P.CustomerId = @CustomerId      
	 AND ISNULL(P.IsDeleted,0) = 0      
	 AND ISNULL(P.IsArchived,0) = 1      
	 AND ISNULL(P.IsPermanentDeleted,0) = 0      
	 AND ISNULL(p.IsOfficeMaster,0)=@IsOfficeMaster    
	 
 IF(@IsSystemManager=@TRUE)   
 BEGIN 
	      
	UPDATE t   
	set t.ProjectAccessTypeName=pt.Name,
		t.IsProjectAccessible=@TRUE  
	from #T t inner join LuProjectAccessType pt  WITH (NOLOCK)              
	on t.ProjectAccessTypeId=pt.ProjectAccessTypeId  
    
	SELECT * FROM #T ORDER by ArchivedDate desc  
 END
 ELSE
 BEGIN
	CREATE TABLE #AccessibleProjectIds(     
	   Projectid INT,     
	   ProjectAccessTypeId INT,     
	   IsProjectAccessible bit,     
	   --ProjectAccessTypeName NVARCHAR(100)  ,   
	   IsProjectOwner BIT   
	);
	
	---Get all public,private and owned projects   
	INSERT INTO #AccessibleProjectIds(Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,IsProjectOwner)                            
	SELECT ps.Projectid,ps.ProjectAccessTypeId,0,iif(ps.OwnerId=@UserId,1,0) 
	FROM #t t inner join ProjectSummary ps WITH(NOLOCK)    
	ON t.ArchiveProjectId=ps.ProjectId      
	where  (ps.ProjectAccessTypeId in(1,2) or ps.OwnerId=@UserId)   
	AND ps.CustomerId=@CustomerId  
	
	--Update all public Projects as accessible   
	UPDATE t   
	set t.IsProjectAccessible=1   
	from #AccessibleProjectIds t    
	where t.ProjectAccessTypeId=1        
	    
	--Update all private Projects if they are accessible   
	UPDATE t set t.IsProjectAccessible=1   
	from #AccessibleProjectIds t    
	inner join UserProjectAccessMapping u WITH(NOLOCK)   
	ON t.Projectid=u.ProjectId         
	where u.IsActive=1    
	and u.UserId=@UserId and t.ProjectAccessTypeId=2   
	AND u.CustomerId=@CustomerId     
	
	--Get all accessible projects   
	INSERT INTO #AccessibleProjectIds  (Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,IsProjectOwner)                            
	SELECT ps.Projectid,ps.ProjectAccessTypeId,1,iif(ps.OwnerId=@UserId,1,0) 
	FROM #t res inner join ProjectSummary ps WITH(NOLOCK)  
	ON res.ArchiveProjectId=ps.ProjectId
	INNER JOIN UserProjectAccessMapping upam WITH(NOLOCK)   
	ON upam.ProjectId=ps.ProjectId 
	LEFT outer JOIN #AccessibleProjectIds t   
	ON t.Projectid=ps.ProjectId   
	where ps.ProjectAccessTypeId=3 AND upam.UserId=@UserId and t.Projectid is null AND ps.CustomerId=@CustomerId   
	AND(upam.IsActive=1 OR ps.OwnerId=@UserId)      
 
	UPDATE t   
	set t.IsProjectAccessible=t.IsProjectOwner   
	from #AccessibleProjectIds t    
	where t.IsProjectOwner=1         
	
	UPDATE t   
	set t.ProjectAccessTypeName=pt.Name
	from #T t inner join LuProjectAccessType pt  WITH (NOLOCK)              
	on t.ProjectAccessTypeId=pt.ProjectAccessTypeId

	UPDATE res   
	set res.IsProjectAccessible=t.IsProjectAccessible	
	from #T res INNER JOIN #AccessibleProjectIds t    
	ON res.ArchiveProjectId=t.ProjectId

	SELECT res.* from #T res 
	INNER JOIN #AccessibleProjectIds t    
	ON res.ArchiveProjectId=t.ProjectId
	ORDER by res.ArchivedDate desc      
	 
 END
END 