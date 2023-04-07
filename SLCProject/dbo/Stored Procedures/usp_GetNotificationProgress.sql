CREATE PROCEDURE [dbo].[usp_GetNotificationProgress]
 @UserId int,  
 @RequestIdList nvarchar(100)='',  
 @CustomerId int,  
 @CopyProject BIT=0,  
 @ImportSection BIT=0,
 @unArchiveProject BIT=0
AS  
BEGIN  
 --find and mark as failed copy project requests which running loner(more than 30 mins)  
 --EXEC usp_UpdateLongRunningRequestsASFailed  
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())  
 DECLARE @RES AS TABLE(RequestId INT,SourceProjectId INT,TargetProjectId INT,TargetSectionId INT,  
       RequestDateTime DATETIME,RequestDateTimeStr NVARCHAR(20),RequestExpiryDateTime DATETIME,  
       StatusId INT,IsNotify BIT,CompletedPercentage INT,[Source] NVARCHAR(200),  
       TaskName nvarchar(500),StatusDescription nvarchar(50),IsOfficeMaster BIT,RequestTypeId INT)
  
 IF(@CopyProject=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT  CPR.RequestId  
  ,CPR.SourceProjectId    
  ,CPR.TargetProjectId    
  ,0  AS TargetSectionId  
  ,CPR.CreatedDate  AS RequestDateTime   
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
  ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime    
  ,CPR.StatusId    
  ,CPR.IsNotify    
  ,CPR.CompletedPercentage    
  ,'CopyProject' AS [Source]  
  ,CONVERT(nvarchar(500),'') AS TaskName  
  ,CONVERT(nvarchar(50),'') AS StatusDescription  
  ,0
  ,0
  FROM CopyProjectRequest CPR WITH (NOLOCK)  
  WHERE CPR.CreatedById = @UserId AND CPR.IsNotify = 0  
  AND ISNULL(CPR.IsDeleted, 0) = 0    
  AND CPR.CreatedDate> @DateBefore30Days  
  AND CPR.CopyProjectTypeId=1
    
  UPDATE t  
  SET t.TaskName=P.Name ,
	  t.IsOfficeMaster=P.IsOfficeMaster
  FROM @RES t INNER JOIN Project P WITH(NOLOCK)   
  ON P.ProjectId=t.TargetProjectId  
  WHERE P.CustomerId=@CustomerId  

  UPDATE CPR  
   SET CPR.IsNotify = 1  
   ,ModifiedDate = GETUTCDATE()  
    FROM CopyProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	WHERE CPR.IsNotify = 0   
 END  
  
 IF(@unArchiveProject=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT CPR.RequestId            
 ,0 AS SourceProjectId    
 ,CPR.SLCProd_ProjectId as TargetProjectId    
 ,0 as TargetSectionId       
 ,CPR.RequestDate AS RequestDateTime           
 ,FORMAT(CPR.RequestDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
 ,DATEADD(DAY,30,CPR.RequestDate) AS RequestExpiryDateTime            
 ,CPR.StatusId            
 ,CPR.IsNotify            
 ,CPR.ProgressInPercentage as CompletedPercentage         
 ,'UnArchiveProject' as Source  
 ,CPR.ProjectName AS TaskName  
 ,CONVERT(nvarchar(50),'') AS StatusDescription  
 ,0  
 ,CPR.RequestType
  FROM UnArchiveProjectRequest CPR WITH(NOLOCK)           
  WHERE CPR.SLC_UserId=@UserId AND CPR.IsNotify = 0
  AND ISNULL(CPR.IsDeleted,0)=0         
  AND CPR.RequestDate> @DateBefore30Days    
    
  UPDATE t  
  SET t.TaskName=P.Name ,
	  t.IsOfficeMaster=P.IsOfficeMaster
  FROM @RES t INNER JOIN Project P WITH(NOLOCK)   
  ON P.ProjectId=t.TargetProjectId  
  WHERE P.CustomerId=@CustomerId  

  UPDATE CPR  
   SET CPR.IsNotify = 1  
   ,ModifiedDate = GETUTCDATE()  
    FROM UnArchiveProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	WHERE CPR.IsNotify = 0   
	AND t.[Source]='unArchiveProject'
 END 

 IF(@ImportSection=1)  
 BEGIN  
  INSERT INTO @RES  
  SELECT CPR.RequestId    
  ,CPR.SourceProjectId    
  ,CPR.TargetProjectId    
  ,CPR.TargetSectionId   
  ,CPR.CreatedDate AS RequestDateTime   
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
  ,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime    
  ,CPR.StatusId    
  ,CPR.IsNotify    
  ,CPR.CompletedPercentage     
  ,CPR.Source  
  ,CONVERT(nvarchar(500),'') AS TaskName  
  ,CONVERT(nvarchar(50),'') AS StatusDescription 
  ,0
  ,0
   FROM ImportProjectRequest CPR WITH(NOLOCK)   
   WHERE CPR.CreatedById=@UserId AND [Source] IN('SpecAPI','Import from Template')   
   AND ISNULL(CPR.IsDeleted,0)=0     
   AND CPR.IsNotify=0  
   AND CPR.CreatedDate> @DateBefore30Days    
  
  UPDATE t  
  SET t.TaskName=PS.Description  
  FROM @RES t INNER JOIN ProjectSection PS WITH(NOLOCK)       
  ON t.TargetSectionId=PS.SectionId  
  WHERE PS.CustomerId=@CustomerId  
  AND t.[Source] IN('SpecAPI','Import from Template')  

   UPDATE CPR  
	SET CPR.IsNotify = 1  
    ,ModifiedDate = GETUTCDATE()  
	FROM ImportProjectRequest CPR WITH (NOLOCK)  
	INNER JOIN @RES t  
	ON CPR.RequestId = t.RequestId  
	--AND CPR.[Source]=t.[Source]  
	WHERE CPR.IsNotify = 0   
 END   
  
 UPDATE t  
 SET t.StatusDescription=LCS.StatusDescription  
 FROM @RES t INNER JOIN LuCopyStatus LCS WITH(NOLOCK)       
 ON t.StatusId=LCS.CopyStatusId  
  
 SELECT * FROM @RES  
 ORDER BY RequestDateTimeStr DESC  
  
  
END  