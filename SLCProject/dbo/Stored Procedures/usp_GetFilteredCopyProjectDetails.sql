CREATE PROC usp_GetFilteredCopyProjectDetails
(        
 @StatusId INT,        
 @Duration INT=-1,        
 @PageSize INT,        
 @PageNumber INT,        
 @SortOrderDesc BIT=0,        
 @SortByColumnName NVARCHAR(100)=''        
)        
AS        
BEGIN  
	declare @reqStatus as table(statusId int)
	if(@StatusId=-1)
	begin
		insert into @reqStatus (statusId)
		SELECT copyStatusId from LuCopyStatus WITH(NOLOCK)        
	end
	else if(@StatusId=4)
	BEGIN
		insert into @reqStatus (statusId) select 5
	end
	else insert into @reqStatus (statusId) select @StatusId

	SELECT cp.RequestId,CP.TargetProjectId into #filtered FROM CopyProjectRequest CP WITH(NOLOCK)         
	WHERE IsDeleted=0 AND StatusId in(SELECT statusId from @reqStatus)
	AND CP.CreatedDate>=iif(@Duration<0,CP.CreatedDate,DATEADD(DAY,(-@Duration),GETUTCDATE()))
	 AND CP.CopyProjectTypeId=1
	ORDER BY CustomerId   

	
 SELECT cp.RequestId,
 CustomerId,cp.TargetProjectId,SourceProjectId,StatusId,        
         
 CreatedDate as RequestInitiated,        
 CAST(null AS DATETIME) AS RequestCompleted,        
         
 CAST('' as NVARCHAR(150)) AS SourceProjectName,        
 CAST('' as NVARCHAR(150)) AS TargetProjectName,        
 CAST('' as NVARCHAR(150)) AS StatusDescription,        
        
 CAST(0 as INT) AS SystemProcessingTime,        
 CAST(0 as INT) AS TotalProcessingTime   ,  
 CAST(null as datetime) as Step1Date   ,  
 CAST(null as datetime) as Step14Date     
 INTO #TEMP FROM CopyProjectRequest CP WITH(NOLOCK)     
 INNER JOIN #filtered t
 ON t.RequestId=cp.RequestId
  AND CP.CopyProjectTypeId=1
 ORDER BY CustomerId        
 OFFSET @PageSize * (@PageNumber - 1) ROWS                      
 FETCH NEXT @PageSize ROWS ONLY;            
         
 UPDATE t
 SET t.TargetProjectName=p.Name        
 FROM #TEMP t INNER JOIN Project p WITH(NOLOCK)        
 ON t.TargetProjectId=p.ProjectId        
        
 UPDATE t
 SET t.SourceProjectName=p.Name        
 FROM #TEMP t INNER JOIN Project p WITH(NOLOCK)        
 ON t.SourceProjectId=p.ProjectId        
        
 UPDATE t
 SET t.StatusDescription=p.Name        
 FROM #TEMP t INNER JOIN LuCopyStatus p WITH(NOLOCK)        
 ON t.StatusId=p.CopyStatusId        
           
 UPDATE t
 SET t.RequestCompleted=cp.CreatedDate    ,  
 t.Step14Date=  cp.CreatedDate      
 FROM CopyProjectHistory cp WITH(NOLOCK)        
 INNER JOIN #TEMP t        
 ON t.TargetProjectId=cp.projectId        
 WHERE cp.Step=14        
           
 UPDATE t
 SET t.SystemProcessingTime=ISNULL(DATEDIFF(SECOND,cp.CreatedDate,t.RequestCompleted),0)  
, t.Step1Date=  cp.CreatedDate      
 FROM CopyProjectHistory cp WITH(NOLOCK)        
 INNER JOIN #TEMP t        
 ON t.TargetProjectId=cp.projectId       
 WHERE cp.Step=2        
        
 UPDATE t
 SET t.TotalProcessingTime=ISNULL(DATEDIFF(SECOND,t.RequestInitiated,t.RequestCompleted),0)        
 FROM #TEMP t        
       
	 select *,
	 STUFF(STUFF(TotalProcessingTimeSys, 6, 1 ,' mins '), 3, 1 ,' hrs ') as TotalProcessingTime1,
	 STUFF(STUFF(SystemProcessingTimeSys, 6, 1 ,' mins '), 3, 1 ,' hrs ') as SystemProcessingTime1
	into #tttemp  from(   
 SELECT
 CustomerId,      
 TargetProjectId,      
 TargetProjectName,      
 SourceProjectId,      
 SourceProjectName,      
 StatusId,        
 StatusDescription,      
 convert(varchar, RequestInitiated, 20) as RequestInitiated,      
 convert(varchar, RequestCompleted, 20) as RequestCompleted,    
 concat(CONVERT(char(10), dateadd(second, TotalProcessingTime, '00:00:00'), 108),' Secs') as TotalProcessingTimeSys, 
 concat(CONVERT(char(10), dateadd(second, SystemProcessingTime, '00:00:00'), 108),' Secs') as SystemProcessingTimeSys,  
  --(  
  --Case WHEN SystemProcessingTime < 60 THEN CONVERT (varchar,SystemProcessingTime) + ' secs'      
  --  WHEN SystemProcessingTime > 3600 THEN CONVERT(varchar,CAST((SystemProcessingTime/cast(3600 as decimal)) as decimal(9,2))) + ' hours'  
  --  WHEN SystemProcessingTime > 60 THEN CONVERT(varchar,CAST((SystemProcessingTime/cast(60 as decimal)) as decimal(9,2))) + ' mins'  
  --ELSE ''  
  --END  
  --) as SystemProcessingTime1,      
  --(Case WHEN TotalProcessingTime < 60 THEN CONVERT (varchar,TotalProcessingTime) + ' secs'      
  --  WHEN TotalProcessingTime > 3600 THEN CONVERT(varchar,CAST((TotalProcessingTime/cast(3600 as decimal)) as decimal(9,2))) + ' hours'  
  --  WHEN TotalProcessingTime > 60 THEN CONVERT(varchar,CAST((TotalProcessingTime/cast(60 as decimal)) as decimal(9,2))) + ' mins'  
  --ELSE ''  
  --END  
  --) as TotalProcessingTime1,     
  Step1Date,  
  Step14Date  
  FROM #TEMP        
  ) as res

  select *,
  replace(replace(TotalProcessingTime1,'00 hrs ',''),'00 mins ','') as TotalProcessingTime,
  replace(replace(SystemProcessingTime1,'00 hrs ',''),'00 mins ','') as SystemProcessingTime
    from #tttemp

  SELECT count(1) from #filtered
   
END  

GO

