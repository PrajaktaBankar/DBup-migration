Use SLCProject
GO

PRINT N'Creating [dbo].[fn_GetRESTempPlaceholder]...';


GO

CREATE FUNCTION [dbo].[fn_GetRESTempPlaceholder](@Description NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	--DECLARE @Description AS NVARCHAR(MAX) = '{RSTEMP#10004741}' --'{RSTEMP#10004741}'
	DECLARE @ID INT = 0
	, @I INT
	, @K INT
	, @tmp VARCHAR(20) = ''
	, @OldPlaceHolder VARCHAR(20) = ''
	, @ReplaceString NVARCHAR(50)
	, @SegmentText NVARCHAR(MAX) = @Description
	, @retString NVARCHAR(MAX) = ''
	, @OldChoice VARCHAR(50) = ''
	, @OldStringTAG NVARCHAR(10) = '{RSTEMP#'
	SET @OldChoice = REPLACE(@Description, '}', '')
	IF CHARINDEX(@OldChoice,@SegmentText) > 0
	BEGIN
		SELECT @I = CHARINDEX(@OldChoice,@SegmentText)
		SELECT @K = PATINDEX('%}%',SUBSTRING(@SegmentText, @I + 1, LEN(@SegmentText)))
		SELECT @OldPlaceHolder = SUBSTRING(@SegmentText, @I, @K + 1)
		SELECT @tmp = SUBSTRING(@SegmentText, @I, @K)
		SELECT @tmp = LTRIM(RTRIM(REPLACE(@tmp, @OldStringTAG, '')))
		IF ISNUMERIC(@tmp) = 1
			SELECT @ID = @tmp
		
		SET @retString = CAST(@ID AS VARCHAR)
	END
	IF @retString = ''
	BEGIN
		SET @retString = '0'
	END
	RETURN @retString
END
GO
PRINT N'Creating [dbo].[fn_GetRESTempPlaceholder_UserAddedRS]...';


GO

CREATE FUNCTION [dbo].[fn_GetRESTempPlaceholder_UserAddedRS](@Description NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
AS
BEGIN
	--DECLARE @Description AS NVARCHAR(MAX) = '{RSTEMP#10004741}' --'{RSTEMP#10004741}'
	DECLARE @ID INT = 0
	, @I INT
	, @K INT
	, @tmp VARCHAR(20) = ''
	, @OldPlaceHolder VARCHAR(20) = ''
	, @ReplaceString NVARCHAR(50)
	, @SegmentText NVARCHAR(MAX) = @Description
	, @retString NVARCHAR(MAX) = ''
	, @OldChoice VARCHAR(50) = ''
	, @OldStringTAG NVARCHAR(10) = '{RSTEMP#'
	SET @OldChoice = REPLACE(@Description, '}', '')
	IF CHARINDEX(@OldChoice,@SegmentText) > 0
	BEGIN
		SELECT @I = CHARINDEX(@OldChoice,@SegmentText)
		SELECT @K = PATINDEX('%}%',SUBSTRING(@SegmentText, @I + 1, LEN(@SegmentText)))
		SELECT @OldPlaceHolder = SUBSTRING(@SegmentText, @I, @K + 1)
		SELECT @tmp = SUBSTRING(@SegmentText, @I, @K)
		SELECT @tmp = LTRIM(RTRIM(REPLACE(@tmp, @OldStringTAG, '')))
		IF ISNUMERIC(@tmp) = 1
			SELECT @ID = @tmp
		IF CONVERT(INT, REPLACE(@ID, CHAR(0), '')) > 10000000
		BEGIN
			SET @retString = CAST(@ID AS VARCHAR)
		END
	END
	IF @retString = ''
	BEGIN
		SET @retString = '0'
	END
	RETURN @retString
END
GO
PRINT N'Creating [dbo].[fn_ReplaceSLEPlaceHolder]...';


GO

CREATE FUNCTION [dbo].[fn_ReplaceSLEPlaceHolder](@Description NVARCHAR(MAX),@OldStringTAG NVARCHAR(10),@NewStringTAG NVARCHAR(10),@OldID INT,@NewID INT)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	DECLARE @ID INT = 0
	, @I INT
	, @K INT
	, @tmp VARCHAR(20) = ''
	, @OldPlaceHolder VARCHAR(20) = ''
	, @ReplaceString NVARCHAR(50)
	, @SegmentText NVARCHAR(MAX) = @Description
	, @retString NVARCHAR(MAX) = ''
	, @OldChoice VARCHAR(20) = ''

	SET @OldChoice = @OldStringTAG + CAST(@OldID AS NVARCHAR)
	IF CHARINDEX(@OldChoice,@SegmentText) > 0
	BEGIN
		SELECT @I = CHARINDEX(@OldChoice,@SegmentText)
		SELECT @K = PATINDEX('%}%',SUBSTRING(@SegmentText, @I + 1, LEN(@SegmentText)))
		SELECT @OldPlaceHolder = SUBSTRING(@SegmentText, @I, @K + 1)
		SELECT @tmp = SUBSTRING(@SegmentText, @I, @K)
		SELECT @tmp = LTRIM(RTRIM(REPLACE(@tmp, @OldStringTAG, '')))
		IF ISNUMERIC(@tmp) = 1
			SELECT @ID = @tmp

		IF @ID = @OldID
		BEGIN
			SET @ReplaceString = @NewStringTAG + CAST(@NewID AS VARCHAR) + '}'
			SELECT @retString = LTRIM(RTRIM(REPLACE(@Description, @OldPlaceHolder, @ReplaceString)))
		END
	END
	IF @retString = ''
	BEGIN
		SET @retString = @Description
	END
	RETURN @retString
END
GO
PRINT N'Altering [dbo].[usp_GetAllCopyProjectRequestMetricsPerMonth]...';


GO
ALTER proc usp_GetAllCopyProjectRequestMetricsPerMonth  
AS  
BEGIN  
 DECLARE @DATE_BEFORE_YEAR DATETIME=DATEADD(MONTH,-5,GETUTCDATE())  
 SELECT @DATE_BEFORE_YEAR=DATEADD(DAY,0-(DATEPART(DAY,@DATE_BEFORE_YEAR)-1),@DATE_BEFORE_YEAR)  
  
 DECLARE @TODAY DATETIME=GETUTCDATE()  
  
 DECLARE @MONTH AS TABLE(MONTH_NAME NVARCHAR(3))  
 DECLARE @FAILED AS TABLE(CNT INT)  
 DECLARE @TOTAL AS TABLE(CNT INT)  
 --DECLARE @RUNNIG AS TABLE(CNT INT)  
 DECLARE @COMPLETED AS TABLE(CNT INT)  
  
  
 WHILE(@DATE_BEFORE_YEAR<=@TODAY)  
 BEGIN  
  INSERT @MONTH  
  SELECT FORMAT(@DATE_BEFORE_YEAR, 'MMM', 'en-US')  
  
  INSERT @TOTAL  
  SELECT ISNULL(COUNT(1),0) FROM CopyProjectRequest WITH(NOLOCK)  
  WHERE Isdeleted=0 AND --StatusId=3  AND  
  MONTH(CreatedDate)=MONTH(@DATE_BEFORE_YEAR) 
   AND CopyProjectTypeId=1
  
  INSERT @COMPLETED  
  SELECT ISNULL(COUNT(1),0) FROM CopyProjectRequest WITH(NOLOCK)  
  WHERE Isdeleted=0 AND 
  StatusId=3  
  AND  MONTH(CreatedDate)=MONTH(@DATE_BEFORE_YEAR)  
   AND CopyProjectTypeId=1
  INSERT @FAILED  
  SELECT ISNULL(COUNT(1),0) FROM CopyProjectRequest WITH(NOLOCK)  
  WHERE Isdeleted=0 AND 
  StatusId IN(4,5)  
  AND  MONTH(CreatedDate)=MONTH(@DATE_BEFORE_YEAR)  
   AND CopyProjectTypeId=1
  SET @DATE_BEFORE_YEAR=DATEADD(MONTH,1,@DATE_BEFORE_YEAR)  
 END  
 SELECT   
 (SELECT MONTH_NAME FROM @MONTH FOR JSON PATH) as Months,  
 (SELECT * FROM @COMPLETED FOR JSON AUTO) as completed,  
 (SELECT * FROM @FAILED FOR JSON AUTO) as failed,  
 (SELECT * FROM @TOTAL FOR JSON AUTO) AS total  
 FOR JSON PATH,WITHOUT_ARRAY_WRAPPER   
END
GO
PRINT N'Altering [dbo].[usp_GetAllNotifications]...';


GO
ALTER PROCEDURE [dbo].[usp_GetAllNotifications]    
(        
 @CustomerId INT,        
 @UserId INT,        
 @IsSystemManager BIT=0        
)        
AS        
BEGIN        
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())        
     
 DECLARE @RES AS TABLE(RequestId INT,SourceProjectId INT,TargetProjectId INT,TargetSectionId INT,    
       RequestDateTime DATETIME,RequestDateTimeStr NVARCHAR(20),RequestExpiryDateTime DATETIME,    
       StatusId INT,IsNotify BIT,CompletedPercentage INT,[Source] NVARCHAR(200),    
       TaskName nvarchar(500),StatusDescription nvarchar(50),IsOfficeMaster BIT,RequestTypeId INT)    
     
 INSERT INTO @RES    
 SELECT CPR.RequestId      
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
 FROM CopyProjectRequest CPR WITH(NOLOCK)        
 WHERE CPR.CreatedById=@UserId      
 AND ISNULL(CPR.IsDeleted,0)=0        
 AND CPR.CreatedDate> @DateBefore30Days     
 AND CPR.CopyProjectTypeId=1
   
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
 ,'UnArchiveProject' Source    
 ,CPR.ProjectName AS TaskName    
 ,CONVERT(nvarchar(50),'') AS StatusDescription    
 ,0    
 ,CPR.RequestType  
  FROM UnArchiveProjectRequest CPR WITH(NOLOCK)             
  WHERE CPR.SLC_UserId=@UserId       
  AND ISNULL(CPR.IsDeleted,0)=0           
  AND CPR.RequestDate> @DateBefore30Days               
    
 UPDATE t    
 SET t.TaskName=P.Name,    
 t.IsOfficeMaster=p.IsOfficeMaster    
 FROM @RES t INNER JOIN Project P WITH(NOLOCK)         
 ON t.TargetProjectId=P.ProjectId    
 WHERE P.CustomerId=@CustomerId    
 AND t.[Source] in('CopyProject','UnArchiveProject')    
    
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
 AND CPR.[Source]=t.[Source]    
 WHERE CPR.IsNotify = 0    
 AND t.[Source] IN('SpecAPI','Import from Template')   
  
 UPDATE CPR    
 SET CPR.IsNotify = 1    
 ,ModifiedDate = GETUTCDATE()    
 FROM CopyProjectRequest CPR WITH (NOLOCK)    
 INNER JOIN @RES t    
 ON CPR.RequestId = t.RequestId    
 WHERE CPR.IsNotify = 0    
 AND t.[Source] ='CopyProject'  
 AND CPR.CopyProjectTypeId=1
  
 UPDATE CPR    
 SET CPR.IsNotify = 1    
 ,ModifiedDate = GETUTCDATE()    
 FROM UnArchiveProjectRequest CPR WITH (NOLOCK)    
 INNER JOIN @RES t    
 ON CPR.RequestId = t.RequestId    
 WHERE CPR.IsNotify = 0    
 AND t.[Source] ='UnArchiveProject'  
  
  UPDATE t    
  SET t.StatusDescription=LCS.StatusDescription    
  FROM @RES t INNER JOIN LuCopyStatus LCS WITH(NOLOCK)         
  ON t.StatusId=LCS.CopyStatusId    
  
  SELECT * FROM @RES    
  ORDER BY RequestDateTimeStr DESC    
  --Check type sorting performance    
    
END
GO
PRINT N'Altering [dbo].[usp_GetCopyProjectProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_GetCopyProjectProgress]    
@UserId INT        
AS        
BEGIN    
--find and mark as failed copy project requests which running loner(more than 30 mins)        
    
UPDATE cpr
	SET cpr.StatusId=5
		,cpr.IsNotify=0
		,cpr.IsEmailSent=0
		,ModifiedDate=GETUTCDATE()
	FROM CopyProjectRequest cpr WITH(nolock) INNER JOIN CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2      AND CopyProjectTypeId=1
    
SELECT    
 CPR.RequestId    
   ,CPR.SourceProjectId    
   ,CPR.TargetProjectId    
   ,CPR.CreatedById    
   ,CPR.CustomerId    
   ,P.Name    
   ,P.IsOfficeMaster    
   ,CPR.CompletedPercentage    
   ,CPR.StatusId    
   ,CPR.CreatedDate    
	,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
   ,LCS.StatusDescription    
   ,CPR.IsNotify    
   ,CPR.ModifiedDate    
   ,DATEADD(DAY, 30, CPR.CreatedDate) AS RequestExpiryDateTime    
INTO #t    
FROM CopyProjectRequest CPR WITH (NOLOCK)    
INNER JOIN Project P WITH (NOLOCK)    
 ON P.ProjectId = CPR.TargetProjectId    
INNER JOIN LuCopyStatus LCS WITH (NOLOCK)    
 ON LCS.CopyStatusId = CPR.StatusId    
WHERE 
(CPR.IsNotify = 0    
OR DATEADD(SECOND, 7, CPR.ModifiedDate) > GETUTCDATE())    
AND CPR.CreatedById = @UserId    
AND ISNULL(CPR.IsDeleted, 0) = 0 
 AND CPR.CopyProjectTypeId=1
    
UPDATE CPR    
SET CPR.IsNotify = 1    
   ,ModifiedDate = GETUTCDATE()    
FROM CopyProjectRequest CPR WITH (NOLOCK)    
INNER JOIN #t t    
 ON CPR.RequestId = t.RequestId    
WHERE CPR.IsNotify = 0    
    
SELECT    
 *    
FROM #t    
    
    
END
GO
PRINT N'Altering [dbo].[usp_GetCopyProjectRequest]...';


GO
ALTER PROC [dbo].[usp_GetCopyProjectRequest]    
(    
 @CustomerId INT,    
 @UserId INT,    
 @IsSystemManager BIT=0    
)    
AS    
BEGIN    
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())    
 SELECT   
 CPR.RequestId  
,CPR.SourceProjectId  
,CPR.TargetProjectId  
,CPR.CreatedById  
,CPR.CustomerId  
,CPR.CreatedDate  
,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr
,DATEADD(DAY,30,CPR.CreatedDate) AS RequestExpiryDateTime  
,ISNULL(CPR.ModifiedDate,'') as ModifiedDate  
,CPR.StatusId  
,CPR.IsNotify  
,CPR.CompletedPercentage  
,CPR.IsDeleted  
,P.[Name]  
,LCS.Name as StatusDescription  
 FROM CopyProjectRequest CPR WITH(NOLOCK)    
  INNER JOIN Project P WITH(NOLOCK)    
   ON P.ProjectId = CPR.TargetProjectId   
   INNER JOIN LuCopyStatus LCS  WITH(NOLOCK)
   ON LCS.CopyStatusId=CPR.StatusId   
 WHERE CPR.CreatedById=@UserId  
 AND isnull(CPR.IsDeleted,0)=0    
 AND CPR.CreatedDate> @DateBefore30Days   
  AND CPR.CopyProjectTypeId=1
 ORDER by CPR.CreatedDate DESC    
END
GO
PRINT N'Altering [dbo].[usp_GetCopyProjectRequestDetailsMetric]...';


GO
ALTER PROC usp_GetCopyProjectRequestDetailsMetric    
AS    
BEGIN    
 SELECT   
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0) AS TotalRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId=1) AS QueuedRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId=2) AS RunningRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId=3) AS ProcessedRequests,  
 (SELECT COUNT(1) FROM CopyProjectRequest WITH(NOLOCK) WHERE  CopyProjectTypeId=1 AND IsDeleted=0 AND StatusId IN(4,5))  AS FailedRequests,  
 '' AS JsonResponse  
END
GO
PRINT N'Altering [dbo].[usp_GetFilteredCopyProjectDetails]...';


GO
ALTER PROC usp_GetFilteredCopyProjectDetails
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
PRINT N'Altering [dbo].[usp_GetNotificationCount]...';


GO
ALTER PROCEDURE [dbo].[usp_GetNotificationCount]
	@UserId int,
	@CustomerId int
AS
BEGIN
	DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())      

	DECLARE @RES AS Table(CopyProject INT,SpecApiSection INT,CreateSectionFromTemplate INT,UnArchiveProjectsCount INT)
	DECLARE @COUNT INT=0
	INSERT INTO @RES(CopyProject)
	SELECT COUNT(1) FROM CopyProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2)
	AND CP.CreatedDate> @DateBefore30Days   
	AND CP.CopyProjectTypeId=1


	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='SpecAPI' --verify
	AND CP.CreatedDate> @DateBefore30Days   

	UPDATE @RES
	SET SpecApiSection=@COUNT

	SET @COUNT=0
	SELECT @COUNT=COUNT(1) FROM ImportProjectRequest cp WITH(NOLOCK)
	WHERE cp.CreatedById=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2) and Source='Import from Template'
	AND CP.CreatedDate> @DateBefore30Days   

	UPDATE @RES
	SET CreateSectionFromTemplate=@COUNT

	SET @COUNT=0
	SELECT @COUNT=COUNT(1) FROM UnArchiveProjectRequest cp WITH(NOLOCK)
	WHERE cp.SLC_UserId=@UserId AND ISNULL(cp.IsDeleted,0)=0
	AND cp.StatusId IN(1,2)
	AND CP.RequestDate > @DateBefore30Days   

	UPDATE @RES
	SET UnArchiveProjectsCount=@COUNT

	SELECT * FROM @RES
END
GO
PRINT N'Altering [dbo].[usp_GetNotificationProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_GetNotificationProgress]
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
GO
PRINT N'Altering [dbo].[usp_MaintainCopyProjectProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_MaintainCopyProjectProgress]    
@SourceProjectId INT,    
@TargetProjectId INT,    
@CreatedById INT,    
@CustomerId INT,    
@Status INT,    
@CompletedPercentage FLOAT,    
@IsInsertRecord BIT  ,  
@CustomerName NVARCHAR(200),  
@UserName NVARCHAR(200)  
AS    
BEGIN    
IF @IsInsertRecord = 1    
BEGIN    
INSERT INTO CopyProjectRequest (SourceProjectId,    
TargetProjectId,    
CreatedById,    
CustomerId,    
CreatedDate,    
ModifiedDate,    
[StatusId],    
CompletedPercentage,    
IsNotify,    
IsDeleted,  
IsEmailSent,  
CustomerName,  
UserName,CopyProjectTypeId)    
 VALUES (@SourceProjectId,   
 @TargetProjectId,   
 @CreatedById,   
 @CustomerId,   
 GETUTCDATE(),   
 NULL,   
 @Status,   
 @CompletedPercentage,  
 0,  
 0,  
 0,  
 @CustomerName,  
 @UserName,
 1);    
END    
ELSE    
BEGIN    
UPDATE CPR    
SET CPR.[StatusId] = @Status    
   ,CompletedPercentage = @CompletedPercentage    
   ,IsNotify=0    
FROM CopyProjectRequest CPR WITH (NOLOCK)    
WHERE CPR.TargetProjectId = @TargetProjectId    
AND CPR.CustomerId = @CustomerId    
END    
END
GO
PRINT N'Altering [dbo].[usp_SendEmailCopyProjectFailedJob]...';


GO
ALTER PROC [dbo].[usp_SendEmailCopyProjectFailedJob]           
  (              
    @recipients VARCHAR(Max)=''              
 )              
 AS              
 BEGIN        
	 DROP table IF exists #tempStep              
	 DROP TABLE IF EXISTS #failedProject    
	 DECLARE @profileName NVARCHAR(100)=(SELECT TOP 1 name FROM msdb.dbo.sysmail_profile)
	 IF(@profileName is not NULL)
	 BEGIN
		 SELECT cast('' as nvarchar(255)) as ProjectName , ROW_NUMBER() over(order by RequestId) as RowId,*              
		 into #failedProject FROM CopyProjectRequest WITH(NOLOCK)               
		 where IsEmailSent=0 and StatusId IN(4,5) AND ISNULL(IsDeleted,0)=0  AND CopyProjectTypeId=1
 
		 declare @i int=1, @count int=(select count(1) from #failedProject)      
		 IF(@count>0)
		 BEGIN
			 set @recipients= 'Shitaln@varseno.com;pandurangm@varseno.com;sushilb@varseno.com;abhosale@varseno.com;diptik@versionsolutions.com';
			 DECLARE @CustomerId VARCHAR(1000);              
			 DECLARE @projectName VARCHAR(1000);              
			 DECLARE @customerName VARCHAR(1000);              
			 DECLARE @projectId VARCHAR(1000);              
			 DECLARE @userName VARCHAR(1000);              
			 DECLARE @userId VARCHAR(1000);              
			 DECLARE @failedStep VARCHAR(1000);              
			 DECLARE @heading VARCHAR(1000)='Copy Project Process Has';              
			 DECLARE @subtitle VARCHAR(1000) = 'See the copy project failure details below: ';              
			 DECLARE @subject NVARCHAR(100) = 'BSD Copy Project: Failure'             
			 DECLARE @failureTime DateTime  = '';              
			 DECLARE @statusDescription VARCHAR(1000)='';        
               
		          
              
			 CREATE TABLE #tempStep(StepID INT,StepName NVARCHAR(100))              
               
			 INSERt into #tempStep VALUES(1,'Project Create')              
			 INSERt into #tempStep VALUES(2,'CopyStart_Step')              
			 INSERt into #tempStep VALUES(3,'CopyGlobalTems_Step')              
			 INSERt into #tempStep VALUES(4,'CopySections_Step')              
			 INSERt into #tempStep VALUES(5,'CopySegmentStatus_Step')              
			 INSERt into #tempStep VALUES(6,'CopySegments_Step')              
			 INSERt into #tempStep VALUES(7,'CopySegmentChoices_Step')              
			 INSERt into #tempStep VALUES(8,'CopySegmentLinks_Step')              
			 INSERt into #tempStep VALUES(9,'CopyNotes_Step')              
			 INSERt into #tempStep VALUES(10,'CopyImages_Step')              
			 INSERt into #tempStep VALUES(11,'CopyRefStds_Step')              
			 INSERt into #tempStep VALUES(12,'CopyTags_Step')              
			 INSERt into #tempStep VALUES(13,'CopyHeaderFooter_Step')              
			 INSERt into #tempStep VALUES(14,'CopyComplete_Step')              
              
               
			 update t              
			 set t.ProjectName=p.Name              
			 from #failedProject t inner join Project p WITH(NOLOCK)              
			 ON p.ProjectId=t.TargetProjectId              
              
        
			 DECLARE @Body NVARCHAR(MAX),              
			  @TableHead VARCHAR(1000)='',              
			  @TableTail VARCHAR(1000)='',              
			  @RequsetId int,              
			  @StepId INT              
              
			 WHILE(@i<=@count)              
			 BEGIN
              
				  select @RequsetId=RequestId,@projectName=ProjectName from #failedProject where RowId=@i              
				  set @StepId=(SELECT MAX(CPH.Step) as StepId FROM CopyProjectHistory CPH with(nolock) where cph.Step<14 and CPH.RequestId=@RequsetId) + 1              
				  SELECT @failedStep = StepName FROM #tempStep where StepID=@StepId              
              
				 SELECT               
				 @CustomerId= ISNULL(CPR.CustomerId,0),              
				 @customerName=ISNULL(CPR.CustomerName,''),              
				 @userId=ISNULL(CPR.CreatedById,0),              
				 @userName=ISNULL(CPR.UserName,''),              
				 @projectId=ISNULL(CPR.TargetProjectId,0),              
				 @failureTime=ISNULL(CPR.ModifiedDate,''),        
				 @StatusDescription = ISNULL(lu.Name,'')        
				 FROM  CopyProjectRequest CPR WITH(NOLOCK) INNER JOIN               
				 CopyProjectHistory CPH WITH(NOLOCK) ON CPR.RequestId = CPH.RequestId           
				 INNER JOIN LuCopyStatus lu WITH(NOLOCK) ON  CPR.StatusId = lu.CopyStatusId          
				 WHERE CPH.RequestId = @RequsetId AND ISNULL(CPR.IsDeleted,0)=0              
				 AND CPR.CopyProjectTypeId=1

				 if(@statusDescription='Aborted')  
				 BEGIN  
				 SET @subject  = 'BSD Copy Project: Taking Longer time than expected'             
				 END  
              
				SET @Body = '<table style="width:100%; background-color:#fff; " border="0" cellpadding="0" cellspacing="0">              
						<tbody>              
							<tr>              
								<td style="vertical-align:top; " align="center" valign="top">              
									<table width="654" border="0" cellpadding="0" cellspacing="0" style="text-align:left; border: 1px solid #dedede;              
									box-shadow: 0 6px 6px #ccc;">              
										<tbody>              
											<tr>              
											<td style="vertical-align:top; padding-top:10px; ">              
									 <table style="width:600px; margin-top:65px; " border="0" cellpadding="0" cellspacing="0">              
														<tbody>             
															<tr>              
																<td style="background-color: #312B7B; vertical-align: top;">              
					<table width="100%" border="0" align="center" cellpadding="0" cellspacing="0" style="width:100%; background-color:#fff;">              
																		<tbody>              
																			<tr>              
																				<td style="vertical-align: middle; text-align: center; "><img src="https://bsdspeclink.com/wp-content/uploads/2018/04/bsd-speclink-logo.png" alt="bsd_full_header"></td>              
																				<td align="center"></td>              
																			</tr>              
																		</tbody>              
																	</table>              
																</td>              
															</tr>              
															<tr>              
																<td style="vertical-align:top; background-color:#FFFFFF;padding:30px 20px 20px; ">              
																	<table width="100%" border="0" cellspacing="0" cellpadding="0">              
				   <tbody>              
				   <tr>              
				   <td valign="top">              
				   <p align="center">              
				   <font size="3" color="#126bb5" style="font-size:18px;border-bottom:2px solid #ccc"><b>{{heading}} {{statusDescription}}</b></font>              
				   </p>              
							<div style="padding:10px 20px 20px;color:#45555f;font-family:Arial,Verdana,Tahoma,Geneva,sans-serif;font-size:14px;line-height:18px;vertical-align:top;min-height:375px">              
								<p align="left">              
									<div style="color:#45555f;">              
										<br>              
										{{subtitle}}              
									</div>              
								</p><p align="left">              
									<div>              
								</p>              
								<div style="color:#45555f;">Customer ID: <b style="color:#000;font-size:14px">{{CustomerId}}</b></div>              
								<div style="color:#45555f;">Customer Name: <b style="color:#000;font-size:14px">{{customerName}}</b></div>              
								<div style="color:#45555f;">Project Name: <b style="color:#000;font-size:14px">{{projectName}}</b></div>              
								<div style="color:#45555f;">Project ID: <b style="color:#000;font-size:14px">{{projectId}}</b></div>              
								<div style="color:#45555f;">Username: <b style="color:#000;font-size:14px">{{userName}}</b></div>              
								<div style="color:#45555f;">User ID: <b style="color:#000;font-size:14px">{{userId}}</b></div>              
								<div style="color:#45555f;">Failed Step: <b style="color:#000;font-size:14px">{{failedStep}}</b></div>           
								<div style="color:#45555f;">Failed Type: <b style="color:#000;font-size:14px">{{statusDescription}}</b></div>              
								<div style="color:#45555f;">Date Time of the process failure:  <b style="color: #000; font-size: 14px"> {{failureTime}} </b></div>              
								</br></br>              
								<span class="HOEnZb">              
									<font color="#888888">              
									</font>              
								</span>              
							</div><span class="HOEnZb"><font color="#888888">              
					   </font></span></td></tr></tbody>              
				   </table></td></tr></tbody></table></td></tr></tbody></table>              
					   <span class="HOEnZb"><font color="#888888">              
					 </font></span></td></tr></tbody></table>              
											 </table>              
												</td>              
											</tr>              
										</tbody>              
									</table>              
								</td>              
							</tr>              
						</tbody>              
					</table>'              
              
				SET @Body = REPLACE(@Body,'{{heading}}',@heading)              
				SET @Body = REPLACE(@Body,'{{CustomerId}}',@CustomerId)              
				SET @Body = REPLACE(@Body,'{{projectName}}',isnull(@projectName,''))              
				SET @Body = REPLACE(@Body,'{{customerName}}',isnull(@customerName,''))              
				SET @Body = REPLACE(@Body,'{{projectId}}',isnull(@projectId,''))              
				SET @Body = REPLACE(@Body,'{{userName}}',isnull(@userName,''))              
				SET @Body = REPLACE(@Body,'{{userId}}',isnull(@userId,''))              
				SET @Body = REPLACE(@Body,'{{failedStep}}',isnull(@failedStep,''))              
				SET @Body = REPLACE(@Body,'{{subtitle}}',isnull(@subtitle,''))              
				SET @Body = REPLACE(@Body,'{{failureTime}}',isnull(convert(varchar, getdate(), 0),''))        
				SET @Body = REPLACE(@Body,'{{statusDescription}}',ISNULL(@statusDescription,''))              
              
              
				SELECT  @Body = @TableHead + ISNULL(@Body, '') + @TableTail                   
				  BEGIN try            
				EXEC msdb.dbo.sp_send_dbmail              
					@profile_name = @profileName
				  , @recipients = @recipients              
				  , @subject = @subject              
				  , @body=@Body               
				   ,@body_format = 'HTML';              
				  END TRY            
				  BEGIN CATCH            
				  END CATCH            
				   UPDATE CPR SET CPR.IsEmailSent= 1 FROM CopyProjectRequest CPR with(nolock) WHERE CPR.RequestId=@RequsetId              
				  set @i=@i+1              
			END 
		END
	 END
END
GO
PRINT N'Altering [dbo].[usp_UpdateCopyProjectStepProgress]...';


GO
ALTER PROCEDURE [dbo].[usp_UpdateCopyProjectStepProgress]
AS
BEGIN

   	--find and mark as failed copy project requests which running loner(more than 30 mins)
	SELECT cpr.RequestId into #longRunningRequests
	FROM dbo.CopyProjectRequest cpr WITH(nolock) 
	INNER JOIN dbo.CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 
	AND CPR.CopyProjectTypeId=1
	and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2

	IF(EXISTS(select top 1 1 from #longRunningRequests))
	BEGIN
		UPDATE cpr
		SET cpr.StatusId=5
			,cpr.IsNotify=0
			,cpr.IsEmailSent=0
			,cpr.ModifiedDate=GETUTCDATE()
		FROM dbo.CopyProjectRequest cpr WITH(nolock) 
		INNER JOIN #longRunningRequests cph WITH(NOLOCK)
		ON cpr.RequestId=cph.RequestId
	END
END;
GO
PRINT N'Altering [dbo].[usp_UpdateLongRunningRequestsASFailed]...';


GO
ALTER PROCEDURE [dbo].[usp_UpdateLongRunningRequestsASFailed]
AS
BEGIN
	UPDATE cpr
	SET cpr.StatusId=5
		,cpr.IsNotify=0
		,cpr.IsEmailSent=0
		,ModifiedDate=GETUTCDATE()
	FROM CopyProjectRequest cpr WITH(nolock) INNER JOIN CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2  AND cpr.CopyProjectTypeId=1


END
GO
PRINT N'Altering [dbo].[usp_GetSubmittalsLog]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSubmittalsLog]    
 -- exec [dbo].[usp_GetSubmittalsLog]  6067,2227,1    
 @ProjectId INT ,   
 @CustomerID INT,   
 @IsIncludeUntagged BIT   
AS   
  
BEGIN  
 DECLARE @PProjectId INT = @ProjectId;  
 DECLARE @PCustomerID INT = @CustomerID;  
 DECLARE @PIsIncludeUntagged BIT = @IsIncludeUntagged;  
  
-- SET NOCOUNT ON added to prevent extra result sets from   
  
-- interfering with SELECT statements.   
SET NOCOUNT ON;  
 -- Insert statements for procedure here   
DECLARE @SubmittalsWord NVARCHAR(1024) = 'submittals';  
DECLARE @ProjectName NVARCHAR(500)='';  
--DECLARE @ProjectSourceTagFormate NVARCHAR(MAX)='';  
Declare @SourceTagFormat  VARCHAR(10);  
Declare @UnitOfMeasureValueTypeId int;  
DECLARE @RequirementsTagTbl TABLE (   
TagType NVARCHAR(5),   
RequirementTagId INT   
);  
  
DROP TABLE IF EXISTS #SegmentsTable;  
CREATE TABLE #SegmentsTable (  
 SourceTag VARCHAR(10)  
   ,SectionId INT  
   ,Author NVARCHAR(500)  
   ,Description NVARCHAR(MAX)  
   ,SegmentStatusId INT  
   ,mSegmentStatusId INT  
   ,SegmentId INT  
   ,mSegmentId INT  
   ,SegmentSource CHAR(1)  
   ,SegmentOrigin CHAR(1)  
   ,SegmentDescription NVARCHAR(MAX)  
   ,RequirementTagId INT  
   ,TagType NVARCHAR(5)  
   ,SortOrder INT  
   ,SequenceNumber DECIMAL(18, 4)  
   ,IsSegmentStatusActive INT  
   ,ProjectName NVARCHAR(500)  
   ,ParentSegmentStatusId INT  
   ,IndentLevel INT  
   ,IsDeleted BIT NULL  
   ,SourceTagFormat VARCHAR(10)  
   ,UnitOfMeasureValueTypeId INT  
   ,mSegmentRequirementTagId INT  
);  
  
--CREATE TABLE #ProjectInfo (  
-- ProjectId INT  
--   ,SourceTagFormat NVARCHAR(MAX)  
--   ,UnitOfMeasureValueTypeId INT  
--)  
  
--SET VARIABLES TO DEFAULT VALUE   
  
DROP TABLE IF EXISTS #Tags;  
CREATE TABLE #Tags (  
 TagType NVARCHAR(2)  
)  
  
INSERT INTO #Tags  
 SELECT  
  *  
 FROM STRING_SPLIT('CT,DC,FR,II,IQ,LR,XM,MQ,MO,OM,PD,PE,PR,QS,SA,SD,TR,WE,WT,WS,S1,S2,S3,S4,S5,S6,S7,NS,NP', ',')  
  
INSERT INTO @RequirementsTagTbl (RequirementTagId, TagType)  
 SELECT  
  RequirementTagId  
    ,rt.TagType  
 FROM [dbo].[LuProjectRequirementTag] AS rt WITH (NOLOCK)  
 INNER JOIN #Tags AS t  
  ON t.TagType = rt.TagType  
  
--WHERE TagType IN ('CT', 'DC', 'FR', 'II', 'IQ', 'LR', 'XM', 'MQ', 'MO', 'OM', 'PD', 'PE', 'PR', 'QS',  
--'SA', 'SD', 'TR', 'WE', 'WT', 'WS', 'S1', 'S2', 'S3', 'S4', 'S5', 'S6', 'S7', 'NS', 'NP');  
--SET @ProjectName = (SELECT  
--  [Name]  
-- FROM Project WITH (NOLOCK)  
-- WHERE ProjectId = @PProjectId);  
  
--INSERT INTO #ProjectInfo  
SELECT  
 @ProjectName = pt.Name  
   ,@SourceTagFormat = SourceTagFormat  
   ,@UnitOfMeasureValueTypeId = UnitOfMeasureValueTypeId  
FROM ProjectSummary ps WITH (NOLOCK)  
INNER JOIN Project pt WITH (NOLOCK)  
 ON ps.ProjectId = pt.ProjectId  
WHERE ps.ProjectId = @PProjectId;  
  
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatusView;  
SELECT  
 * INTO #tmp_ProjectSegmentStatusView  
FROM ProjectSegmentStatusView PSSTV  WITH (NOLOCK)  
WHERE PSSTV.ProjectId = @PProjectId  
AND PSSTV.CustomerId = @PCustomerID  
AND PSSTV.IsSegmentStatusActive = 1;  
  
DROP TABLE IF EXISTS #tmp_ProjectSegmentRequirementTag;  
SELECT  
 PSRT.* INTO #tmp_ProjectSegmentRequirementTag  
FROM ProjectSegmentRequirementTag PSRT  WITH (NOLOCK)  
WHERE PSRT.ProjectId = @PProjectId  
AND PSRT.CustomerId = @PCustomerID;  
  
--1. FIND PARAGRAPHS WHICH ARE TAGGED BY GIVEN REQUIREMENTS TAGS  
WITH TaggedSegmentsCte  
AS  
(SELECT  
  PSSTV.SegmentStatusId  
    ,PSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)  
 INNER JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId  
 INNER JOIN @RequirementsTagTbl TagTbl  
  ON PSRT.RequirementTagId = TagTbl.RequirementTagId  
 WHERE PSSTV.ProjectId = @PProjectId  
 AND PSSTV.IsParentSegmentStatusActive = 1  
 AND PSSTV.SegmentStatusTypeId < 6  
 UNION ALL  
 SELECT  
  CPSSTV.SegmentStatusId  
    ,CPSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)  
 INNER JOIN TaggedSegmentsCte TSC  
  ON CPSSTV.ParentSegmentStatusId = TSC.SegmentStatusId  
 WHERE CPSSTV.IsParentSegmentStatusActive = 1  
 AND CPSSTV.SegmentStatusTypeId < 6)  
  
INSERT INTO #SegmentsTable (SourceTag, SectionId, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId  
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, ProjectName  
, ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat, UnitOfMeasureValueTypeId, mSegmentRequirementTagId)  
 SELECT DISTINCT  
  PS.SourceTag  
    ,PS.SectionId  
    ,PS.Author  
    ,PS.[Description]  
    ,PSSTV.SegmentStatusId  
    ,PSSTV.mSegmentStatusId  
    ,PSSTV.SegmentId  
    ,PSSTV.mSegmentId  
    ,PSSTV.SegmentSource  
    ,PSSTV.SegmentOrigin  
    ,PSSTV.SegmentDescription  
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId  
    ,ISNULL(LPRT.TagType, '') AS TagType  
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder  
    ,PSSTV.SequenceNumber  
    ,PSSTV.IsSegmentStatusActive  
    ,@ProjectName  
    ,PSSTV.ParentSegmentStatusId  
    ,PSSTV.IndentLevel  
    ,CASE  
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR  
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1  
   ELSE 0  
  END AS IsDeleted  
    ,@SourceTagFormat  
  AS SourceTagFormat  
    ,@UnitOfMeasureValueTypeId  
  AS UnitOfMeasureValueTypeId  
    ,PSRT.mSegmentRequirementTagId  
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)  
 INNER JOIN TaggedSegmentsCte TSC  
  ON PSSTV.SegmentStatusId = TSC.SegmentStatusId  
 INNER JOIN ProjectSection PS WITH (NOLOCK)  
  ON PSSTV.SectionId = PS.SectionId  
  AND ISNULL(Ps.IsDeleted,0)=0
 LEFT JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId  
 LEFT JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)  
  ON PSRT.RequirementTagId = LPRT.RequirementTagId;  
  
--2. FIND SUBMITTALS ARTICLE PARAGRAPHS   
WITH SubmittlesChildCte  
AS  
(SELECT  
  CPSSTV.SegmentStatusId  
    ,CPSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView PSSTV  
 INNER JOIN #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = CPSSTV.ParentSegmentStatusId  
 WHERE PSSTV.ProjectId = @PProjectId  
 AND PSSTV.CustomerId = @PCustomerID  
 AND PSSTV.SegmentDescription LIKE '%' + @SubmittalsWord  
 AND PSSTV.IndentLevel = 2  
 AND CPSSTV.IsSegmentStatusActive = 1  
 UNION ALL  
 SELECT  
  CPSSTV.SegmentStatusId  
    ,CPSSTV.ParentSegmentStatusId  
 FROM #tmp_ProjectSegmentStatusView CPSSTV WITH (NOLOCK)  
 INNER JOIN SubmittlesChildCte SCC  
  ON CPSSTV.ParentSegmentStatusId = SCC.SegmentStatusId  
 WHERE CPSSTV.IsParentSegmentStatusActive = 1  
 AND CPSSTV.SegmentStatusTypeId < 6)  
  
INSERT INTO #SegmentsTable (SourceTag, Author, [Description], SegmentStatusId, mSegmentStatusId, SegmentId, mSegmentId  
, SegmentSource, SegmentOrigin, SegmentDescription, RequirementTagId, TagType, SortOrder, SequenceNumber, IsSegmentStatusActive, 
ParentSegmentStatusId, IndentLevel, IsDeleted, SourceTagFormat, UnitOfMeasureValueTypeId, mSegmentRequirementTagId)  
 SELECT DISTINCT  
  PS.SourceTag  
    ,PS.Author  
    ,PS.[Description]  
    ,PSSTV.SegmentStatusId  
    ,PSSTV.mSegmentStatusId  
    ,PSSTV.SegmentId  
    ,PSSTV.mSegmentId  
    ,PSSTV.SegmentSource  
    ,PSSTV.SegmentOrigin  
    ,PSSTV.SegmentDescription  
    ,ISNULL(PSRT.RequirementTagId, 0) AS RequirementTagId  
    ,ISNULL(LPRT.TagType, '') AS TagType  
    ,ISNULL(LPRT.SortOrder, 0) AS SortOrder  
    ,PSSTV.SequenceNumber  
    ,PSSTV.IsSegmentStatusActive  
    ,PSSTV.ParentSegmentStatusId  
    ,PSSTV.IndentLevel  
    ,CASE  
   WHEN ISNULL(LPRT.TagType, '') = 'NS' OR  
    ISNULL(LPRT.TagType, '') = 'NP' THEN 1  
   ELSE 0  
  END AS IsDeleted  
    ,@SourceTagFormat  
  AS SourceTagFormat  
    ,@UnitOfMeasureValueTypeId  
  AS UnitOfMeasureValueTypeId  
    ,PSRT.mSegmentRequirementTagId  
 FROM #tmp_ProjectSegmentStatusView PSSTV WITH (NOLOCK)  
 INNER JOIN SubmittlesChildCte SCC WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = SCC.SegmentStatusId  
 INNER JOIN ProjectSection PS WITH (NOLOCK)  
  ON PSSTV.SectionId = PS.SectionId  
 LEFT JOIN #tmp_ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
  ON PSSTV.SegmentStatusId = PSRT.SegmentStatusId  
 LEFT JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)  
  ON PSRT.RequirementTagId = LPRT.RequirementTagId  
  
;  
WITH cte  
AS  
(SELECT  
  s.SegmentStatusId  
    ,s.ParentSegmentStatusId  
    ,s.isDeleted  
 FROM #SegmentsTable AS s  
 WHERE s.isDeleted = 1  
 UNION ALL  
 SELECT  
  s.SegmentStatusId  
    ,s.ParentSegmentStatusId  
    ,CONVERT(BIT, 1) AS isDeleted  
 FROM #SegmentsTable AS s  
 INNER JOIN cte AS c  
  ON s.ParentSegmentStatusId = c.SegmentStatusId)  
  
DELETE s  
 FROM cte  
 INNER JOIN #SegmentsTable AS s  
  ON cte.SegmentStatusId = s.SegmentStatusId;  
  
--DELETE FROM #SegmentsTable  
--WHERE TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
  
--new changes--  
--Start change--  
DELETE FROM #SegmentsTable  
WHERE ParentSegmentStatusId NOT IN (SELECT  
   SegmentStatusId  
  FROM #SegmentsTable)  
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
  
DELETE FROM #SegmentsTable  
WHERE SequenceNumber IN (SELECT  
   SequenceNumber  
  FROM #SegmentsTable  
  GROUP BY SequenceNumber  
  HAVING COUNT(1) > 1)  
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
 AND mSegmentRequirementTagId IS NOT NULL  
  
DELETE FROM #SegmentsTable  
WHERE SegmentStatusId IN (SELECT  
   SegmentStatusId  
  FROM #SegmentsTable  
  WHERE TagType NOT IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP'))  
 AND TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP');  
  
UPDATE #SegmentsTable  
SET TagType = ''  
WHERE TagType IN ('RS', 'RT', 'RE', 'ST', 'PI', 'ML', 'MT', 'PL', 'FT', 'SQ', 'PP')  
--End Change--  
  
DELETE FROM #SegmentsTable  
WHERE @PIsIncludeUntagged = 0  
 AND TagType = '';  
  
--SELECT FINAL DATA  
IF (NOT EXISTS (SELECT  
  1  
 FROM #SegmentsTable)  
)  
BEGIN  
INSERT INTO #SegmentsTable (ProjectName)  
 VALUES (@ProjectName)  
END  
  
--ELSE   
  
--BEGIN   
  
SELECT  
dbo.[fnGetSegmentDescriptionTextForRSAndGT](@PProjectId, @PCustomerID, STbl.SegmentDescription) AS SegmentText  
   ,STbl.Description as SectionName, ISNULL(STbl.SegmentStatusId,0) as SegmentStatusId,STbl.SequenceNumber, STbl.SourceTag
   ,STbl.TagType as RequirementTag,STbl.ProjectName,STbl.Author,STbl.SourceTagFormat as SourceTagFormate,isnull(STbl.UnitOfMeasureValueTypeId,0) as UnitOfMeasureValueTypeId
FROM #SegmentsTable STbl  
WHERE STbl.ProjectName IS NOT NULL  
ORDER BY STbl.SourceTag ASC, STbl.SequenceNumber ASC, STbl.SortOrder ASC;  
  
--END   
  
SELECT  
 SCView.SegmentStatusId, SCView.SegmentChoiceCode, SCView.SectionId,SCView.ChoiceTypeId
 ,SCView.ChoiceOptionCode, SCView.SortOrder, SCView.ChoiceOptionSource
 ,SCView.OptionJson INTO #DapperChoiceTbl
FROM  SegmentChoiceView SCView WITH (NOLOCK)  
WHERE SCView.IsSelected = 1  
AND SCView.SegmentStatusId  IN (SELECT DISTINCT  
  SegmentStatusId  
 FROM #SegmentsTable)  

 SELECT 
 ISNULL(SegmentStatusId,0) as SegmentStatusId
 ,ISNULL(SegmentChoiceCode,0)as SegmentChoiceCode
 ,ISNULL(SectionId,0)as SectionId
 ,ISNULL(ChoiceTypeId,0) as ChoiceTypeId
 FROM #DapperChoiceTbl
  
 SELECT 
 ISNULL(SegmentChoiceCode,0) as SegmentChoiceCode
 ,ISNULL(ChoiceOptionCode,0) as ChoiceOptionCode
 ,SortOrder
 ,COALESCE(ChoiceOptionSource,'') as ChoiceOptionSource
 ,ISNULL(SectionId,0) as SectionId
 ,OptionJson
 FROM #DapperChoiceTbl

SELECT DISTINCT  
 (PS.SectionId)  
   ,COALESCE(PS.SourceTag,'')  as SourceTag 
   ,COALESCE(PS.Description ,'')as Description
   ,ISNULL(PS.SectionCode,0)  as SectionCode
FROM ProjectSection PS WITH (NOLOCK)  
WHERE PS.ProjectId = @PProjectId  
AND PS.CustomerId = @PCustomerID  
  
END
GO
PRINT N'Altering [dbo].[usp_CreateGlobalTerms]...';


GO
ALTER PROCEDURE [dbo].[usp_CreateGlobalTerms]     
(  
 @Name  NVARCHAR(max) NULL,    
 @Value NVARCHAR(max) NULL,    
 @CreatedBy INT NULL,    
 @CustomerId INT NULL,    
 @ProjectId INT NULL    
)  
AS          
BEGIN    
    
 DECLARE @PName NVARCHAR(max) = @Name;    
 DECLARE @PValue NVARCHAR(max) = @Value;    
 DECLARE @PCreatedBy INT = @CreatedBy;    
 DECLARE @PCustomerId INT = @CustomerId;    
 DECLARE @PProjectId INT = @ProjectId;    
   
 SET NOCOUNT ON;    
    
  
  DECLARE @GlobalTermCode INT = 0;    
  DECLARE @UserGlobalTermId INT = NULL    
  DECLARE @MaxGlobalTermCode INT = (SELECT TOP 1 GlobalTermCode FROM ProjectGlobalTerm WITH(NOLOCK) WHERE CustomerId = @PCustomerId ORDER BY GlobalTermCode DESC);  
    
  DECLARE @MinGlobalTermCode INT = 10000000;    
  IF(@MaxGlobalTermCode < @MinGlobalTermCode)    
   BEGIN  
   SET @MaxGlobalTermCode = @MinGlobalTermCode;  
   END  
    
 INSERT INTO [UserGlobalTerm] ([Name], [Value], CreatedDate, CreatedBy, CustomerId, ProjectId, IsDeleted)    
 VALUES (@PName, @PValue, GETUTCDATE(), @PCreatedBy, @PCustomerId, @PProjectId, 0);  
 SET @UserGlobalTermId = SCOPE_IDENTITY();  
    
 SET @MaxGlobalTermCode = @MaxGlobalTermCode + 1;  
  
 INSERT INTO [ProjectGlobalTerm] (ProjectId, CustomerId, [Name], [Value], GlobalTermSource, CreatedDate, CreatedBy, UserGlobalTermId, GlobalTermCode)    
  SELECT    
   P.ProjectId  
  ,@PCustomerId AS CustomerId  
  ,@PName AS [Name]  
  ,@PValue AS [Value]  
  ,'U' AS GlobalTermSource   
  ,GETUTCDATE() AS CreatedDate  
  ,@PCreatedBy AS CreatedBy    
  ,@UserGlobalTermId AS UserGlobalTermId   
  ,@MaxGlobalTermCode AS GlobalTermCode  
  FROM Project P WITH(NOLOCK)  
  WHERE P.CustomerId = @PCustomerId AND ISNULL(P.IsDeleted, 0) = 0;  
    
 SELECT @MaxGlobalTermCode AS GlobalTermCode;  
    
END
GO
PRINT N'Altering [dbo].[usp_GetCoverSheetDetails]...';


GO
ALTER PROCEDURE [dbo].[usp_GetCoverSheetDetails]         
 @ProjectId INT,            
 @CustomerID INT          
AS            
BEGIN      
        
 DECLARE @PProjectId INT = @ProjectId;      
        
 DECLARE @PCustomerID INT = @CustomerID;      
         

 DECLARE @ActiveSectionCount INT=0;      
        
 DECLARE @Temp NVARCHAR(50)      
      
--Set @ActiveSectionCount        
SET @ActiveSectionCount = (SELECT      
  COUNT(PS.SectionId) AS OpenSectionCount      
 FROM ProjectSection PS WITH (NOLOCK)      
 INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK)      
  ON PS.SectionId = PSS.SectionId     
  AND PS.ProjectId=PSS.ProjectId 
 WHERE  PS.ProjectId = @PProjectId  
 --AND PS.CustomerId = @CustomerID
 AND ISNULL(PSS.ParentSegmentStatusId,0)=0
 AND PSS.IndentLevel = 0      
 AND PS.IsLastLevel = 1      
 AND PSS.SequenceNumber = 0      
 AND ISNULL(PS.IsDeleted,0) = 0      
 AND PSS.SegmentStatusTypeId < 6      
 GROUP BY PS.ProjectId);      
--Selects Project Deatils            
SELECT     
 P.[Name] as ProjectName     
   ,P.ProjectId as ProjectNumber     
   ,CASE      
  WHEN LC.city = 'Undefined' THEN PA.CityName   
  ELSE LC.city      
 END AS city      
   ,CASE      
  WHEN LSP.StateProvinceName = 'Undefined' THEN PA.StateProvinceName     
  ELSE LSP.StateProvinceName      
 END AS State      
   ,LCO.CountryName  as Country    
   ,LF.[Description] AS WorkType      
   ,LP.[Description] AS ProjectType      
   ,LPS.SizeDescription AS Size      
   ,LPC.CostDescription AS Cost      
   ,P.CreateDate    as CreatedDate  
   ,ISNULL(@ActiveSectionCount,0) AS ActiveSectionCount      
   ,CASE      
  WHEN LPU.ProjectUoMId = 1 THEN 'm²'      
  WHEN LPU.ProjectUoMId = 2 THEN 'sq.ft.'      
 END AS SizeAbbreviation      
   ,LPU.ProjectUoMId      
   ,PS.SourceTagFormat      
   ,LCO.CurrencyAbbreviation    
FROM PROJECT P WITH (NOLOCK)      
INNER JOIN [ProjectSummary] PS WITH (NOLOCK)      
 ON PS.ProjectId = P.projectId      
INNER JOIN [ProjectAddress] PA WITH (NOLOCK)      
 ON PA.PROJECTID = P.PROJECTID      
INNER JOIN LuCountry LCO WITH (NOLOCK)      
 ON LCO.CountryId = PA.CountryId      
INNER JOIN Lucity LC WITH (NOLOCK)      
 ON LC.cityId = (CASE  
    WHEN PA.cityId IS NULL THEN '99999999'  
    ELSE PA.cityId   
 END)  
INNER JOIN LuStateProvince LSP WITH (NOLOCK)      
 ON LSP.StateProvinceID =  (CASE  
    WHEN PA.StateProvinceId IS NULL THEN '99999999'  
    ELSE PA.StateProvinceId   
 END)  
  
INNER JOIN LuFacilityType LF WITH (NOLOCK)      
 ON LF.FacilityTypeId = PS.FacilityTypeId      
INNER JOIN LuProjectType LP WITH (NOLOCK)      
 ON LP.ProjectTypeId = PS.ProjectTypeId      
INNER JOIN LuProjectSize LPS WITH (NOLOCK)      
 ON LPS.SizeId = PS.ActualSizeId      
INNER JOIN LuProjectCost LPC WITH (NOLOCK)      
 ON LPC.CostId = PS.ActualCostId      
INNER JOIN LuProjectUoM LPU WITH (NOLOCK)      
 ON LPU.ProjectUoMId = PS.SizeUoM      
--INNER JOIN ProjectSummary PSM ON PSM.ProjectId = P.ProjectId            
WHERE P.ProjectId = @PProjectId      
AND P.CustomerId = @PCustomerId      
END
GO
PRINT N'Altering [dbo].[usp_GetMigrationProjectsForPDFGeneration]...';


GO
--ALTER PROCEDURE [dbo].[usp_GetMigrationProjectsForPDFGeneration] 
          
--AS          
--BEGIN 

--    SELECT ProjectId,CustomerId,P.Name AS ProjectName,ISNULL(AP.ArchiveProjectId,0) AS ArchiveProjectId, slc_prodprojectid
--	FROM [dbo].Project P WITH(NOLOCK)
--	LEFT OUTER JOIN	[ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH(NOLOCK) 
--		ON P.ProjectId =AP.slc_prodprojectid and P.CustomerId=AP.SLC_CustomerID
--	WHERE IsShowMigrationPopup = 1 AND
--	ISNULL(PDFGenerationStatusId,0)=0 AND 
--	ISNULL(P.IsDeleted,0)=0 
--END
--GO
PRINT N'Altering [dbo].[usp_GetProjects]...';


GO
ALTER PROCEDURE [dbo].[usp_GetProjects]                    
  @CustomerId INT NULL                                                      
 ,@UserId INT NULL = NULL                                                      
 ,@ParticipantEmailId NVARCHAR(255) NULL = NULL                                                      
 ,@IsDesc BIT NULL = NULL                                                      
 ,@PageNo INT NULL = 1                                                      
 ,@PageSize INT NULL = 100                                                      
 ,@ColName NVARCHAR(255) NULL = NULL                                                      
 ,@SearchField NVARCHAR(255) NULL = NULL                                                      
 ,@DisciplineId NVARCHAR(MAX) NULL = ''                                                      
 ,@CatalogueType NVARCHAR(MAX) NULL = 'FS'                                                      
 ,@IsOfficeMasterTab BIT NULL = NULL                                                      
 ,@IsSystemManager BIT NULL = 0                                                        
AS                                                      
BEGIN                                                    
                                                    
  DECLARE @PCustomerId INT = @CustomerId;                                                    
  DECLARE @PUserId INT = @UserId;                                                    
  DECLARE @PParticipantEmailId NVARCHAR(255) = @ParticipantEmailId;                                                    
  DECLARE @PIsDesc BIT = @IsDesc;                                                    
  DECLARE @PPageNo INT = @PageNo;                                                    
  DECLARE @PPageSize INT = @PageSize;                                                    
  DECLARE @PColName NVARCHAR(255) = @ColName;                                                    
  DECLARE @PSearchField NVARCHAR(255) = @SearchField;                                                    
  DECLARE @PDisciplineId NVARCHAR(MAX) = @DisciplineId;                                                    
  DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                                                    
  DECLARE @PIsOfficeMasterTab BIT = @IsOfficeMasterTab;                                                    
  DECLARE @PIsSystemManager BIT = @IsSystemManager;                                                    
  DECLARE @OpenCommentStatusId INT = 1                                                  
  DECLARE @Order AS INT = CASE @PIsDesc                                                      
    WHEN 1                                                      
  THEN - 1                                                      
    ELSE 1                                                      
    END;                                                    
                                                    
 SET @PsearchField = REPLACE(@PSearchField, '_', '[_]')                              
 SET @PsearchField = REPLACE(@PSearchField, '%', '[%]')                              
  DECLARE @isnumeric AS INT = ISNUMERIC(@PSearchField);                                                    
  IF @PSearchField = ''                                                    
 SET @PSearchField = NULL;                                                    
                                                    
 DECLARE @allProjectCount AS INT = 0;                                                    
 DECLARE @deletedProjectCount AS INT = 0;                                                    
 DECLARE @archivedProjectCount AS INT=0;                                                   
 DECLARE @officeMasterCount AS INT = 0;                                                    
 DECLARE @deletedOfficeMasterCount AS INT = 0;                   
 Declare @incomingProjectCount  AS INT=0;                   
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())              
 DECLARE @StatusCompleted INT =3                
 CREATE TABLE #projectList  (                   
   ProjectId INT                                                      
    ,[Name] NVARCHAR(255)                                                      
    ,[Description] NVARCHAR(255)                                            
    ,IsOfficeMaster BIT                                                      
,TemplateId INT                                                      
    ,CustomerId INT                         
    ,LastAccessed DATETIME2                                                      
    ,UserId INT                                         
    ,CreateDate DATETIME2                                                      
    ,CreatedBy INT                                                      
    ,ModifiedBy INT                                                      
    ,ModifiedDate DATETIME2                                                      
    ,allProjectCount INT                                    
    ,officeMasterCount INT                                                      
    ,deletedOfficeMasterCount INT                   
    ,deletedProjectCount INT                                                      
    ,archivedProjectCount INT                                      
    ,MasterDataTypeId INT                                                      
    ,SpecViewModeId INT                                                      
    ,LastAccessUserId INT                                
    ,IsDeleted BIT                                                      
 ,IsArchived BIT                                      
    ,IsPermanentDeleted BIT                                                      
    ,UnitOfMeasureValueTypeId INT                                                      
    ,ModifiedByFullName NVARCHAR(100)                              
    ,ProjectAccessTypeId INT                                                    
    ,IsProjectAccessible bit                                                     
    ,ProjectAccessTypeName NVARCHAR(100)                                                    
    ,IsProjectOwner BIT                                                    
    ,ProjectOwnerId INT           
    ,CountryName NVARCHAR(255)                               
 ,IsMigrated BIT                           
 ,HasMigrationError BIT DEFAULT 0                        
 ,IsLocked BIT DEFAULT 0                        
 ,LockedBy NVARCHAR(500)                       
 ,LockedDate DateTIme2(7)                        
    )                                                      
                                                    
 IF(@PIsSystemManager=1)                                                    
 BEGIN                                                    
  SET @allProjectCount = COALESCE((SELECT                                                    
    COUNT(P.ProjectId)                                    
   FROM dbo.Project AS P WITH (NOLOCK)                                                    
   WHERE P.customerId = @PCustomerId                                                    
   AND ISNULL(P.IsDeleted,0) = 0                                            
   and ISNULL(p.IsArchived,0)= 0                                              
   AND P.IsOfficeMaster = @PIsOfficeMasterTab                                         
   AND ISNULL( P.IsIncomingProject , 0)=0                             
   AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')                                                
   )                                                    
  , 0);                                                    
                                          
 SET @deletedProjectCount = COALESCE((SELECT                                                    
    COUNT(P.ProjectId)                                                    
   FROM dbo.Project AS P WITH (NOLOCK)                        
  INNER JOIN [ProjectSummary] psm WITH (NOLOCK)      
  ON psm.ProjectId = P.ProjectId                     
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                                    
   AND ISNULL(P.IsDeleted, 0) = 1                                          
   AND P.customerId = @PCustomerId                                                    
   AND ISNULL(P.IsPermanentDeleted, 0) = 0)                                                    
  , 0);                                                   
                                         
    SET @archivedProjectCount = COALESCE((SELECT                                                    
    COUNT(P.ProjectId)                                                 
   FROM dbo.Project AS P WITH (NOLOCK)                                                    
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                                    
 AND  ISNULL(p.IsArchived,0)=1                                      
   AND ISNULL(P.IsDeleted,0)=0                                                 
   AND P.customerId = @PCustomerId                                                    
   ) , 0);                                       
                      
 SET @incomingProjectCount=COALESCE((SELECT COUNT(P.ProjectId) from dbo.Project P              
 WHERE P.IsIncomingProject=1 AND  P.customerId = @PCustomerId                   
 AND ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab  AND ISNULL(P.IsDeleted,0)=0 AND ISNULL(P.IsPermanentDeleted,0)=0                 
 AND P.TransferredDate > @DateBefore30Days ),0);                                   
                              
  SET @officeMasterCount = @allProjectCount;                                                    
  SET @deletedOfficeMasterCount = @deletedProjectCount;                    
                                          
                                      
  INSERT INTO #projectList                                                    
   SELECT                                                    
    p.ProjectId                                                    
      ,LTRIM(RTRIM(p.[Name])) AS [Name]                                                    
      ,p.[Description]                          
      ,p.IsOfficeMaster                                                    
      ,COALESCE(p.TemplateId, 1) TemplateId                                                    
      ,p.customerId                                                    
      ,UF.LastAccessed                                                    
      ,p.UserId                                                    
      ,p.CreateDate                                                    
      ,p.CreatedBy                                                    
      ,p.ModifiedBy                                                    
      ,p.ModifiedDate                          
      ,@allProjectCount AS allprojectcount                                                    
      ,@officeMasterCount AS officemastercount                                                    
      ,@deletedOfficeMasterCount AS deletedOfficeMasterCount                                                    
      ,@deletedProjectCount AS deletedProjectCount                                                    
      ,@archivedProjectCount AS archiveprojectCount                   
   ,p.MasterDataTypeId                                                    
      ,COALESCE(psm.SpecViewModeId, 0) AS SpecViewModeId                                                    
      ,COALESCE(UF.UserId, 0) AS lastaccessuserid                                    
      ,p.IsDeleted                                      
   ,p.IsArchived                                                    
      ,COALESCE(p.IsPermanentDeleted, 0) AS IsPermanentDeleted                                                    
      ,psm.UnitOfMeasureValueTypeId                                                    
      ,COALESCE(UF.LastAccessByFullName, 'NA') AS ModifiedByFullName                                   
      ,psm.projectAccessTypeId                                                    
      ,1 as isProjectAccessible                                                    
      ,'' as projectAccessTypeName                                                    
      ,iif(psm.OwnerId=@UserId,1,0) as IsProjectOwner                                                    
      ,COALESCE(psm.OwnerId,0) AS ProjectOwnerId          
   ,'' AS CountryName                     
   ,P.IsMigrated                          
   ,0 AS HasMigrationError                                        
   ,ISNULL(P.IsLocked,0) as IsLocked                      
   ,ISNULL(P.LockedBy,'') as   LockedBy                     
   ,ISNULL(P.LockedDate,'') as  LockedDate                       
   FROM dbo.Project AS p WITH (NOLOCK)                                                    
   INNER JOIN [dbo].[ProjectSummary] psm WITH (NOLOCK)                                                    
    ON psm.ProjectId = p.ProjectId                                                    
   LEFT JOIN UserFolder UF WITH (NOLOCK)                                                    
    ON UF.ProjectId = P.ProjectId                 
     AND UF.customerId = p.customerId                                                    
   WHERE ISNULL(p.IsDeleted,0)= 0                                 
   and ISNULL(p.IsArchived,0)= 0                                          
   AND p.IsOfficeMaster = @PIsOfficeMasterTab                                                    
   AND p.customerId = @PCustomerId                          
   AND ISNULL( P.IsIncomingProject , 0)=0                              
   AND (@PSearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@PSearchField, p.[Name]) + '%')                                                    
   ORDER BY CASE                                                    
    WHEN @PIsDesc = 1 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'name' THEN P.Name                                                    
     END                       END DESC                                                    
   , CASE                                                    
    WHEN @PIsDesc = 1 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                                                    
     END                                                    
   END DESC                                                    
   , CASE                                                    
    WHEN @PIsDesc = 1 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                                                    
     END                                                    
   END DESC                                                    
   , CASE                                                    
    WHEN @PIsDesc = 0 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'name' THEN P.Name                                                    
     END                                                    
   END                                   
   , CASE                                                    
    WHEN @PIsDesc = 0 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                                                    
     END                                                    
   END                                                    
   , CASE                                                    
    WHEN @PIsDesc = 0 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                                                    
     END                                                    
   END OFFSET @PPageSize * (@PPageNo - 1) ROWS                                
                                                    
   FETCH NEXT @PPageSize ROWS ONLY;                                                    
                                                    
 END                                                    
 ELSE                                                    
 BEGIN                                                    
  CREATE TABLE #AccessibleProjectIds(                                              
   Projectid INT,                                                      
   ProjectAccessTypeId INT,                                                      
   IsProjectAccessible bit,                                                      
   ProjectAccessTypeName NVARCHAR(100)  ,                                                    
   IsProjectOwner BIT                                                    
  );                                                 
                                                      
  ---Get all public,private and owned projects                                                    
  INSERT INTO #AccessibleProjectIds(Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)                                              
  SELECT ps.Projectid,ps.ProjectAccessTypeId,0,'',iif(ps.OwnerId=@UserId,1,0) FROM ProjectSummary ps WITH(NOLOCK)                                                        
  where  (ps.ProjectAccessTypeId in(1,2) or ps.OwnerId=@UserId)                                                    
  AND ps.CustomerId=@PCustomerId                           
                     
  --Update all public Projects as accessible                                                    
  UPDATE t                                                    
  set t.IsProjectAccessible=1                                                    
  from #AccessibleProjectIds t                                                     
  where t.ProjectAccessTypeId=1                                                    
                                                    
  --Update all private Projects if they are accessible                                                    
  UPDATE t        set t.IsProjectAccessible=1                                                    
  from #AccessibleProjectIds t                                                     
  inner join UserProjectAccessMapping u WITH(NOLOCK)                                                    
  ON t.Projectid=u.ProjectId                                                          
  where u.IsActive=1                                                     
  and u.UserId=@UserId and t.ProjectAccessTypeId=2                                                    
  AND u.CustomerId=@PCustomerId                                                        
                                                    
  --Get all accessible projects                                                    
  INSERT INTO #AccessibleProjectIds  (Projectid  ,ProjectAccessTypeId,  IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)                                              
  SELECT ps.Projectid,ps.ProjectAccessTypeId,1,'',iif(ps.OwnerId=@UserId,1,0) FROM ProjectSummary ps WITH(NOLOCK)                                                     
  INNER JOIN UserProjectAccessMapping upam WITH(NOLOCK)                                             
  ON upam.ProjectId=ps.ProjectId                                                  
  LEFT outer JOIN #AccessibleProjectIds t                                                    
  ON t.Projectid=ps.ProjectId                                                    
  where ps.ProjectAccessTypeId=3 AND upam.UserId=@UserId and t.Projectid is null AND ps.CustomerId=@PCustomerId                                                    
  AND(  upam.IsActive=1 OR ps.OwnerId=@UserId)                                                       
                                                    
  UPDATE t                       
  set t.IsProjectAccessible=t.IsProjectOwner                                      
  from #AccessibleProjectIds t                                                     
  where t.IsProjectOwner=1                                                    
                                                    
  SET @allProjectCount = COALESCE((SELECT                                                    
    COUNT(P.ProjectId)                                                    
   FROM dbo.Project AS P WITH (NOLOCK)                                                    
   inner JOIN #AccessibleProjectIds t                                                    
   ON t.Projectid=p.ProjectId                                                    
   WHERE ISNULL(P.IsDeleted,0) = 0                                         
   AND ISNULL(p.IsArchived,0)= 0                                                 
   AND P.IsOfficeMaster = @PIsOfficeMasterTab                                
   AND P.customerId = @PCustomerId                       
   AND ISNULL( P.IsIncomingProject , 0)=0                                               
   AND (@PSearchField IS NULL OR P.[Name] LIKE '%' + COALESCE(@PSearchField, P.[Name]) + '%')                                                
   )                                                  
  , 0);                                                    
                                                     
  SET @deletedProjectCount = COALESCE((SELECT                                                    
    COUNT(P.ProjectId)                                                    
   FROM dbo.Project AS P WITH (NOLOCK)                                                    
   inner JOIN #AccessibleProjectIds t                                                    
   ON t.Projectid=p.ProjectId                                                    
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                                    
   AND ISNULL(P.IsDeleted, 0) = 1                                                    
   AND P.customerId = @PCustomerId                                                    
   AND ISNULL(P.IsPermanentDeleted, 0) = 0)                                                    
  , 0);                                                    
                                                    
  SET @archivedProjectCount = COALESCE((SELECT                                                    
    COUNT(P.ProjectId)                                                    
   FROM dbo.Project AS P WITH (NOLOCK)                                                    
   inner JOIN #AccessibleProjectIds t                                                    
   ON t.Projectid=p.ProjectId                                                    
   WHERE ISNULL(P.IsOfficeMaster, 0) = @PIsOfficeMasterTab                                                    
   AND ISNULL(P.IsArchived, 0) = 1                                          
   and ISNULL(p.IsDeleted,0)=0                                                
   AND P.customerId = @PCustomerId )                               
  , 0);                                                    
                   
 SET @incomingProjectCount=COALESCE((SELECT COUNT(P.ProjectId)            
 from dbo.Project p WITH (NOLOCK)                     
 inner JOIN #AccessibleProjectIds t                                                    
    ON t.Projectid=p.ProjectId                     
 WHERE p.IsIncomingProject=1 AND  p.customerId = @PCustomerId                   
 AND ISNULL(p.IsOfficeMaster, 0) = @PIsOfficeMasterTab  AND ISNULL(p.IsDeleted,0)=0  AND ISNULL(p.IsPermanentDeleted,0)=0               
  AND P.TransferredDate > @DateBefore30Days                
 ),0);            
                                      
  SET @officeMasterCount = @allProjectCount;                                                    
  SET @deletedOfficeMasterCount = @deletedProjectCount;                                                    
                          
   INSERT INTO #projectList                                                    
   SELECT                                                    
    p.ProjectId                                     
      ,LTRIM(RTRIM(p.[Name])) AS [Name]                                                    
      ,p.[Description]                                                    
      ,p.IsOfficeMaster                                                    
      ,COALESCE(p.TemplateId, 1) TemplateId                                                    
      ,p.customerId                                                    
      ,UF.LastAccessed                                                    
      ,p.UserId                                                    
      ,p.CreateDate                                                    
      ,p.CreatedBy                                                    
      ,p.ModifiedBy                                                    
      ,p.ModifiedDate                                                    
      ,@allProjectCount AS allprojectcount                                               
      ,@officeMasterCount AS officemastercount                                                    
      ,@deletedOfficeMasterCount AS deletedOfficeMasterCount                                                    
      ,@deletedProjectCount AS deletedProjectCount                                        
      ,@archivedProjectCount AS archiveProjectcount                     
      ,p.MasterDataTypeId                                                    
      ,COALESCE(psm.SpecViewModeId, 0) AS SpecViewModeId                                                    
      ,COALESCE(UF.UserId, 0) AS lastaccessuserid                                                    
      ,p.IsDeleted                                          
      ,p.IsArchived                                                
      ,COALESCE(p.IsPermanentDeleted, 0) AS IsPermanentDeleted                                                    
      ,psm.UnitOfMeasureValueTypeId                                                    
      ,COALESCE(UF.LastAccessByFullName, 'NA') AS ModifiedByFullName                                      
      ,psm.projectAccessTypeId                                                    
      ,t.isProjectAccessible                                                    
      ,t.projectAccessTypeName                                                    
      ,iif(psm.OwnerId=@UserId,1,0) as IsProjectOwner                                                    
      ,COALESCE(psm.OwnerId,0) AS ProjectOwnerId     
   ,'' AS CountryName                                
   ,P.IsMigrated                          
      ,0 AS HasMigrationError                            
   ,ISNULL(P.IsLocked,0) as IsLocked                      
   ,P.LockedBy as LockedBy                      
   ,P.LockedDate as LockedDate                      
   FROM dbo.Project AS p WITH (NOLOCK)                                                    
   INNER JOIN [dbo].[ProjectSummary] psm WITH (NOLOCK)                                              
    ON psm.ProjectId = p.ProjectId                                                    
   inner JOIN #AccessibleProjectIds t                                                    
   ON t.Projectid=p.ProjectId                                                    
   LEFT JOIN UserFolder UF WITH (NOLOCK)                                                    
    ON UF.ProjectId = P.ProjectId                                                    
     AND UF.customerId = p.customerId                                          
   WHERE p.IsDeleted = 0                                        
   AND ISNULL(p.IsArchived,0)= 0                                           
   AND p.IsOfficeMaster = @PIsOfficeMasterTab                                                    
   AND p.customerId = @PCustomerId                                                   
   AND ISNULL( P.IsIncomingProject , 0)=0                   
   AND (@PSearchField IS NULL OR p.[Name] LIKE '%' + COALESCE(@PSearchField, p.[Name]) + '%')                                                    
   ORDER BY CASE                                                    
    WHEN @PIsDesc = 1 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'name' THEN P.Name                                                    
     END                                                    
   END DESC                                                    
   , CASE                                                    
    WHEN @PIsDesc = 1 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                        
     END                                                   
   END DESC                                                    
   , CASE                                         
    WHEN @PIsDesc = 1 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                                                    
     END                                                    
   END DESC                                                    
   , CASE                                                    
    WHEN @PIsDesc = 0 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'name' THEN P.Name                                            
     END                                            
   END                                                    
   , CASE                                                    
    WHEN @PIsDesc = 0 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'Id' THEN P.[ProjectId]                                                    
     END                                                    
   END                                                    
   , CASE                                                    
    WHEN @PIsDesc = 0 THEN CASE                                                    
      WHEN LOWER(@PColName) = 'createdate' THEN UF.LastAccessed                              
     END                                                    
   END OFFSET @PPageSize * (@PPageNo - 1) ROWS                                                    
                                                    
   FETCH NEXT @PPageSize ROWS ONLY;                                                    
 END                                                    
      
  
  -- Update Project Access Type                                            
  UPDATE t                                                    
  set t.ProjectAccessTypeName=pt.Name                                                    
  from #projectList t inner join LuProjectAccessType pt  WITH (NOLOCK)                                
  on t.ProjectAccessTypeId=pt.ProjectAccessTypeId                                                    
    
    -- Update Country Name  
  UPDATE t                     
  set t.CountryName = lc.CountryName  
  from #projectList t inner join ProjectAddress pa WITH(NOLOCK)  
  on t.ProjectId = pa.ProjectId inner join LuCountry lc WITH(NOLOCK)  
  on pa.CountryId = lc.CountryId;  
  
                                  
 /* Removed old logic                                                
 SELECT                                                    
  ProjectId                                                    
    ,[Name]                                                    
    ,[Description]                                                    
    ,IsOfficeMaster                                                    
    ,TemplateId                                                    
    ,customerId                                                    
    ,LastAccessed                                                    
    ,UserId                                                    
    ,CreateDate                        
    ,CreatedBy                                                    
    ,ModifiedBy                                                    
    ,ModifiedDate                                                    
    ,allProjectCount                                         
    ,officemastercount                                                    
  ,MasterDataTypeId                                                    
    ,SpecViewModeId                                                    
    ,LastAccessUserId                                                    
    ,pl.IsDeleted                                      
    ,pl.IsArchived                                                    
    ,pl.IsPermanentDeleted                                                    
    ,ISNULL(pl.UnitOfMeasureValueTypeId, 0) AS UnitOfMeasureValueTypeId                   
    ,deletedOfficeMasterCount                                                    
    ,deletedProjectCount                                                    
    ,archivedProjectCount                                      
    ,COALESCE(SectionCount, 0) SectionCount                 
    ,ModifiedByFullName                                                    
    ,ProjectAccessTypeId                                                    
    ,IsProjectAccessible                                                    
    ,ProjectAccessTypeName                                                    
    ,pl.IsProjectOwner                                                    
    ,pl.ProjectOwnerId                                                    
 FROM #projectList pl                                                    
 OUTER APPLY (SELECT                                                    
   COALESCE(COUNT(1), 0) SectionCount                                                    
  FROM dbo.ProjectSection AS PS WITH (NOLOCK)                                                    
  INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)                              
   ON PS.SectionId = PsS.SectionId                                      
   AND PS.ProjectId = PsS.ProjectId                                      
   AND PS.customerId = PSs.customerId                                                    
  WHERE PS.customerId = Pl.customerId                                                    
  AND PS.ProjectId = Pl.ProjectId                                                    
  AND PS.IsLastLevel = 1                                                    
  AND PSS.ParentSegmentStatusId = 0                                                    
  AND PSS.SequenceNumber = 0                                                    
  AND (                                                    
  PSS.SegmentStatusTypeId > 0                                                    
  AND PSS.SegmentStatusTypeId < 6             
  )                                                    
  GROUP BY ps.ProjectId) P                                          
     ORDER by LastAccessed desc    */                                    
                                       
 /* New Logic*/                            
                         
                         
UPDATE P                          
SET P.HasMigrationError = 1                          
FROM #projectList P                          
INNER JOIN ProjectMigrationException PME WITH (NOLOCK)                          
 ON PME.ProjectId = P.ProjectId                          
WHERE ISNULL(P.IsMigrated, 0) = 1 AND ISNULL(IsResolved,0)=0                                      
DROP TABLE IF EXISTS #ProjectCommentCount                    
---- To get Project wise Open Segment Comment (i.e. UnResolved - CommentStatusId=1) count                            
--SELECT SC.Projectid,COUNT(SC.SectionId) ProjectCommentCount                   
--INTO #ProjectCommentCount                    
--FROM SegmentComment SC WITH (NOLOCK)                  
--WHERE SC.CustomerId=@CustomerId and SC.CommentStatusId=@OpenCommentStatusId and SC.ParentCommentId=0  and ISNULL(SC.IsDeleted, 0) = 0                   
--GROUP BY SC.ProjectId                   
                  
 ;WITH CTE_SectionCommentCount(ProjectId, ProjectCommentCount)                            
 AS                            
 (Select SC.ProjectId,Count(SC.SectionId) as ProjectCommentCount                             
from #projectList pl with (nolock)                            
INNER JOIN ProjectSection PS with (nolock) ON pl.ProjectId = PS.ProjectId                            
INNER JOIN SegmentComment SC  with (nolock)                            
ON SC.SectionId = PS.SectionId AND SC.ProjectId = pl.ProjectId                            
where SC.CustomerId = @CustomerId                             
AND ISNULL(SC.IsDeleted, 0) = 0                       
AND ISNULL(PS.IsDeleted, 0) = 0                             
AND ps.IsLastLevel = 1                            
AND SC.CommentStatusId=@OpenCommentStatusId                  
AND SC.ParentCommentId=0                   
GROUP by SC.ProjectId,SC.CustomerId)                   
                  
SELECT ProjectId, ProjectCommentCount INTO #ProjectCommentCount FROM CTE_SectionCommentCount                  
                  
 ;WITH CTE_ActiveSection (ProjectId, TotalActiveSection)                       
 AS                            
 (Select PSS.ProjectId,Count(PSS.SectionId) as TotalActiveSections                             
from #projectList pl with (nolock)                            
INNER JOIN ProjectSection PS with (nolock) ON pl.ProjectId = PS.ProjectId                            
INNER JOIN Projectsegmentstatus PSS with (nolock)                            
ON PSS.SectionId = PS.SectionId AND PSS.ProjectId = pl.ProjectId                            
where PSS.CustomerId = @CustomerId                             
AND ISNULL(PSS.ParentSegmentStatusId,0)=0                            
AND PS.IsDeleted = 0                            
AND ps.IsLastLevel = 1                            
and PSS.SequenceNumber = 0 and (                             
PSS.SegmentStatusTypeId > 0                             
AND PSS.SegmentStatusTypeId < 6                             
)                            
GROUP by PSS.ProjectId,PSS.CustomerId)                            
          
                        
 Select                             
     pl.ProjectId                                                  
    ,pl.[Name]                                                  
    ,pl.[Description]                                                  
    ,IsOfficeMaster                                                  
    ,pl.TemplateId                                                  
    ,pl.customerId                                                  
    ,LastAccessed                                                  
    ,pl.UserId                                                  
    ,pl.CreateDate                                                  
    ,pl.CreatedBy                                                  
    ,pl.ModifiedBy                                                  
    ,pl.ModifiedDate                                                  
    ,allProjectCount                                                  
    ,officemastercount                       
    ,MasterDataTypeId                                              
    ,pl.SpecViewModeId                                                  
    ,LastAccessUserId                                                  
    ,pl.IsDeleted                                    
    ,pl.IsArchived                                                  
    ,pl.IsPermanentDeleted                                                  
    ,ISNULL(pl.UnitOfMeasureValueTypeId, 0) AS UnitOfMeasureValueTypeId                                                  
    ,deletedOfficeMasterCount                                                  
    ,deletedProjectCount                                                  
    ,archivedProjectCount                   
    ,COALESCE(X.TotalActiveSection, 0) SectionCount                                                  
    ,ModifiedByFullName                                                  
    ,ProjectAccessTypeId                                                  
    ,IsProjectAccessible                                                  
    ,ProjectAccessTypeName                                                  
    ,pl.IsProjectOwner                                                  
    ,pl.ProjectOwnerId   
 ,pl.CountryName                            
 ,pl.IsMigrated                          
 ,pl.HasMigrationError                          
 ,pl.IsLocked                      
 ,pl.LockedBy                    
 ,pl.LockedDate                    
 ,ISNULL(PSC.ProjectCommentCount,0) ProjectCommentCount                    
 from #projectList pl                            
 LEFT JOIN #ProjectCommentCount PSC ON PSC.ProjectId = pl.ProjectId                    
 LEFT JOIN CTE_ActiveSection X ON pl.ProjectId = X.ProjectId                            
  ORDER by pl.LastAccessed desc                            
                            
 /**New logic end*********/                            
                                       
 SELECT                                                    
     @archivedProjectCount AS ArchiveProjectCount                                      
 ,@deletedProjectCount AS DeletedProjectCount          
    ,@deletedOfficeMasterCount AS DeletedOfficeMasterCount                                        
    ,@officeMasterCount AS OfficeMasterCount                                                    
    ,@allProjectCount AS TotalProjectCount                  
    ,@incomingProjectCount AS IncomingProjectCount;                  
                                                  
END
GO
PRINT N'Altering [dbo].[usp_GetProjectSegmentGlobalTerms]...';


GO
ALTER PROCEDURE [dbo].[usp_GetProjectSegmentGlobalTerms]
@UserGlobalTermId INT NULL,  
@CustomerId INT NULL,  
@ProjectId INT NULL=NULL  
AS         
BEGIN
  
DECLARE @PUserGlobalTermId INT = @UserGlobalTermId;
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PProjectId INT = @ProjectId;

SET NOCOUNT ON;

--FIND INSTANCES USED IN SEGMENTS  
SELECT
DISTINCT
	PSSTV.CustomerId
   ,PSGT.UserGlobalTermId
   ,0 AS GlobalTermCode --NOTE: No need of this value in final result  
   ,PSSTV.SegmentId
   ,0 AS HeaderId
   ,0 AS FooterId
   ,'Segment' AS GlobalTermUsedIn
   ,PSGT.ProjectId INTO #UsedGTTbl
FROM ProjectSegmentGlobalTerm PSGT WITH (NOLOCK)
INNER JOIN ProjectSegment PSSTV WITH (NOLOCK)
	ON PSGT.SegmentId = PSSTV.SegmentId
WHERE PSSTV.CustomerId = @PCustomerId
AND ISNULL(PSSTV.IsDeleted,0) = 0
AND PSGT.UserGlobalTermId = @PUserGlobalTermId
AND ISNULL(PSGT.IsDeleted,0) = 0
UNION
--FIND INSTANCES USED IN HEADER/FOOTER  
SELECT DISTINCT
	HFGTU.CustomerId
   ,HFGTU.UserGlobalTermId
   ,0 AS GlobalTermCode --NOTE: No need of this value in final result  
   ,0 AS SegmentId
   ,ISNULL(HFGTU.HeaderId, 0) AS HeaderId
   ,ISNULL(HFGTU.FooterId, 0) AS FooterId
   ,(CASE
		WHEN HFGTU.HeaderId IS NOT NULL AND
			HFGTU.HeaderId > 0 THEN 'Header'
		WHEN HFGTU.FooterId IS NOT NULL AND
			HFGTU.FooterId > 0 THEN 'Footer'
		ELSE ''
	END) AS GlobalTermUsedIn
   ,HFGTU.ProjectId
FROM HeaderFooterGlobalTermUsage HFGTU WITH (NOLOCK)
WHERE HFGTU.CustomerId = @PCustomerId
AND HFGTU.UserGlobalTermId = @PUserGlobalTermId

--SELECT * from #UsedGTTbl
--Added this change to filter used GT from Permanently Deleted Projects
SELECT
	UGT.*
FROM #UsedGTTbl UGT
INNER JOIN Project P with (nolock)
	ON P.ProjectId = UGT.ProjectId
WHERE ISNULL( P.IsPermanentDeleted,0) = 0
OR ISNULL( P.IsDeleted ,0)= 0

END
GO
PRINT N'Altering [dbo].[usp_GetSegmentsForMLReportWithParagraph]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentsForMLReportWithParagraph]                   
(                  
@ProjectId INT,                  
@CustomerId INT,                  
@CatalogueType NVARCHAR(MAX)='FS',                  
@TCPrintModeId INT = 0,            
@TagId NVARCHAR(MAX)            
)                      
AS                      
BEGIN
      
          
              
DECLARE @PProjectId INT = @ProjectId;
      
          
DECLARE @PCustomerId INT = @CustomerId;
      
          
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;
      
          
DECLARE @PTCPrintModeId INT = 0;
      
          
DECLARE @PTagId INT = convert(int,@TagId);

DECLARE @SegmentTypeId INT = 1
DECLARE @HeaderFooterTypeId INT = 3
          
          
CREATE table #SegmentStatusIds (SegmentStatusId int);

INSERT INTO #SegmentStatusIds (SegmentStatusId)
	(SELECT
		PSRT.SegmentStatusId
	FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
	WHERE PSRT.ProjectId = @PProjectId
	AND PSRT.RequirementTagId = @TagId
	UNION ALL
	SELECT
		PSUT.SegmentStatusId
	FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)
	WHERE PSUT.ProjectId = @PProjectId
	AND PSUT.UserTagId = @TagId);

(SELECT
	PSS.SegmentStatusId
   ,PSS.SectionId
   ,PSS.ParentSegmentStatusId
   ,PSS.mSegmentStatusId
   ,PSS.mSegmentId
   ,PSS.SegmentId
   ,PSS.SegmentSource
   ,PSS.SegmentOrigin
   ,PSS.IndentLevel
   ,PSS.SequenceNumber
   ,PSS.SpecTypeTagId
   ,PSS.SegmentStatusTypeId
   ,PSS.IsParentSegmentStatusActive
   ,PSS.ProjectId
   ,PSS.CustomerId
   ,PSS.SegmentStatusCode
   ,PSS.IsShowAutoNumber
   ,PSS.IsRefStdParagraph
   ,PSS.FormattingJson
   ,PSS.CreateDate
   ,PSS.CreatedBy
   ,PSS.ModifiedDate
   ,PSS.ModifiedBy
   ,PSS.IsPageBreak
   ,PSS.IsDeleted
   ,PSS.TrackOriginOrder
   ,PSS.mTrackDescription INTO #taggedSegment
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.ProjectId = @PProjectId
AND PSS.CustomerId = @PCustomerId
AND PSS.SegmentStatusId IN (SELECT
		SegmentStatusId
	FROM #SegmentStatusIds)
);

DELETE FROM #taggedSegment
WHERE SegmentStatusId IN (SELECT
			SegmentStatusId
		FROM ProjectSegmentStatusView PSST WITH (NOLOCK)
		WHERE PSST.ProjectId = @PProjectId
		AND PSST.CustomerId = @PCustomerId
		AND PSST.IsDeleted = 0
		AND PSST.IsSegmentStatusActive = 0);

WITH SegmentStatus (SegmentStatusId, SectionId, ParentSegmentStatusId, SegmentOrigin, IndentLevel, SequenceNumber, SegmentDescription)
AS
(SELECT
		SegmentStatusId
	   ,SectionId
	   ,ParentSegmentStatusId
	   ,SegmentOrigin
	   ,IndentLevel
	   ,SequenceNumber
	   ,CAST(NULL AS NVARCHAR(MAX)) AS SegmentDescription
	FROM ProjectSegmentStatus WITH (NOLOCK)
	WHERE SegmentStatusId IN (SELECT
			SegmentStatusId
		FROM #taggedSegment)
	UNION ALL
	SELECT
		PSS.SegmentStatusId
	   ,PSS.SectionId
	   ,PSS.ParentSegmentStatusId
	   ,PSS.SegmentOrigin
	   ,PSS.IndentLevel
	   ,PSS.SequenceNumber
	   ,NULL AS SegmentDescription
	FROM ProjectSegmentStatus PSS WITH (NOLOCK)
	JOIN SegmentStatus SG
		ON PSS.SegmentStatusId = SG.ParentSegmentStatusId
		AND PSS.IndentLevel > 1)

SELECT
	* INTO #TagReport
FROM SegmentStatus;

UPDATE SS
SET SS.SegmentDescription = pssv.SegmentDescription
FROM #TagReport SS
INNER JOIN ProjectSegmentStatusView pssv WITH (NOLOCK)
	ON pssv.SegmentStatusId = SS.SegmentStatusId;




DECLARE @MasterDataTypeId INT = (SELECT
		P.MasterDataTypeId
	FROM Project P WITH (NOLOCK)
	WHERE P.ProjectId = @PProjectId
	AND P.CustomerId = @PCustomerId);

DECLARE @SectionIdTbl TABLE (
	SectionId INT
);
DECLARE @CatalogueTypeTbl TABLE (
	TagType NVARCHAR(MAX)
);
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';

DECLARE @Lu_InheritFromSection INT = 1;
DECLARE @Lu_AllWithMarkups INT = 2;
DECLARE @Lu_AllWithoutMarkups INT = 3;

--CONVERT STRING INTO TABLE                      
INSERT INTO @SectionIdTbl (SectionId)
	SELECT DISTINCT
		SectionId
	FROM #TagReport;

--CONVERT CATALOGUE TYPE INTO TABLE                  
IF @PCatalogueType IS NOT NULL
	AND @PCatalogueType != 'FS'
BEGIN
INSERT INTO @CatalogueTypeTbl (TagType)
	SELECT
		*
	FROM dbo.fn_SplitString(@PCatalogueType, ',');

IF EXISTS (SELECT
		TOP 1
			1
		FROM @CatalogueTypeTbl
		WHERE TagType = 'OL')
BEGIN
INSERT INTO @CatalogueTypeTbl
	VALUES ('UO')
END
IF EXISTS (SELECT
		TOP 1
			1
		FROM @CatalogueTypeTbl
		WHERE TagType = 'SF')
BEGIN
INSERT INTO @CatalogueTypeTbl
	VALUES ('US')
END
END

--DROP TEMP TABLES IF PRESENT                      
DROP TABLE IF EXISTS #tmp_ProjectSegmentStatus;
DROP TABLE IF EXISTS #tmp_Template;
DROP TABLE IF EXISTS #tmp_SelectedChoiceOption;
DROP TABLE IF EXISTS #tmp_ProjectSection;

--FETCH SECTIONS DATA IN TEMP TABLE            
SELECT
	PS.SectionId
   ,PS.ParentSectionId
   ,PS.mSectionId
   ,PS.ProjectId
   ,PS.CustomerId
   ,PS.UserId
   ,PS.DivisionId
   ,PS.DivisionCode
   ,PS.Description
   ,PS.LevelId
   ,PS.IsLastLevel
   ,PS.SourceTag
   ,PS.Author
   ,PS.TemplateId
   ,PS.SectionCode
   ,PS.IsDeleted
   ,PS.SpecViewModeId
   ,PS.IsTrackChanges INTO #tmp_ProjectSection
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId
ORDER BY PS.SourceTag

--FETCH SEGMENT STATUS DATA INTO TEMP TABLE               
PRINT 'FETCH SEGMENT STATUS DATA INTO TEMP TABLE'
SELECT
	PSST.SegmentStatusId
   ,PSST.SectionId
   ,PSST.ParentSegmentStatusId
   ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId
   ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId
   ,ISNULL(PSST.SegmentId, 0) AS SegmentId
   ,PSST.SegmentSource
   ,TRIM(CONVERT(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin
   ,CASE
		WHEN PSST.IndentLevel > 8 THEN CAST(8 AS TINYINT)
		ELSE PSST.IndentLevel
	END AS IndentLevel
   ,PSST.SequenceNumber
   ,PSST.SegmentStatusTypeId
   ,ISNULL(PSST.SegmentStatusCode,0) as SegmentStatusCode
   ,PSST.IsParentSegmentStatusActive
   ,PSST.IsShowAutoNumber
   ,COALESCE(PSST.FormattingJson,'') as FormattingJson
	-- ,STT.TagType                  
   ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId
   ,PSST.IsRefStdParagraph
   ,PSST.IsPageBreak
   ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder INTO #tmp_ProjectSegmentStatus
FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)
--INNER JOIN #TagReport TR                  
-- ON PSST.SegmentStatusId = TR.SegmentStatusId                  
--LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)                  
--ON PSST.SpecTypeTagId = STT.SpecTypeTagId                

WHERE PSST.ProjectId = @PProjectId
AND PSST.CustomerId = @PCustomerId
AND (PSST.IsDeleted IS NULL
OR PSST.IsDeleted = 0)
--AND ((PSST.SegmentStatusTypeId > 0                  
--AND PSST.SegmentStatusTypeId < 6                  
AND PSST.IsParentSegmentStatusActive = 1
AND PSST.SegmentStatusId IN (SELECT
		SegmentStatusId
	FROM #TagReport)
--OR (PSST.IsPageBreak = 1))                  
--AND (@PCatalogueType = 'FS'                  
--OR STT.TagType IN (SELECT                  
--  *                  
-- FROM @CatalogueTypeTbl)                  
--)                  

--SELECT SEGMENT STATUS DATA            
SELECT
	*,@PProjectId as ProjectId,@PCustomerId as CustomerId
FROM #tmp_ProjectSegmentStatus PSST
ORDER BY PSST.SectionId, PSST.SequenceNumber
--SELECT SEGMENT DATA             
SELECT
	PSST.SegmentId
   ,PSST.SegmentStatusId
   ,PSST.SectionId
   ,(CASE
		WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')
		WHEN @PTCPrintModeId = @Lu_AllWithMarkups THEN COALESCE(PSG.SegmentDescription, '')
		WHEN @PTCPrintModeId = @Lu_InheritFromSection AND
			PS.IsTrackChanges = 1 THEN COALESCE(PSG.SegmentDescription, '')
		WHEN @PTCPrintModeId = @Lu_InheritFromSection AND
			PS.IsTrackChanges = 0 THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')
		ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')
	END) AS SegmentDescription
   ,PSG.SegmentSource
   ,ISNULL(PSG.SegmentCode,0) as SegmentCode
   ,@PProjectId as ProjectId
   ,@PCustomerId as CustomerId
FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)
INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK)
	ON PSST.SectionId = PS.SectionId
INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)
	ON PSST.SegmentId = PSG.SegmentId
INNER JOIN #TagReport TR
	ON TR.SectionId = PS.SectionId

WHERE PSG.ProjectId = @PProjectId
AND PSG.CustomerId = @PCustomerId

UNION
SELECT
	MSG.SegmentId
   ,PSST.SegmentStatusId
   ,PSST.SectionId
   ,CASE
		WHEN PSST.ParentSegmentStatusId = 0 AND
			PSST.SequenceNumber = 0 THEN PS.Description
		ELSE ISNULL(MSG.SegmentDescription, '')
	END AS SegmentDescription
   ,MSG.SegmentSource
   ,ISNULL(MSG.SegmentCode,0) as SegmentCode
   ,@PProjectId as ProjectId
   ,@PCustomerId as CustomerId
FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)
INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK)
	ON PSST.SectionId = PS.SectionId
INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK)
	ON PSST.mSegmentId = MSG.SegmentId
INNER JOIN #TagReport TR
	ON TR.SectionId = PS.SectionId
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId

--FETCH TEMPLATE DATA INTO TEMP TABLE                      
SELECT
	* INTO #tmp_Template
FROM (SELECT
		T.TemplateId
	   ,T.Name
	   ,T.TitleFormatId
	   ,T.SequenceNumbering
	   ,T.IsSystem
	   ,T.IsDeleted
	   ,0 AS SectionId
	   ,CAST(1 AS BIT) AS IsDefault
	FROM Template T WITH (NOLOCK)
	INNER JOIN Project P WITH (NOLOCK)
		ON T.TemplateId = COALESCE(P.TemplateId, 1)

	WHERE P.ProjectId = @PProjectId
	AND P.CustomerId = @PCustomerId) AS X






--SELECT TEMPLATE DATA                     
SELECT
	*,@PCustomerId as CustomerId
FROM #tmp_Template T

--SELECT TEMPLATE STYLE DATA                  

SELECT
	TS.TemplateStyleId
   ,TS.TemplateId
   ,TS.StyleId
   ,TS.Level
   ,@PCustomerId as CustomerId
FROM TemplateStyle TS WITH (NOLOCK)
INNER JOIN #tmp_Template T WITH (NOLOCK)
	ON TS.TemplateId = T.TemplateId

--SELECT STYLE DATA                      
SELECT
	ST.StyleId
   ,ST.Alignment
   ,ST.IsBold
   ,ST.CharAfterNumber
   ,ST.CharBeforeNumber
   ,ST.FontName
   ,ST.FontSize
   ,ST.HangingIndent
   ,ST.IncludePrevious
   ,ST.IsItalic
   ,ST.LeftIndent
   ,ST.NumberFormat
   ,ST.NumberPosition
   ,ST.PrintUpperCase
   ,ST.ShowNumber
   ,ST.StartAt
   ,ST.Strikeout
   ,ST.Name
   ,ST.TopDistance
   ,ST.Underline
   ,ST.SpaceBelowParagraph
   ,ST.IsSystem
   ,ST.IsDeleted
   ,CAST(TS.Level AS INT) AS Level
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId
  ,@PCustomerId as CustomerId
FROM Style AS ST WITH (NOLOCK)
INNER JOIN TemplateStyle AS TS WITH (NOLOCK)
	ON ST.StyleId = TS.StyleId
INNER JOIN #tmp_Template T WITH (NOLOCK)
	ON TS.TemplateId = T.TemplateId
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId 


--FETCH SelectedChoiceOption INTO TEMP TABLE             
SELECT DISTINCT
	SCHOP.SegmentChoiceCode
   ,SCHOP.ChoiceOptionCode
   ,SCHOP.ChoiceOptionSource
   ,SCHOP.IsSelected
   ,SCHOP.ProjectId
   ,SCHOP.SectionId
   ,SCHOP.CustomerId
   ,0 AS SelectedChoiceOptionId
   ,SCHOP.OptionJson INTO #tmp_SelectedChoiceOption
FROM SelectedChoiceOption SCHOP WITH (NOLOCK)
INNER JOIN @SectionIdTbl SIDTBL
	ON SCHOP.SectionId = SIDTBL.SectionId
WHERE SCHOP.ProjectId = @PProjectId
AND SCHOP.CustomerId = @PCustomerId
AND ISNULL(SCHOP.IsDeleted, 0) = 0
--FETCH MASTER + USER CHOICES AND THEIR OPTIONS             
SELECT
	0 AS SegmentId
   ,MCH.SegmentId AS mSegmentId
   ,MCH.ChoiceTypeId
   ,'M' AS ChoiceSource
   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
   ,PSCHOP.IsSelected
   ,PSCHOP.ChoiceOptionSource
   ,CASE
		WHEN PSCHOP.IsSelected = 1 AND
			PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson
		ELSE MCHOP.OptionJson
	END AS OptionJson
   ,MCHOP.SortOrder
   ,MCH.SegmentChoiceId
   ,MCHOP.ChoiceOptionId
   ,PSCHOP.SelectedChoiceOptionId
   ,PSST.SectionId into #DapperChoiceTbl
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)
	ON PSST.mSegmentId = MCH.SegmentId
INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK)
	ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
		AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
		AND PSCHOP.ChoiceOptionSource = 'M'
UNION
SELECT
	PCH.SegmentId
   ,0 AS mSegmentId
   ,PCH.ChoiceTypeId
   ,PCH.SegmentChoiceSource AS ChoiceSource
   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode
   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode
   ,PSCHOP.IsSelected
   ,PSCHOP.ChoiceOptionSource
   ,PCHOP.OptionJson
   ,PCHOP.SortOrder
   ,PCH.SegmentChoiceId
   ,PCHOP.ChoiceOptionId
   ,PSCHOP.SelectedChoiceOptionId
   ,PSST.SectionId
FROM #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)
	ON PSST.SegmentId = PCH.SegmentId
		AND ISNULL(PCH.IsDeleted, 0) = 0
INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)
	ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId
		AND ISNULL(PCHOP.IsDeleted, 0) = 0
INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK)
	ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode
		AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
		AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource
		AND PSCHOP.ChoiceOptionSource = 'U'
WHERE PCH.ProjectId = @PProjectId
AND PCH.CustomerId = @PCustomerId
AND PCHOP.ProjectId = @PProjectId
AND PCHOP.CustomerId = @PCustomerId

SELECT SegmentId,MSegmentId,ChoiceTypeId,ChoiceSource,SegmentChoiceCode,SegmentChoiceId, @PProjectId as ProjectId , @PCustomerId as CustomerId
,SectionId
FROM #DapperChoiceTbl

SELECT ChoiceOptionCode,IsSelected,SegmentChoiceCode,ChoiceOptionSource,ChoiceOptionId,SortOrder,SelectedChoiceOptionId, @PProjectId as ProjectId , @PCustomerId as CustomerId
,SectionId,OptionJson
FROM #DapperChoiceTbl

--SELECT GLOBAL TERM DATA                 
SELECT
	PGT.GlobalTermId
   ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId
   ,PGT.Name
   ,ISNULL(PGT.value, '') AS value
   ,PGT.CreatedDate
   ,PGT.CreatedBy
   ,PGT.ModifiedDate
   ,PGT.ModifiedBy
   ,PGT.GlobalTermSource
   ,isnull(PGT.GlobalTermCode,0) as GlobalTermCode
   ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId
   ,GlobalTermFieldTypeId as GTFieldType
   ,@PProjectId as ProjectId 
   ,@PCustomerId as CustomerId
FROM ProjectGlobalTerm PGT WITH (NOLOCK)
WHERE PGT.ProjectId = @PProjectId
AND PGT.CustomerId = @PCustomerId;

--SELECT SECTIONS DATA                

SELECT
	S.SectionId AS SectionId
   ,ISNULL(S.mSectionId, 0) AS mSectionId
   ,S.Description
   ,S.Author
   ,ISNULL(S.SectionCode,0) AS SectionCode
   ,ISNULL(S.SourceTag,'') as SourceTag
   ,PS.SourceTagFormat
   ,ISNULL(D.DivisionCode, '') AS DivisionCode
   ,ISNULL(D.DivisionTitle, '') AS DivisionTitle
   ,ISNULL(D.DivisionId, 0) AS DivisionId
   ,ISNULL(S.IsTrackChanges,CONVERT(BIT, 0)) as IsTrackChanges
FROM #tmp_ProjectSection AS S WITH (NOLOCK)
LEFT JOIN SLCMaster..Division D WITH (NOLOCK)
	ON S.DivisionId = D.DivisionId
INNER JOIN ProjectSummary PS WITH (NOLOCK)
	ON S.ProjectId = PS.ProjectId
		AND S.CustomerId = PS.CustomerId
WHERE S.ProjectId = @PProjectId
AND S.CustomerId = @PCustomerId
AND S.IsLastLevel = 1
UNION
SELECT
	0 AS SectionId
   ,MS.SectionId AS mSectionId
   ,MS.Description
   ,MS.Author
   ,ISNULL(MS.SectionCode,0) as SectionCode
   ,ISNULL(MS.SourceTag,'') as SourceTag
   ,P.SourceTagFormat
   ,ISNULL(D.DivisionCode, '') AS DivisionCode
   ,ISNULL(D.DivisionTitle, '') AS DivisionTitle
   ,ISNULL(D.DivisionId, 0) AS DivisionId
   ,CONVERT(BIT, 0) AS IsTrackChanges
FROM SLCMaster..Section MS WITH (NOLOCK)
LEFT JOIN SLCMaster..Division D WITH (NOLOCK)
	ON MS.DivisionId = D.DivisionId
INNER JOIN ProjectSummary P WITH (NOLOCK)
	ON P.ProjectId = @PProjectId
		AND P.CustomerId = @PCustomerId
LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK)
	ON MS.SectionId = PS.mSectionId
		AND PS.ProjectId = @PProjectId
		AND PS.CustomerId = @PCustomerId
WHERE MS.MasterDataTypeId = @MasterDataTypeId
AND MS.IsLastLevel = 1
AND PS.SectionId IS NULL;

--SELECT SEGMENT REQUIREMENT TAGS DATA             
SELECT
	PSRT.SegmentStatusId
   ,PSRT.SegmentRequirementTagId
   ,PSST.mSegmentStatusId
   ,LPRT.RequirementTagId
   ,LPRT.TagType
   ,LPRT.Description AS TagName
   ,CASE
		WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)
		ELSE CAST(1 AS BIT)
	END AS IsMasterAppliedTag
   ,PSST.SectionId
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)
	ON PSRT.RequirementTagId = LPRT.RequirementTagId
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)
	ON PSRT.SegmentStatusId = PSST.SegmentStatusId
WHERE PSRT.ProjectId = @PProjectId
AND PSRT.CustomerId = @PCustomerId

--SELECT REQUIRED IMAGES DATA             
SELECT
	IMG.ImageId
   ,IMG.ImagePath
   ,PIMG.SectionId
   ,ISNULL(PIMG.ImageStyle,'') as ImageStyle
   ,IMG.LuImageSourceTypeId
FROM ProjectSegmentImage PIMG WITH (NOLOCK)
INNER JOIN ProjectImage IMG WITH (NOLOCK)
	ON PIMG.ImageId = IMG.ImageId
--INNER JOIN @SectionIdTbl SIDTBL	ON PIMG.SectionId = SIDTBL.SectionId //To resolved cross section images in headerFooter
WHERE PIMG.ProjectId = @PProjectId
AND PIMG.CustomerId = @PCustomerId
AND IMG.LuImageSourceTypeId in (@SegmentTypeId,@HeaderFooterTypeId)
UNION ALL -- This union to ge Note images  
 SELECT           
 PN.ImageId          
 ,IMG.ImagePath          
 ,PN.SectionId           
 ,'' ImageStyle          
 ,IMG.LuImageSourceTypeId   
 FROM ProjectNoteImage PN  WITH (NOLOCK)       
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId  
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId  
 WHERE PN.ProjectId = @PProjectId                
  AND PN.CustomerId = @PCustomerId  

--SELECT HYPERLINKS DATA                      
SELECT
	HLNK.HyperLinkId
   ,HLNK.LinkTarget
   ,HLNK.LinkText
   ,'U' AS Source
   ,HLNK.SectionId
FROM ProjectHyperLink HLNK WITH (NOLOCK)
INNER JOIN @SectionIdTbl SIDTBL
	ON HLNK.SectionId = SIDTBL.SectionId
WHERE HLNK.ProjectId = @PProjectId
AND HLNK.CustomerId = @PCustomerId

--SELECT SEGMENT USER TAGS DATA             
SELECT
	PSUT.SegmentUserTagId
   ,PSUT.SegmentStatusId
   ,PSUT.UserTagId
   ,PUT.TagType
   ,PUT.Description AS TagName
   ,PSUT.SectionId
FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)
INNER JOIN ProjectUserTag PUT WITH (NOLOCK)
	ON PSUT.UserTagId = PUT.UserTagId
INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK)
	ON PSUT.SegmentStatusId = PSST.SegmentStatusId
WHERE PSUT.ProjectId = @PProjectId
AND PSUT.CustomerId = @PCustomerId

--SELECT Project Summary information            
SELECT
	P.ProjectId AS ProjectId
   ,P.Name AS ProjectName
   ,'' AS ProjectLocation
   ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate
   ,PS.SourceTagFormat AS SourceTagFormat
   ,COALESCE(LState.StateProvinceAbbreviation, PA.StateProvinceName) + ', ' + COALESCE(LCity.City, PA.CityName) AS DbInfoProjectLocationKeyword
   ,ISNULL(PGT.value, '') AS ProjectLocationKeyword
   ,PS.UnitOfMeasureValueTypeId
FROM Project P WITH (NOLOCK)
INNER JOIN ProjectSummary PS WITH (NOLOCK)
	ON P.ProjectId = PS.ProjectId
INNER JOIN ProjectAddress PA WITH (NOLOCK)
	ON P.ProjectId = PA.ProjectId
INNER JOIN LuCountry LCountry WITH (NOLOCK)
	ON PA.CountryId = LCountry.CountryId
LEFT JOIN LuStateProvince LState WITH (NOLOCK)
	ON PA.StateProvinceId = LState.StateProvinceID
LEFT JOIN LuCity LCity WITH (NOLOCK)
	ON PA.CityId = LCity.CityId
LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)
	ON P.ProjectId = PGT.ProjectId
		AND PGT.mGlobalTermId = 11
WHERE P.ProjectId = @PProjectId
AND P.CustomerId = @PCustomerId

--SELECT Header/Footer information                      
IF EXISTS (SELECT
		TOP 1
			1
		FROM Header WITH (NOLOCK)
		WHERE ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND DocumentTypeId = 2)
BEGIN
SELECT
	H.HeaderId
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(H.SectionId, 0) AS SectionId
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(H.TypeId, 1) AS TypeId
   ,H.DateFormat
   ,H.TimeFormat
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H WITH (NOLOCK)
WHERE H.ProjectId = @PProjectId
AND H.CustomerId = @PCustomerId
AND H.DocumentTypeId = 2
END
ELSE
BEGIN
SELECT
	H.HeaderId
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(H.SectionId, 0) AS SectionId
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(H.TypeId, 1) AS TypeId
   ,H.DateFormat
   ,H.TimeFormat
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H WITH (NOLOCK)
WHERE H.ProjectId IS NULL
AND H.CustomerId IS NULL
AND H.SectionId IS NULL
AND H.DocumentTypeId = 2
END
IF EXISTS (SELECT
		TOP 1
			1
		FROM Footer WITH (NOLOCK)
		WHERE ProjectId = @PProjectId
		AND CustomerId = @PCustomerId
		AND DocumentTypeId = 2)
BEGIN
SELECT
	F.FooterId
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(F.SectionId, 0) AS SectionId
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(F.TypeId, 1) AS TypeId
   ,F.DateFormat
   ,F.TimeFormat
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter

FROM Footer F WITH (NOLOCK)
WHERE F.ProjectId = @PProjectId
AND F.CustomerId = @PCustomerId
AND F.DocumentTypeId = 2
END
ELSE
BEGIN
SELECT
	F.FooterId
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId
   ,ISNULL(F.SectionId, 0) AS SectionId
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId
   ,ISNULL(F.TypeId, 1) AS TypeId
   ,F.DateFormat
   ,F.TimeFormat
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter
FROM Footer F WITH (NOLOCK)
WHERE F.ProjectId IS NULL
AND F.CustomerId IS NULL
AND F.SectionId IS NULL
AND F.DocumentTypeId = 2
END
--SELECT PageSetup INFORMATION                  
SELECT
	PageSetting.ProjectPageSettingId AS ProjectPageSettingId
   ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId
   ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop
   ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom
   ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft
   ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight
   ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader
   ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter
   ,PageSetting.IsMirrorMargin AS IsMirrorMargin
   ,PageSetting.ProjectId AS ProjectId
   ,PageSetting.CustomerId AS CustomerId
   ,ISNULL(PaperSetting.PaperName,'A4') AS PaperName
   ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth
   ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight
   ,ISNULL(PaperSetting.PaperOrientation,'') AS PaperOrientation
   ,ISNULL(PaperSetting.PaperSource,'') AS PaperSource
FROM ProjectPageSetting PageSetting WITH (NOLOCK)
INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK)
	ON PageSetting.ProjectId = PaperSetting.ProjectId
WHERE PageSetting.ProjectId = @PProjectId
END
GO
PRINT N'Altering [dbo].[usp_GetSegmentsForPrint]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentsForPrint] (                    
 @ProjectId INT                    
 ,@CustomerId INT                    
 ,@SectionIdsString NVARCHAR(MAX)                    
 ,@UserId INT                    
 ,@CatalogueType NVARCHAR(MAX)                    
 ,@TCPrintModeId INT = 1                    
 ,@IsActiveOnly BIT = 1                  
 ,@IsPrintMasterNote BIT =0           
 ,@IsPrintProjectNote BIT =0               
 )                      
AS                      
BEGIN              
SET NOCOUNT ON;          
 DECLARE @PProjectId INT = @ProjectId;                      
 DECLARE @PCustomerId INT = @CustomerId;                      
 DECLARE @PSectionIdsString NVARCHAR(MAX) = @SectionIdsString;                      
 DECLARE @PUserId INT = @UserId;                      
 DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                      
 DECLARE @PTCPrintModeId INT = @TCPrintModeId;                      
 DECLARE @PIsActiveOnly BIT = @IsActiveOnly;    
 DECLARE @PIsPrintMasterNote BIT =@IsPrintMasterNote;  
 DECLARE @PIsPrintProjectNote BIT =@IsPrintProjectNote;                    
 DECLARE @IsFalse BIT = 0;                      
 DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);                      
 DECLARE @STCPrintModeId NVARCHAR(2) = convert(NVARCHAR, @TCPrintModeId);                      
 DECLARE @SIsActiveOnly NVARCHAR(2) = convert(NVARCHAR, @IsActiveOnly);                      
 DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);                      
 DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);                      
 DECLARE @MasterDataTypeId INT = (                      
   SELECT P.MasterDataTypeId                      
   FROM Project P WITH (NOLOCK)                      
   WHERE P.ProjectId = @PProjectId                      
    AND P.CustomerId = @PCustomerId                      
   );                      
 DECLARE @SectionIdTbl TABLE (SectionId INT);                      
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));                      
 DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';                      
 DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';                      
 DECLARE @Lu_InheritFromSection INT = 1;                      
 DECLARE @Lu_AllWithMarkups INT = 2;                      
 DECLARE @Lu_AllWithoutMarkups INT = 3;                     
 DECLARE @ImagSegment int =1          
 DECLARE @ImageHeaderFooter int =3          
 DECLARE @State VARCHAR(50)=''      
 DECLARE @City VARCHAR(50)=''      
                      
 --CONVERT STRING INTO TABLE                                          
 INSERT INTO @SectionIdTbl (SectionId)                      
 SELECT *                      
 FROM dbo.fn_SplitString(@PSectionIdsString, ',');                      
                      
 --CONVERT CATALOGUE TYPE INTO TABLE                                      
 IF @PCatalogueType IS NOT NULL                      
  AND @PCatalogueType != 'FS'                      
 BEGIN                      
  INSERT INTO @CatalogueTypeTbl (TagType)                      
  SELECT *                      
  FROM dbo.fn_SplitString(@PCatalogueType, ',');                      
                      
  IF EXISTS (                      
    SELECT *                      
    FROM @CatalogueTypeTbl                      
    WHERE TagType = 'OL'                      
    )                      
  BEGIN                      
   INSERT INTO @CatalogueTypeTbl                      
   VALUES ('UO')                      
  END                      
                      
  IF EXISTS (                      
    SELECT TOP 1 1                      
    FROM @CatalogueTypeTbl                      
    WHERE TagType = 'SF'                      
    )                      
  BEGIN                      
   INSERT INTO @CatalogueTypeTbl                      
   VALUES ('US')                      
  END                      
 END                      
      
 IF EXISTS (SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE Projectid=@PProjectId AND PA.StateProvinceId=99999999 AND PA.StateProvinceName IS NULL)      
 BEGIN      
  SELECT TOP 1 @State = ISNULL(concat(rtrim(VALUE),','),'') FROM ProjectGlobalTerm  WITH (NOLOCK)      
  WHERE Projectid = @PProjectId AND (NAME = 'Project Location State' OR Name ='Project Location Province')   
  OPTION (FAST 1)     
 END      
 ELSE      
 BEGIN      
  SELECT TOP 1 @State = CONCAT(RTRIM(SP.StateProvinceAbbreviation),', ') FROM LuStateProvince SP WITH (NOLOCK)      
  INNER JOIN ProjectAddress PA WITH (NOLOCK) ON PA.StateProvinceId = SP.StateProvinceID       
  WHERE ProjectId = @PProjectId   
  OPTION (FAST 1)     
 END      
       
 IF EXISTS(SELECT COUNT(1) FROM ProjectAddress PA  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND PA.CityId=99999999 AND PA.CityName IS NULL)      
 BEGIN      
  SELECT TOP 1 @City =ISNULL(VALUE,'') FROM ProjectGlobalTerm  WITH (NOLOCK) WHERE ProjectId = @PProjectId AND NAME = 'Project Location City'    
  OPTION (FAST 1)    
 END      
 ELSE      
 BEGIN      
  SELECT TOP 1 @City = CITY FROM LuCity C WITH (NOLOCK) INNER JOIN ProjectAddress PA ON PA.CityId = C.CityId WHERE Projectid=@PProjectId    
  OPTION (FAST 1)  
 END      
      
                      
 --DROP TEMP TABLES IF PRESENT                                          
 DROP TABLE                      
                      
 IF EXISTS #tmp_ProjectSegmentStatus;                      
  DROP TABLE                      
                      
 IF EXISTS #tmp_Template;                      
  DROP TABLE                      
                      
 IF EXISTS #tmp_SelectedChoiceOption;                      
  DROP TABLE                      
                      
 IF EXISTS #tmp_ProjectSection;                      
  --FETCH SECTIONS DATA IN TEMP TABLE                                      
  SELECT PS.SectionId                      
   ,PS.ParentSectionId                      
   ,PS.mSectionId                      
   ,PS.ProjectId                      
   ,PS.CustomerId                      
   ,PS.UserId                      
   ,PS.DivisionId          
   ,PS.DivisionCode                      
   ,PS.Description                      
   ,PS.LevelId                      
   ,PS.IsLastLevel                      
   ,PS.SourceTag                      
   ,PS.Author                      
   ,PS.TemplateId                      
   ,PS.SectionCode                      
   ,PS.IsDeleted                      
   ,PS.SpecViewModeId                      
   ,PS.IsTrackChanges                      
  INTO #tmp_ProjectSection                      
  FROM ProjectSection PS WITH (NOLOCK)                      
  WHERE PS.ProjectId = @PProjectId                      
   AND PS.CustomerId = @PCustomerId                      
   AND ISNULL(PS.IsDeleted, 0) = 0;                      
   
                      
 --FETCH SEGMENT STATUS DATA INTO TEMP TABLE                                  
 SELECT PSST.SegmentStatusId                
  ,PSST.SectionId                      
  ,PSST.ParentSegmentStatusId                      
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                      
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                      
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId                 
  ,PSST.SegmentSource                      
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                      
  ,CASE                       
   WHEN PSST.IndentLevel > 8                      
    THEN CAST(8 AS TINYINT)                      
   ELSE PSST.IndentLevel                      
   END AS IndentLevel                      
  ,PSST.SequenceNumber                      
  ,PSST.SegmentStatusTypeId                      
  ,PSST.SegmentStatusCode                      
  ,PSST.IsParentSegmentStatusActive                      
  ,PSST.IsShowAutoNumber                      
  ,PSST.FormattingJson                      
  ,STT.TagType                      
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                      
  ,PSST.IsRefStdParagraph                 
  ,PSST.IsPageBreak                      
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                      
  ,PSST.MTrackDescription  
 INTO #tmp_ProjectSegmentStatus                      
 FROM @SectionIdTbl SIDTBL                      
 INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.SectionId = SIDTBL.SectionId                      
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                      
 WHERE PSST.ProjectId = @PProjectId                      
  AND PSST.CustomerId = @PCustomerId                      
  AND (                      
   PSST.IsDeleted IS NULL                      
   OR PSST.IsDeleted = 0                      
   )                      
  AND (                      
   @PIsActiveOnly = @IsFalse                      
   OR (                      
    PSST.SegmentStatusTypeId > 0                      
    AND PSST.SegmentStatusTypeId < 6                      
    AND PSST.IsParentSegmentStatusActive = 1                      
    )                      
   OR (PSST.IsPageBreak = 1)                      
   )                      
  AND (                      
   @PCatalogueType = 'FS'                      
   OR STT.TagType IN (                      
    SELECT TagType                      
    FROM @CatalogueTypeTbl                      
    )                      
   )                      
                      
 --SELECT SEGMENT STATUS DATA                                          
 SELECT SegmentStatusId,SectionId,ParentSegmentStatusId,mSegmentStatusId,mSegmentId,SegmentId,SegmentSource,SegmentOrigin  
 ,IndentLevel,SequenceNumber,SegmentStatusTypeId,isnull(SegmentStatusCode,0) as SegmentStatusCode,IsParentSegmentStatusActive  
 ,IsShowAutoNumber, COALESCE(TagType,'')TagType,isnull(SpecTypeTagId,0)as SpecTypeTagId,COALESCE(FormattingJson,'') as FormattingJson  
 ,IsRefStdParagraph,IsPageBreak,COALESCE(TrackOriginOrder,'') AS TrackOriginOrder, @PProjectId as ProjectId  
  ,@PCustomerId as CustomerId  
 FROM #tmp_ProjectSegmentStatus PSST   WITH (NOLOCK)                
 ORDER BY PSST.SectionId                      
  ,PSST.SequenceNumber;                      
       
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;       
  
 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE           
SELECT PSST.SegmentStatusId                  
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId     
  ,PSST.SectionId                     
 INTO #tmpProjectSegmentStatusForNote                        
 FROM @SectionIdTbl SIDTBL                      
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)  ON PSST.SectionId = SIDTBL.SectionId                       
 --WHERE PSST.ProjectId = @PProjectId       
 --AND PSST.CustomerId = @PCustomerId       
      
 --SELECT SEGMENT DATA                                          
 SELECT PSST.SegmentId                      
  ,PSST.SegmentStatusId                      
  ,PSST.SectionId                      
  ,(                      
   CASE                       
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups                      
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                      
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups                      
     THEN COALESCE(PSG.SegmentDescription, '')                      
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                      
     AND PS.IsTrackChanges = 1                      
     THEN COALESCE(PSG.SegmentDescription, '')                      
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                      
     AND PS.IsTrackChanges = 0                      
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                      
    ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                      
    END                      
   ) AS SegmentDescription                      
  ,PSG.SegmentSource                      
  ,ISNULL(PSG.SegmentCode ,0)SegmentCode  
  ,@PProjectId as ProjectId  
  ,@PCustomerId as CustomerId  
 FROM @SectionIdTbl STBL   
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                      
 ON PSST.SectionId = STBL.SectionId  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId         
 AND PS.SectionId  = STBL.SectionId              
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId    
 AND PSG.SectionId= STBL.SectionId                    
 WHERE PSG.ProjectId = @PProjectId                      
  AND PSG.CustomerId = @PCustomerId                      
 UNION  ALL                    
 SELECT MSG.SegmentId                      
  ,PSST.SegmentStatusId                      
  ,PSST.SectionId                      
  ,CASE                       
   WHEN PSST.ParentSegmentStatusId = 0                AND PSST.SequenceNumber = 0                      
    THEN PS.Description                      
   ELSE ISNULL(MSG.SegmentDescription, '')                      
   END AS SegmentDescription                      
  ,MSG.SegmentSource                      
  ,ISNULL(MSG.SegmentCode ,0)SegmentCode         
  ,@PProjectId as ProjectId  
  ,@PCustomerId as CustomerId  
 FROM @SectionIdTbl STBL   
 INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                      
 ON PSST.SectionId = STBL.SectionId AND ISNULL(PSST.mSegmentId,0) > 0  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId    
 AND PS.SectionId  = STBL.SectionId                       
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                      
 WHERE PS.ProjectId = @PProjectId                      
  AND PS.CustomerId = @PCustomerId   
   AND ISNULL(PSST.mSegmentId,0) > 0                     
          
   
 --FETCH TEMPLATE DATA INTO TEMP TABLE                                          
 SELECT *                      
 INTO #tmp_Template                      
 FROM (                      
  SELECT T.TemplateId                      
   ,T.Name                      
   ,T.TitleFormatId                      
   ,T.SequenceNumbering                      
   ,T.IsSystem                      
   ,T.IsDeleted                      
   ,0 AS SectionId                
   ,T.ApplyTitleStyleToEOS                  
   ,CAST(1 AS BIT) AS IsDefault                      
  FROM Template T WITH (NOLOCK)                      
  INNER JOIN Project P WITH (NOLOCK) ON T.TemplateId = COALESCE(P.TemplateId, 1)                      
  WHERE P.ProjectId = @PProjectId                      
   AND P.CustomerId = @PCustomerId                      
                        
  UNION                      
                        
  SELECT T.TemplateId                      
   ,T.Name                      
   ,T.TitleFormatId                      
   ,T.SequenceNumbering                      
   ,T.IsSystem                    
   ,T.IsDeleted                      
   ,PS.SectionId                      
   ,T.ApplyTitleStyleToEOS                  
   ,CAST(0 AS BIT) AS IsDefault                      
  FROM Template T WITH (NOLOCK)                      
  INNER JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON T.TemplateId = PS.TemplateId                      
  INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId                      
  WHERE PS.ProjectId = @PProjectId                      
   AND PS.CustomerId = @PCustomerId                      
   AND PS.TemplateId IS NOT NULL                      
  ) AS X                      
                      
 --SELECT TEMPLATE DATA                                          
 SELECT *  
  ,@PCustomerId as CustomerId                      
 FROM #tmp_Template T                      
                      
 --SELECT TEMPLATE STYLE DATA                                          
 SELECT TS.TemplateStyleId                      
  ,TS.TemplateId                      
  ,TS.StyleId                      
  ,TS.LEVEL   
  ,@PCustomerId as CustomerId  
 FROM TemplateStyle TS WITH (NOLOCK)                  
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId                      
                      
 --SELECT STYLE DATA                                          
 SELECT ST.StyleId                      
  ,ST.Alignment                      
  ,ST.IsBold                      
  ,ST.CharAfterNumber                      
  ,ST.CharBeforeNumber                      
  ,ST.FontName                      
  ,ST.FontSize                      
  ,ST.HangingIndent                      
  ,ST.IncludePrevious                      
  ,ST.IsItalic                      
  ,ST.LeftIndent                      
  ,ST.NumberFormat                      
  ,ST.NumberPosition              
  ,ST.PrintUpperCase                      
  ,ST.ShowNumber                      
  ,ST.StartAt                      
  ,ST.Strikeout                      
  ,ST.Name                      
  ,ST.TopDistance                      
  ,ST.Underline                      
  ,ST.SpaceBelowParagraph                      
  ,ST.IsSystem                      
  ,ST.IsDeleted                      
  ,CAST(TS.LEVEL AS INT) AS LEVEL             
  ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing        
  ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId        
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId        
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId     
  ,@PCustomerId as CustomerId  
 FROM Style AS ST WITH (NOLOCK)                      
 INNER JOIN TemplateStyle AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId                      
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId          
  LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId                  
                      
 --SELECT GLOBAL TERM DATA                                          
 SELECT PGT.GlobalTermId                      
  ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                      
  ,PGT.Name                      
  ,ISNULL(PGT.value, '') AS value                      
  ,PGT.CreatedDate                      
  ,PGT.CreatedBy                      
  ,PGT.ModifiedDate                      
  ,PGT.ModifiedBy                      
  ,PGT.GlobalTermSource                      
  ,ISNULL(PGT.GlobalTermCode,0) AS GlobalTermCode  
  ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                      
  ,GlobalTermFieldTypeId AS GTFieldType      
  ,@PProjectId as ProjectId  
  ,@PCustomerId as CustomerId  
 FROM ProjectGlobalTerm PGT WITH (NOLOCK)                      
 WHERE PGT.ProjectId = @PProjectId                      
  AND PGT.CustomerId = @PCustomerId;                      
  
  DECLARE @PSourceTagFormat NVARCHAR(10)='', @IsPrintReferenceEditionDate BIT, @UnitOfMeasureValueTypeId INT;  
SELECT TOP 1 @PSourceTagFormat= SourceTagFormat  
,@IsPrintReferenceEditionDate = PS.IsPrintReferenceEditionDate   
,@UnitOfMeasureValueTypeId = ISNULL(PS.UnitOfMeasureValueTypeId,0)  
FROM ProjectSummary PS WITH (NOLOCK) WHERE PS.ProjectId = @PProjectId  
                      
 --SELECT SECTIONS DATA                                          
 SELECT S.SectionId AS SectionId                      
  ,ISNULL(S.mSectionId, 0) AS mSectionId                      
  ,S.Description                      
  ,COALESCE(S.Author,'') as Author                     
  ,ISNULL(S.SectionCode ,0)   AS SectionCode                  
  ,COALESCE(S.SourceTag,'') as SourceTag                     
  ,@PSourceTagFormat SourceTagFormat    --PS.SourceTagFormat                   
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                      
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                      
  ,ISNULL(D.DivisionId, 0) AS DivisionId                      
  ,ISNULL(S.IsTrackChanges, CONVERT(BIT,0)) AS IsTrackChanges                      
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                      
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId                      
 --INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                 
 -- AND S.CustomerId = PS.CustomerId                      
 WHERE S.ProjectId = @PProjectId                      
  AND S.CustomerId = @PCustomerId                      
  AND S.IsLastLevel = 1                      
AND ISNULL(S.IsDeleted, 0) = 0                      
 UNION                      
 SELECT 0 AS SectionId                      
  ,MS.SectionId AS mSectionId                      
  ,MS.Description                      
  ,MS.Author                      
  ,MS.SectionCode                      
  ,MS.SourceTag                      
  ,@PSourceTagFormat SourceTagFormat --P.SourceTagFormat                      
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                      
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                      
  ,ISNULL(D.DivisionId, 0) AS DivisionId                      
  ,CONVERT(BIT, 0) AS IsTrackChanges                      
 FROM SLCMaster..Section MS WITH (NOLOCK)                      
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON MS.DivisionId = D.DivisionId                      
 --INNER JOIN ProjectSummary P WITH (NOLOCK) ON P.ProjectId = @PProjectId                      
 -- AND P.CustomerId = @PCustomerId                    
 LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON MS.SectionId = PS.mSectionId                      
  AND PS.ProjectId = @PProjectId                      
  AND PS.CustomerId = @PCustomerId                      
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                      
  AND MS.IsLastLevel = 1                      
  AND PS.SectionId IS NULL                      
  AND ISNULL(PS.IsDeleted, 0) = 0                      
                      
 --SELECT SEGMENT REQUIREMENT TAGS DATA                                          
 SELECT PSRT.SegmentStatusId                      
  ,PSRT.SegmentRequirementTagId                      
  ,PSST.mSegmentStatusId                      
  ,LPRT.RequirementTagId                      
  ,LPRT.TagType                      
  ,LPRT.Description AS TagName                      
  ,CASE                       
   WHEN PSRT.mSegmentRequirementTagId IS NULL                      
    THEN CAST(0 AS BIT)                      
   ELSE CAST(1 AS BIT)                      
   END AS IsMasterAppliedTag                      
  ,PSST.SectionId                      
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                      
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK) ON PSRT.RequirementTagId = LPRT.RequirementTagId                      
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSRT.SegmentStatusId = PSST.SegmentStatusId                      
 WHERE PSRT.ProjectId = @PProjectId                      
  AND PSRT.CustomerId = @PCustomerId                      
                           
 --SELECT REQUIRED IMAGES DATA                                          
 SELECT                 
  PIMG.SegmentImageId                
 ,IMG.ImageId                
 ,IMG.ImagePath                
 ,COALESCE(PIMG.ImageStyle,'')  as ImageStyle              
 ,PIMG.SectionId                 
 ,ISNULL(IMG.LuImageSourceTypeId,0) as LuImageSourceTypeId  
              
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                      
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                      
 --INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId    //To resolved cross section images in headerFooter                   
 WHERE PIMG.ProjectId = @PProjectId                      
  AND PIMG.CustomerId = @PCustomerId                      
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)        
UNION ALL -- This union to ge Note images        
 SELECT                 
  0 SegmentImageId                
 ,PN.ImageId                
 ,IMG.ImagePath                
 ,'' ImageStyle                
 ,PN.SectionId                 
 ,ISNULL(IMG.LuImageSourceTypeId,0) as   LuImageSourceTypeId       
 FROM ProjectNoteImage PN  WITH (NOLOCK)             
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId        
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId        
 WHERE PN.ProjectId = @PProjectId                      
  AND PN.CustomerId = @PCustomerId           
 UNION ALL -- This union to ge Master Note images         
 select         
  0 SegmentImageId                  
 ,NI.ImageId                  
 ,MIMG.ImagePath                  
 ,'' ImageStyle                  
 ,NI.SectionId                   
 ,ISNULL(MIMG.LuImageSourceTypeId,0) as    LuImageSourceTypeId       
from slcmaster..NoteImage NI with (nolock)        
INNER JOIN ProjectSection PS with (nolock) on NI.SectionId = PS.mSectionId        
INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId        
INNER JOIN SLCMaster..Image MIMG WITH (NOLOCK) ON MIMG.ImageId = NI.ImageId        
   
 --SELECT HYPERLINKS DATA                                          
 SELECT HLNK.HyperLinkId                      
  ,HLNK.LinkTarget                      
  ,HLNK.LinkText                      
  ,'U' AS Source                      
  ,HLNK.SectionId                      
 FROM ProjectHyperLink HLNK WITH (NOLOCK)                      
 INNER JOIN @SectionIdTbl SIDTBL ON HLNK.SectionId = SIDTBL.SectionId                      
 WHERE HLNK.ProjectId = @PProjectId                      
  AND HLNK.CustomerId = @PCustomerId                      
  UNION ALL -- To get Master Hyperlinks      
  SELECT MLNK.HyperLinkId          
  ,MLNK.LinkTarget                      
  ,MLNK.LinkText                      
  ,'M' AS Source                      
  ,MLNK.SectionId                      
 FROM slcmaster..Hyperlink MLNK WITH (NOLOCK)       
 INNER JOIN #tmpProjectSegmentStatusForNote PSS WITH (NOLOCK) ON  MLNK.SegmentStatusId = PSS.mSegmentStatusId      
                    
 --SELECT SEGMENT USER TAGS DATA                                          
 SELECT PSUT.SegmentUserTagId                      
  ,PSUT.SegmentStatusId                      
  ,PSUT.UserTagId                      
  ,PUT.TagType                      
  ,PUT.Description AS TagName                      
  ,PSUT.SectionId                      
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                      
 INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId                      
 INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                      
 WHERE PSUT.ProjectId = @PProjectId                      
  AND PSUT.CustomerId = @PCustomerId               
        
 --SELECT Project Summary information                                          
 SELECT P.ProjectId AS ProjectId                      
  ,P.Name AS ProjectName                      
  ,'' AS ProjectLocation                      
  ,@IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate                      
  ,@PSourceTagFormat AS SourceTagFormat                      
  ,CONCAT(@State,@City) AS DbInfoProjectLocationKeyword                      
  ,ISNULL(PGT.value, '') AS ProjectLocationKeyword                      
  ,@UnitOfMeasureValueTypeId AS UnitOfMeasureValueTypeId                      
 FROM Project P WITH (NOLOCK)                      
 --INNER JOIN ProjectSummary PS WITH (NOLOCK) ON P.ProjectId = PS.ProjectId                      
 INNER JOIN ProjectAddress PA WITH (NOLOCK) ON P.ProjectId = PA.ProjectId                      
 LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK) ON P.ProjectId = PGT.ProjectId                      
  AND PGT.mGlobalTermId = 11                      
 WHERE P.ProjectId = @PProjectId                      
  AND P.CustomerId = @PCustomerId                      
                      
 --SELECT REFERENCE STD DATA                                       
 SELECT MREFSTD.RefStdId as Id                 
  ,COALESCE(MREFSTD.RefStdName, '') AS RefStdName                      
  ,'M' AS RefStdSource                      
  ,COALESCE(MREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                      
  ,'M' AS ReplaceRefStdSource                      
  ,MREFSTD.IsObsolete AS IsObsolute                      
  ,COALESCE(MREFSTD.RefStdCode, 0) AS RefStdCode                      
 FROM SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)                      
 WHERE MREFSTD.MasterDataTypeId = CASE                       
   WHEN @MasterDataTypeId = 2                      
    OR @MasterDataTypeId = 3                      
    THEN 1                      
   ELSE @MasterDataTypeId                      
   END                      
                       
 UNION                      
                       
 SELECT PREFSTD.RefStdId  as Id                    
  ,PREFSTD.RefStdName                      
  ,'U' AS RefStdSource                      
  ,COALESCE(PREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                      
  ,COALESCE(PREFSTD.ReplaceRefStdSource, '') AS ReplaceRefStdSource                      
  ,PREFSTD.IsObsolete as IsObsolute                     
  ,COALESCE(PREFSTD.RefStdCode, 0) AS RefStdCode                      
 FROM ReferenceStandard PREFSTD WITH (NOLOCK)                      
 WHERE PREFSTD.CustomerId = @PCustomerId                      
                      
 --SELECT REFERENCE EDITION DATA                                          
 SELECT MREFEDN.RefStdId                      
  ,MREFEDN.RefStdEditionId as Id                     
  ,MREFEDN.RefEdition                      
  ,MREFEDN.RefStdTitle                      
  ,MREFEDN.LinkTarget                      
  ,'M' AS RefEdnSource                      
 FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)                      
 WHERE MREFEDN.MasterDataTypeId = CASE                       
   WHEN @MasterDataTypeId = 2                      
    OR @MasterDataTypeId = 3                      
    THEN 1                      
   ELSE @MasterDataTypeId                      
   END                      
                       
 UNION                      
                       
 SELECT PREFEDN.RefStdId                      
  ,PREFEDN.RefStdEditionId as Id                     
  ,PREFEDN.RefEdition                      
  ,PREFEDN.RefStdTitle                      
  ,PREFEDN.LinkTarget                      
  ,'U' AS RefEdnSource                      
 FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)                      
 WHERE PREFEDN.CustomerId = @PCustomerId                      
                      
 --SELECT ProjectReferenceStandard MAPPING DATA                                          
 SELECT PREFSTD.RefStandardId                      
  ,PREFSTD.RefStdSource                      
  ,COALESCE(PREFSTD.mReplaceRefStdId, 0) AS mReplaceRefStdId                      
  ,PREFSTD.RefStdEditionId                      
  ,SIDTBL.SectionId                      
 FROM @SectionIdTbl SIDTBL                      
 INNER JOIN ProjectReferenceStandard PREFSTD WITH (NOLOCK) ON PREFSTD.SectionId = SIDTBL.SectionId                      
 WHERE PREFSTD.ProjectId = @PProjectId                      
  AND PREFSTD.CustomerId = @PCustomerId                      
                      
 --SELECT Header/Footer information                                          
 SELECT X.HeaderId                      
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId             
  ,ISNULL(X.SectionId, 0) AS SectionId                      
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                      
  ,ISNULL(X.TypeId, 1) AS TypeId                      
  ,X.DATEFORMAT                      
  ,X.TimeFormat                      
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                      
  ,REPLACE(ISNULL(X.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                      
  ,REPLACE(ISNULL(X.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                      
  ,REPLACE(ISNULL(X.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                      
  ,REPLACE(ISNULL(X.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                      
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId         
  ,X.IsShowLineAboveHeader as  IsShowLineAboveHeader        
  ,X.IsShowLineBelowHeader as  IsShowLineBelowHeader                 
 FROM (                      
  SELECT H.*                      
  FROM Header H WITH (NOLOCK)                      
  INNER JOIN @SectionIdTbl S ON H.SectionId = S.SectionId                      
  WHERE H.ProjectId = @PProjectId                      
   AND H.DocumentTypeId = 1                      
   AND (                      
    ISNULL(H.HeaderFooterCategoryId, 1) = 1                      
    OR H.HeaderFooterCategoryId = 4                      
    )                      
                        
  UNION                      
                        
  SELECT H.*                      
  FROM Header H WITH (NOLOCK)                      
  WHERE H.ProjectId = @PProjectId                      
   AND H.DocumentTypeId = 1                      
   AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                      
   AND (                      
    H.SectionId IS NULL                      
    OR H.SectionId <= 0                      
    )                      
                        
  UNION                      
                        
  SELECT H.*                      
  FROM Header H WITH (NOLOCK)                      
  LEFT JOIN Header TEMP                      
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                      
  WHERE H.CustomerId IS NULL                      
   AND TEMP.HeaderId IS NULL                      
   AND H.DocumentTypeId = 1                      
  ) AS X                      
                      
 SELECT X.FooterId                      
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                      
  ,ISNULL(X.SectionId, 0) AS SectionId                      
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                      
  ,ISNULL(X.TypeId, 1) AS TypeId                      
  ,X.DATEFORMAT                      
  ,X.TimeFormat                      
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                      
  ,REPLACE(ISNULL(X.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                      
  ,REPLACE(ISNULL(X.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter                      
  ,REPLACE(ISNULL(X.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                      
  ,REPLACE(ISNULL(X.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                      
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId          
  ,X.IsShowLineAboveFooter as  IsShowLineAboveFooter        
  ,X.IsShowLineBelowFooter as  IsShowLineBelowFooter                      
 FROM (                
  SELECT F.*                      
  FROM Footer F WITH (NOLOCK)                      
  INNER JOIN @SectionIdTbl S ON F.SectionId = S.SectionId                      
  WHERE F.ProjectId = @PProjectId                      
   AND F.DocumentTypeId = 1                      
   AND (                      
    ISNULL(F.HeaderFooterCategoryId, 1) = 1                      
    OR F.HeaderFooterCategoryId = 4                      
    )                      
                        
  UNION                      
                        
  SELECT F.*                      
  FROM Footer F WITH (NOLOCK)                      
  WHERE F.ProjectId = @PProjectId                      
   AND F.DocumentTypeId = 1             
   AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                      
   AND (                      
    F.SectionId IS NULL                      
    OR F.SectionId <= 0                      
    )                      
                        
  UNION                      
                        
  SELECT F.*                      
  FROM Footer F WITH (NOLOCK)                      
  LEFT JOIN Footer TEMP                      
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                      
  WHERE F.CustomerId IS NULL                      
   AND F.DocumentTypeId = 1                      
   AND TEMP.FooterId IS NULL                      
  ) AS X                      
                      
 --SELECT PageSetup INFORMATION                                          
 SELECT PageSetting.ProjectPageSettingId AS ProjectPageSettingId                      
  ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId                      
  ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop                      
  ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom                      
  ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft                      
  ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight                      
  ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader                      
  ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter                      
  ,PageSetting.IsMirrorMargin AS IsMirrorMargin                      
  ,PageSetting.ProjectId AS ProjectId                      
  ,PageSetting.CustomerId AS CustomerId                      
  ,ISNULL(PaperSetting.PaperName,'A4') AS PaperName                      
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                      
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                      
  ,COALESCE(PaperSetting.PaperOrientation,'') AS PaperOrientation                      
  ,COALESCE(PaperSetting.PaperSource,'') AS PaperSource                      
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                      
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) ON PageSetting.ProjectId = PaperSetting.ProjectId                    
 WHERE PageSetting.ProjectId = @PProjectId                      
        
IF(@IsPrintMasterNote = 1  OR @IsPrintProjectNote =1)  
BEGIN  
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/        
SELECT       
NoteId      
,PN.SectionId        
,isnull(PSS.SegmentStatusId,0)SegmentStatusId        
,PSS.mSegmentStatusId         
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)       
 ELSE NoteText END NoteText        
,PN.ProjectId      
,PN.CustomerId      
,PN.IsDeleted      
,NoteCode ,      
COALESCE(PN.Title,'') as NoteType     
FROM @SectionIdTbl SIDTBL       
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PSS.SectionId  = SIDTBL.SectionId    
INNER JOIN  ProjectNote PN WITH (NOLOCK)  ON PN.SegmentStatusId = PSS.SegmentStatusId  
AND PN.ProjectId= @PProjectId AND PN.SectionId = PSS.SectionId   
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0        
UNION ALL        
SELECT NoteId        
,0 SectionId        
,PSS.SegmentStatusId         
,isnull(PSS.mSegmentStatusId,0) as mSegmentStatusId         
,NoteText        
,@PProjectId As ProjectId         
,@PCustomerId As CustomerId         
,0 IsDeleted        
,0 NoteCode ,      
'' As NoteType      
 FROM @SectionIdTbl SIDTBL    
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)      
ON PSS.SectionId = SIDTBL.SectionId    
INNER JOIN SLCMaster..Note MN  WITH (NOLOCK)   ON  
 ISNULL(PSS.mSegmentStatusId, 0) > 0 and  MN.SegmentStatusId = PSS.mSegmentStatusId   
 AND PSS.SectionId = SIDTBL.SectionId   
 WHERE ISNULL(PSS.mSegmentStatusId, 0) > 0     
      
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/        
End;  
  
END
GO
PRINT N'Altering [dbo].[usp_GetSegmentsForPrintPDF]...';


GO

ALTER PROCEDURE [dbo].[usp_GetSegmentsForPrintPDF] (                  
 @ProjectId INT                  
 ,@CustomerId INT                  
 ,@SectionIdsString NVARCHAR(MAX)                  
 ,@UserId INT                  
 ,@CatalogueType NVARCHAR(MAX)                  
 ,@TCPrintModeId INT = 1                  
 ,@IsActiveOnly BIT = 1                
  ,@IsPrintMasterNote BIT =0         
 ,@IsPrintProjectNote BIT =0              
 )                  
AS                  
BEGIN                  
 DECLARE @PProjectId INT = @ProjectId;                  
 DECLARE @PCustomerId INT = @CustomerId;                  
 DECLARE @PSectionIdsString NVARCHAR(MAX) = @SectionIdsString;                  
 DECLARE @PUserId INT = @UserId;                  
 DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                  
 DECLARE @PTCPrintModeId INT = @TCPrintModeId;                  
 DECLARE @PIsActiveOnly BIT = @IsActiveOnly;                  
 DECLARE @IsFalse BIT = 0;                  
 DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);                  
 DECLARE @STCPrintModeId NVARCHAR(2) = convert(NVARCHAR, @TCPrintModeId);                  
 DECLARE @SIsActiveOnly NVARCHAR(2) = convert(NVARCHAR, @IsActiveOnly);                  
 DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);                  
 DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);                  
 DECLARE @MasterDataTypeId INT = (                  
   SELECT P.MasterDataTypeId                  
   FROM Project P WITH (NOLOCK)                  
   WHERE P.ProjectId = @PProjectId                  
    AND P.CustomerId = @PCustomerId                  
   );                  
 DECLARE @SectionIdTbl TABLE (SectionId INT);                  
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));                  
 DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';                  
 DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';                  
 DECLARE @Lu_InheritFromSection INT = 1;                  
 DECLARE @Lu_AllWithMarkups INT = 2;                  
 DECLARE @Lu_AllWithoutMarkups INT = 3;                 
 DECLARE @ImagSegment int =1      
 DECLARE @ImageHeaderFooter int =3      
                  
 --CONVERT STRING INTO TABLE                                      
 INSERT INTO @SectionIdTbl (SectionId)                  
 SELECT *                  
 FROM dbo.fn_SplitString(@PSectionIdsString, ',');                  
                  
 --CONVERT CATALOGUE TYPE INTO TABLE                                  
 IF @PCatalogueType IS NOT NULL                  
  AND @PCatalogueType != 'FS'                  
 BEGIN                  
  INSERT INTO @CatalogueTypeTbl (TagType)                  
  SELECT *                  
  FROM dbo.fn_SplitString(@PCatalogueType, ',');                  
                  
  IF EXISTS (                  
    SELECT *                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'OL'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('UO')                  
  END                  
                  
  IF EXISTS (                  
    SELECT TOP 1 1                  
    FROM @CatalogueTypeTbl                  
    WHERE TagType = 'SF'                  
    )                  
  BEGIN                  
   INSERT INTO @CatalogueTypeTbl                  
   VALUES ('US')                  
  END                  
 END                  
                  
 --DROP TEMP TABLES IF PRESENT                                      
 DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSegmentStatus;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_Template;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_SelectedChoiceOption;                  
  DROP TABLE                  
                  
 IF EXISTS #tmp_ProjectSection;                  
  --FETCH SECTIONS DATA IN TEMP TABLE                                  
  SELECT PS.SectionId                  
   ,PS.ParentSectionId                  
   ,PS.mSectionId                  
   ,PS.ProjectId                  
   ,PS.CustomerId                  
   ,PS.UserId                  
   ,PS.DivisionId      
   ,PS.DivisionCode                  
   ,PS.Description                  
   ,PS.LevelId                  
   ,PS.IsLastLevel                  
   ,PS.SourceTag                  
   ,PS.Author                  
   ,PS.TemplateId                  
   ,PS.SectionCode                  
   ,PS.IsDeleted                  
   ,PS.SpecViewModeId                  
   ,PS.IsTrackChanges                  
  INTO #tmp_ProjectSection                  
  FROM ProjectSection PS WITH (NOLOCK)                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND ISNULL(PS.IsDeleted, 0) = 0;                  
                  
 --FETCH SEGMENT STATUS DATA INTO TEMP TABLE                              
 SELECT PSST.SegmentStatusId            
  ,PSST.SectionId                  
  ,PSST.ParentSegmentStatusId                  
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                  
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                  
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId             
  ,PSST.SegmentSource                  
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                  
  ,CASE                   
   WHEN PSST.IndentLevel > 8                  
    THEN CAST(8 AS TINYINT)                  
   ELSE PSST.IndentLevel                  
   END AS IndentLevel                  
  ,PSST.SequenceNumber                  
  ,PSST.SegmentStatusTypeId                  
  ,PSST.SegmentStatusCode                  
  ,PSST.IsParentSegmentStatusActive                  
  ,PSST.IsShowAutoNumber                  
  ,PSST.FormattingJson                  
  ,STT.TagType                  
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                  
  ,PSST.IsRefStdParagraph                  
  ,PSST.IsPageBreak                  
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                  
  ,PSST.MTrackDescription                  
 INTO #tmp_ProjectSegmentStatus                  
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                  
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                  
 WHERE PSST.ProjectId = @PProjectId                  
  AND PSST.CustomerId = @PCustomerId                  
  AND (                  
   PSST.IsDeleted IS NULL                  
   OR PSST.IsDeleted = 0                  
   )                  
  AND (                  
   @PIsActiveOnly = @IsFalse                  
   OR (                  
    PSST.SegmentStatusTypeId > 0                  
    AND PSST.SegmentStatusTypeId < 6                  
    AND PSST.IsParentSegmentStatusActive = 1                  
    )                  
   OR (PSST.IsPageBreak = 1)                  
   )                  
  AND (                  
   @PCatalogueType = 'FS'                  
   OR STT.TagType IN (                  
    SELECT TagType                  
    FROM @CatalogueTypeTbl                  
    )                  
   )                  
                  
 --SELECT SEGMENT STATUS DATA                                      
 SELECT SegmentStatusId,SectionId,ParentSegmentStatusId,mSegmentStatusId,mSegmentId,SegmentId,SegmentSource,SegmentOrigin
 ,IndentLevel,SequenceNumber,SegmentStatusTypeId,isnull(SegmentStatusCode,0) as SegmentStatusCode,IsParentSegmentStatusActive
 ,IsShowAutoNumber, COALESCE(TagType,'')TagType,isnull(SpecTypeTagId,0)as SpecTypeTagId,COALESCE(FormattingJson,'') as FormattingJson
 ,IsRefStdParagraph,IsPageBreak,COALESCE(TrackOriginOrder,'') AS TrackOriginOrder, @PProjectId as ProjectId
  ,@PCustomerId as CustomerId              
 FROM #tmp_ProjectSegmentStatus PSST                  
 ORDER BY PSST.SectionId                  
  ,PSST.SequenceNumber;                  
   
DROP TABLE IF EXISTS #tmpProjectSegmentStatusForNote;     
 --FETCH SegmentStatusId AND MSegmentStatusId DATA INTO TEMP TABLE       
SELECT PSST.SegmentStatusId              
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                    
 INTO #tmpProjectSegmentStatusForNote                    
 FROM ProjectSegmentStatus AS PSST WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl SIDTBL ON PSST.SectionId = SIDTBL.SectionId                   
 WHERE PSST.ProjectId = @PProjectId   
 AND PSST.CustomerId = @PCustomerId    
  
 --SELECT SEGMENT DATA                                      
 SELECT PSST.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,(                  
   CASE                   
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 1                  
     THEN COALESCE(PSG.SegmentDescription, '')                  
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                  
     AND PS.IsTrackChanges = 0                  
     THEN COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    ELSE COALESCE(PSG.BaseSegmentDescription, PSG.SegmentDescription, '')                  
    END                  
   ) AS SegmentDescription                  
  ,PSG.SegmentSource                  
  ,ISNULL(PSG.SegmentCode ,0)AS SegmentCode
  ,@PProjectId as ProjectId
  ,@PCustomerId as CustomerId                 
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN ProjectSegment AS PSG WITH (NOLOCK) ON PSST.SegmentId = PSG.SegmentId                  
 WHERE PSG.ProjectId = @PProjectId                  
  AND PSG.CustomerId = @PCustomerId                  
                   
 UNION                  
                   
 SELECT MSG.SegmentId                  
  ,PSST.SegmentStatusId                  
  ,PSST.SectionId                  
  ,CASE                   
   WHEN PSST.ParentSegmentStatusId = 0                AND PSST.SequenceNumber = 0                  
    THEN PS.Description                  
   ELSE ISNULL(MSG.SegmentDescription, '')                  
   END AS SegmentDescription                  
  ,MSG.SegmentSource                  
  ,ISNULL(MSG.SegmentCode  ,0) as SegmentCode
  ,@PProjectId as ProjectId
  ,@PCustomerId as CustomerId   
 FROM #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK)                  
 INNER JOIN #tmp_ProjectSection AS PS WITH (NOLOCK) ON PSST.SectionId = PS.SectionId                  
 INNER JOIN SLCMaster..Segment AS MSG WITH (NOLOCK) ON PSST.mSegmentId = MSG.SegmentId                  
 WHERE PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
                  
 --FETCH TEMPLATE DATA INTO TEMP TABLE                                      
 SELECT *                  
 INTO #tmp_Template                  
 FROM (                  
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                  
   ,T.IsDeleted                  
   ,0 AS SectionId                 
   ,T.ApplyTitleStyleToEOS              
   ,CAST(1 AS BIT) AS IsDefault                  
  --FROM Template T WITH (NOLOCK)                  
  FROM TemplatePDF T WITH (NOLOCK) 
  INNER JOIN Project P WITH (NOLOCK) ON T.TemplateId = COALESCE(P.TemplateId, 1)                  
  WHERE P.ProjectId = @PProjectId                  
   AND P.CustomerId = @PCustomerId                  
                    
  UNION                  
                    
  SELECT T.TemplateId                  
   ,T.Name                  
   ,T.TitleFormatId                  
   ,T.SequenceNumbering                  
   ,T.IsSystem                
   ,T.IsDeleted                  
   ,PS.SectionId                  
   ,T.ApplyTitleStyleToEOS              
   ,CAST(0 AS BIT) AS IsDefault                  
  --FROM Template T WITH (NOLOCK)       
  FROM TemplatePDF T WITH (NOLOCK) 
  INNER JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON T.TemplateId = PS.TemplateId                  
  INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId                  
  WHERE PS.ProjectId = @PProjectId                  
   AND PS.CustomerId = @PCustomerId                  
   AND PS.TemplateId IS NOT NULL       
  ) AS X                  
                  
 --SELECT TEMPLATE DATA                                      
 SELECT * ,@PCustomerId as CustomerId                   
 FROM #tmp_Template T                  
                  
 --SELECT TEMPLATE STYLE DATA                                      
 SELECT TS.TemplateStyleId                  
  ,TS.TemplateId                  
  ,TS.StyleId                  
  ,TS.LEVEL 
   ,@PCustomerId as CustomerId 
 --FROM TemplateStyle TS WITH (NOLOCK)        
 FROM TemplateStylePDF TS WITH (NOLOCK)        
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId                  
                  
 --SELECT STYLE DATA                                      
 SELECT ST.StyleId                  
  ,ST.Alignment                  
  ,ST.IsBold                  
  ,ST.CharAfterNumber                  
  ,ST.CharBeforeNumber                  
  ,ST.FontName                  
  ,ST.FontSize                  
  ,ST.HangingIndent                  
  ,ST.IncludePrevious                  
  ,ST.IsItalic                  
  ,ST.LeftIndent                  
  ,ST.NumberFormat                  
  ,ST.NumberPosition          
  ,ST.PrintUpperCase                  
  ,ST.ShowNumber                  
  ,ST.StartAt                  
  ,ST.Strikeout                  
  ,ST.Name                  
  ,ST.TopDistance                  
  ,ST.Underline                  
  ,ST.SpaceBelowParagraph                  
  ,ST.IsSystem                  
  ,ST.IsDeleted                  
  ,CAST(TS.LEVEL AS INT) AS LEVEL         
  ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing    
  ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId    
  ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId    
  ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId       
   ,@PCustomerId as CustomerId 
 --FROM Style AS ST WITH (NOLOCK)                  
 --INNER JOIN TemplateStyle AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId   
 FROM StylePDF AS ST WITH (NOLOCK)                  
 INNER JOIN TemplateStylePDF AS TS WITH (NOLOCK) ON ST.StyleId = TS.StyleId   
 INNER JOIN #tmp_Template T WITH (NOLOCK) ON TS.TemplateId = T.TemplateId      
  LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId              
                  
 --SELECT GLOBAL TERM DATA                                      
 SELECT PGT.GlobalTermId                  
  ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                  
  ,PGT.Name                  
  ,ISNULL(PGT.value, '') AS value                  
  ,PGT.CreatedDate                  
  ,PGT.CreatedBy                  
  ,PGT.ModifiedDate                  
  ,PGT.ModifiedBy                  
  ,PGT.GlobalTermSource                  
  ,ISNULL(PGT.GlobalTermCode,0) AS GlobalTermCode                  
  ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                  
  ,GlobalTermFieldTypeId   AS GTFieldType   
  ,@PProjectId as ProjectId
  ,@PCustomerId as CustomerId
 FROM ProjectGlobalTerm PGT WITH (NOLOCK)                  
 WHERE PGT.ProjectId = @PProjectId                  
  AND PGT.CustomerId = @PCustomerId;                  
                  
 --SELECT SECTIONS DATA                                      
 SELECT S.SectionId AS SectionId                  
  ,ISNULL(S.mSectionId, 0) AS mSectionId                  
  ,S.Description                  
  ,COALESCE(S.Author,'') as Author                   
  ,ISNULL(S.SectionCode ,0)   AS SectionCode                
  ,COALESCE(S.SourceTag,'') as SourceTag                  
  ,PS.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,S.IsTrackChanges                  
 FROM #tmp_ProjectSection AS S WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON S.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON S.ProjectId = PS.ProjectId                  
  AND S.CustomerId = PS.CustomerId                  
 WHERE S.ProjectId = @PProjectId                  
  AND S.CustomerId = @PCustomerId                  
  AND S.IsLastLevel = 1                  
AND ISNULL(S.IsDeleted, 0) = 0                  
                   
 UNION                  
                   
 SELECT 0 AS SectionId                  
  ,MS.SectionId AS mSectionId                  
  ,MS.Description                  
  ,MS.Author                  
  ,MS.SectionCode                  
  ,MS.SourceTag                  
  ,P.SourceTagFormat                  
  ,ISNULL(D.DivisionCode, '') AS DivisionCode                  
  ,ISNULL(D.DivisionTitle, '') AS DivisionTitle                  
  ,ISNULL(D.DivisionId, 0) AS DivisionId                  
  ,CONVERT(BIT, 0) AS IsTrackChanges                  
 FROM SLCMaster..Section MS WITH (NOLOCK)                  
 LEFT JOIN SLCMaster..Division D WITH (NOLOCK) ON MS.DivisionId = D.DivisionId                  
 INNER JOIN ProjectSummary P WITH (NOLOCK) ON P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
 LEFT JOIN #tmp_ProjectSection PS WITH (NOLOCK) ON MS.SectionId = PS.mSectionId                  
  AND PS.ProjectId = @PProjectId                  
  AND PS.CustomerId = @PCustomerId                  
 WHERE MS.MasterDataTypeId = @MasterDataTypeId                  
  AND MS.IsLastLevel = 1                  
  AND PS.SectionId IS NULL                  
  AND ISNULL(PS.IsDeleted, 0) = 0                  
                  
 --SELECT SEGMENT REQUIREMENT TAGS DATA                                      
 SELECT PSRT.SegmentStatusId                  
  ,PSRT.SegmentRequirementTagId                  
  ,PSST.mSegmentStatusId                  
  ,LPRT.RequirementTagId                  
  ,LPRT.TagType                  
  ,LPRT.Description AS TagName                  
  ,CASE                   
   WHEN PSRT.mSegmentRequirementTagId IS NULL                  
    THEN CAST(0 AS BIT)                  
   ELSE CAST(1 AS BIT)                  
   END AS IsMasterAppliedTag                  
  ,PSST.SectionId                  
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                  
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK) ON PSRT.RequirementTagId = LPRT.RequirementTagId                  
INNER JOIN #tmp_ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSRT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSRT.ProjectId = @PProjectId                  
  AND PSRT.CustomerId = @PCustomerId                  
                       
 --SELECT REQUIRED IMAGES DATA                                      
 SELECT             
  PIMG.SegmentImageId            
 ,IMG.ImageId            
 ,IMG.ImagePath            
 ,COALESCE(PIMG.ImageStyle,'')  as ImageStyle            
 ,PIMG.SectionId             
 ,ISNULL(IMG.LuImageSourceTypeId,0) as LuImageSourceTypeId    
          
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)                  
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                  
 --INNER JOIN @SectionIdTbl SIDTBL ON PIMG.SectionId = SIDTBL.SectionId    //To resolved cross section images in headerFooter               
 WHERE PIMG.ProjectId = @PProjectId                  
  AND PIMG.CustomerId = @PCustomerId                  
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)    
UNION ALL -- This union to ge Note images    
 SELECT             
  0 SegmentImageId            
 ,PN.ImageId            
 ,IMG.ImagePath            
 ,'' ImageStyle            
 ,PN.SectionId             
 ,ISNULL(IMG.LuImageSourceTypeId , 0) as   LuImageSourceTypeId  
 FROM ProjectNoteImage PN  WITH (NOLOCK)         
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PN.ImageId = IMG.ImageId    
 INNER JOIN @SectionIdTbl SIDTBL ON PN.SectionId = SIDTBL.SectionId    
 WHERE PN.ProjectId = @PProjectId                  
  AND PN.CustomerId = @PCustomerId   
 UNION ALL -- This union to ge Master Note images   
 select   
  0 SegmentImageId            
 ,NI.ImageId            
 ,MIMG.ImagePath            
 ,'' ImageStyle            
 ,NI.SectionId             
 ,ISNULL(MIMG.LuImageSourceTypeId ,0) as   LuImageSourceTypeId 
from slcmaster..NoteImage NI with (nolock)  
INNER JOIN ProjectSection PS with (nolock) on NI.SectionId = PS.mSectionId  
INNER JOIN @SectionIdTbl SIDTBL ON PS.SectionId = SIDTBL.SectionId  
INNER JOIN SLCMaster..Image MIMG WITH (NOLOCK) ON MIMG.ImageId = NI.ImageId                  
                  
 --SELECT HYPERLINKS DATA                                      
 SELECT HLNK.HyperLinkId                  
  ,HLNK.LinkTarget                  
  ,HLNK.LinkText                  
  ,'U' AS Source                  
  ,HLNK.SectionId                  
 FROM ProjectHyperLink HLNK WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON HLNK.SectionId = SIDTBL.SectionId                  
 WHERE HLNK.ProjectId = @PProjectId                  
  AND HLNK.CustomerId = @PCustomerId                  
  UNION ALL -- To get Master Hyperlinks  
  SELECT MLNK.HyperLinkId                  
  ,MLNK.LinkTarget                  
  ,MLNK.LinkText                  
  ,'M' AS Source                  
  ,MLNK.SectionId                  
 FROM slcmaster..Hyperlink MLNK WITH (NOLOCK)   
 INNER JOIN #tmpProjectSegmentStatusForNote PSS WITH (NOLOCK) ON  MLNK.SegmentStatusId = PSS.mSegmentStatusId  
                
 --SELECT SEGMENT USER TAGS DATA                                      
 SELECT PSUT.SegmentUserTagId                  
  ,PSUT.SegmentStatusId                  
  ,PSUT.UserTagId                  
  ,PUT.TagType                  
  ,PUT.Description AS TagName                  
  ,PSUT.SectionId                  
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)                  
 --INNER JOIN ProjectUserTag PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId            
 INNER JOIN ProjectUserTagPDF PUT WITH (NOLOCK) ON PSUT.UserTagId = PUT.UserTagId            
 INNER JOIN #tmp_ProjectSegmentStatus PSST WITH (NOLOCK) ON PSUT.SegmentStatusId = PSST.SegmentStatusId                  
 WHERE PSUT.ProjectId = @PProjectId                  
  AND PSUT.CustomerId = @PCustomerId           
    
 --SELECT Project Summary information                                      
 SELECT P.ProjectId AS ProjectId                  
  ,P.Name AS ProjectName                  
  ,'' AS ProjectLocation                  
  ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate                  
  ,PS.SourceTagFormat AS SourceTagFormat                  
  ,COALESCE(CASE                   
    WHEN len(LState.StateProvinceAbbreviation) > 0                  
     THEN LState.StateProvinceAbbreviation              ELSE PA.StateProvinceName                  
    END + ', ' + CASE                   
    WHEN len(LCity.City) > 0                  
     THEN LCity.City                  
    ELSE PA.CityName                  
    END, '') AS DbInfoProjectLocationKeyword                  
  ,ISNULL(PGT.value, '') AS ProjectLocationKeyword                  
  ,PS.UnitOfMeasureValueTypeId                  
 FROM Project P WITH (NOLOCK)                  
 INNER JOIN ProjectSummary PS WITH (NOLOCK) ON P.ProjectId = PS.ProjectId                  
 INNER JOIN ProjectAddress PA WITH (NOLOCK) ON P.ProjectId = PA.ProjectId                  
 INNER JOIN LuCountry LCountry WITH (NOLOCK) ON PA.CountryId = LCountry.CountryId                  
 LEFT JOIN LuStateProvince LState WITH (NOLOCK) ON PA.StateProvinceId = LState.StateProvinceID                  
 LEFT JOIN LuCity LCity WITH (NOLOCK) ON (                  
PA.CityId = LCity.CityId                  
   OR PA.CityName = LCity.City                  
   )                  
  AND LCity.StateProvinceId = PA.StateProvinceId                  
 LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK) ON P.ProjectId = PGT.ProjectId                  
  AND PGT.mGlobalTermId = 11                  
 WHERE P.ProjectId = @PProjectId                  
  AND P.CustomerId = @PCustomerId                  
                  
 --SELECT REFERENCE STD DATA                                   
 SELECT MREFSTD.RefStdId as Id             
  ,COALESCE(MREFSTD.RefStdName, '') AS RefStdName                  
  ,'M' AS RefStdSource                  
  ,COALESCE(MREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,'M' AS ReplaceRefStdSource                  
  ,MREFSTD.IsObsolete   AS IsObsolute                
  ,COALESCE(MREFSTD.RefStdCode, 0) AS RefStdCode                  
 FROM SLCMaster..ReferenceStandard MREFSTD WITH (NOLOCK)                  
 WHERE MREFSTD.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END                  
                   
 UNION                  
                   
 SELECT PREFSTD.RefStdId   as Id                
  ,PREFSTD.RefStdName                  
  ,'U' AS RefStdSource                  
  ,COALESCE(PREFSTD.ReplaceRefStdId, 0) AS ReplaceRefStdId                  
  ,COALESCE(PREFSTD.ReplaceRefStdSource, '') AS ReplaceRefStdSource                  
  ,PREFSTD.IsObsolete      AS IsObsolute             
  ,COALESCE(PREFSTD.RefStdCode, 0) AS RefStdCode                  
 --FROM ReferenceStandard PREFSTD WITH (NOLOCK)    
 FROM ReferenceStandardPDF PREFSTD WITH (NOLOCK)    
 WHERE PREFSTD.CustomerId = @PCustomerId                  
 
 --SELECT REFERENCE EDITION DATA New Implementation for performance improvement.  
  
 DECLARE @MRSEdition TABLE(RefStdId INT,RefStdEditionId INT,RefEdition VARCHAR(150) , RefStdTitle VARCHAR(500), LinkTarget VARCHAR(500),RefEdnSource CHAR(1))  
 DECLARE @PRSEdition TABLE(RefStdId INT,RefStdEditionId INT,RefEdition VARCHAR(150) , RefStdTitle VARCHAR(500), LinkTarget VARCHAR(500),RefEdnSource CHAR(1))  
   
 INSERT into @MRSEdition  
 SELECT MREFEDN.RefStdId                  
  ,MREFEDN.RefStdEditionId                  
  ,MREFEDN.RefEdition                  
  ,MREFEDN.RefStdTitle                  
  ,MREFEDN.LinkTarget                  
  ,'M' AS RefEdnSource                  
 FROM SLCMaster..ReferenceStandardEdition MREFEDN WITH (NOLOCK)                  
 WHERE MREFEDN.MasterDataTypeId = CASE                   
   WHEN @MasterDataTypeId = 2                  
    OR @MasterDataTypeId = 3                  
    THEN 1                  
   ELSE @MasterDataTypeId                  
   END   
  
 INSERT into @PRSEdition    
 SELECT PREFEDN.RefStdId                  
  ,PREFEDN.RefStdEditionId                  
  ,PREFEDN.RefEdition                  
  ,PREFEDN.RefStdTitle                  
  ,PREFEDN.LinkTarget                  
  ,'U' AS RefEdnSource                  
 --FROM ReferenceStandardEdition PREFEDN WITH (NOLOCK)   
 FROM ReferenceStandardEditionPDF PREFEDN WITH (NOLOCK)   
 WHERE PREFEDN.CustomerId = @PCustomerId        
   
 select RefStdId ,RefStdEditionId as Id ,RefEdition, RefStdTitle, LinkTarget, RefEdnSource
 from @MRSEdition  
 union   
 select RefStdId ,RefStdEditionId as Id ,RefEdition, RefStdTitle, LinkTarget, RefEdnSource
 from @PRSEdition  

                  
 --SELECT ProjectReferenceStandard MAPPING DATA                                      
 SELECT PREFSTD.RefStandardId                  
  ,PREFSTD.RefStdSource                  
  ,COALESCE(PREFSTD.mReplaceRefStdId, 0) AS mReplaceRefStdId                  
  ,PREFSTD.RefStdEditionId                  
  ,SIDTBL.SectionId                  
 FROM ProjectReferenceStandard PREFSTD WITH (NOLOCK)                  
 INNER JOIN @SectionIdTbl SIDTBL ON PREFSTD.SectionId = SIDTBL.SectionId                  
 WHERE PREFSTD.ProjectId = @PProjectId                  
  AND PREFSTD.CustomerId = @PCustomerId                  
                  
 --SELECT Header/Footer information                                      
 SELECT X.HeaderId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                  
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader                  
  ,REPLACE(ISNULL(X.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader                  
  ,REPLACE(ISNULL(X.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader                  
  ,REPLACE(ISNULL(X.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId     
  ,X.IsShowLineAboveHeader as  IsShowLineAboveHeader    
  ,X.IsShowLineBelowHeader as  IsShowLineBelowHeader             
 FROM (                  
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON H.SectionId = S.SectionId                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (                  
    ISNULL(H.HeaderFooterCategoryId, 1) = 1                  
    OR H.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  WHERE H.ProjectId = @PProjectId                  
   AND H.DocumentTypeId = 1                  
   AND (ISNULL(H.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    H.SectionId IS NULL                  
    OR H.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT H.*                  
  FROM Header H WITH (NOLOCK)                  
  LEFT JOIN Header TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE H.CustomerId IS NULL                  
   AND TEMP.HeaderId IS NULL                  
   AND H.DocumentTypeId = 1                  
  ) AS X                  
                  
 SELECT X.FooterId                  
  ,ISNULL(X.ProjectId, @PProjectId) AS ProjectId                  
  ,ISNULL(X.SectionId, 0) AS SectionId                  
  ,ISNULL(X.CustomerId, @PCustomerId) AS CustomerId                  
  ,ISNULL(X.TypeId, 1) AS TypeId                  
  ,X.DATEFORMAT                  
  ,X.TimeFormat                  
  ,ISNULL(X.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId                  
  ,REPLACE(ISNULL(X.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter                  
  ,REPLACE(ISNULL(X.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter                  
  ,REPLACE(ISNULL(X.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter                  
  ,REPLACE(ISNULL(X.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter                  
  ,X.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId      
  ,X.IsShowLineAboveFooter as  IsShowLineAboveFooter    
  ,X.IsShowLineBelowFooter as  IsShowLineBelowFooter                  
 FROM (            
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  INNER JOIN @SectionIdTbl S ON F.SectionId = S.SectionId                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1                  
   AND (                  
    ISNULL(F.HeaderFooterCategoryId, 1) = 1                  
    OR F.HeaderFooterCategoryId = 4                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)                  
  WHERE F.ProjectId = @PProjectId                  
   AND F.DocumentTypeId = 1                  
   AND (ISNULL(F.HeaderFooterCategoryId, 1) = 1)                  
   AND (                  
    F.SectionId IS NULL                  
    OR F.SectionId <= 0                  
    )                  
                    
  UNION                  
                    
  SELECT F.*                  
  FROM Footer F WITH (NOLOCK)           
  LEFT JOIN Footer TEMP                  
  WITH (NOLOCK) ON TEMP.ProjectId = @PProjectId                  
  WHERE F.CustomerId IS NULL                  
   AND F.DocumentTypeId = 1                  
   AND TEMP.FooterId IS NULL                  
  ) AS X                  
                  
 --SELECT PageSetup INFORMATION                                      
 SELECT PageSetting.ProjectPageSettingId AS ProjectPageSettingId                  
  ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId                  
  ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop                  
  ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom                  
  ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft                  
  ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight                  
  ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader                  
  ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter                  
  ,PageSetting.IsMirrorMargin AS IsMirrorMargin                  
  ,PageSetting.ProjectId AS ProjectId                  
  ,PageSetting.CustomerId AS CustomerId                  
  ,COALESCE(PaperSetting.PaperName,'A4') AS PaperName                  
  ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth                  
  ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight                  
  ,COALESCE(PaperSetting.PaperOrientation,'') AS PaperOrientation                    
  ,COALESCE(PaperSetting.PaperSource,'') AS PaperSource                 
 FROM ProjectPageSetting PageSetting WITH (NOLOCK)                  
 INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK) ON PageSetting.ProjectId = PaperSetting.ProjectId                
 WHERE PageSetting.ProjectId = @PProjectId                  
    
/*Start - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
SELECT   
NoteId  
,PN.SectionId    
,PSS.SegmentStatusId SegmentStatusId    
,PSS.mSegmentStatusId mSegmentStatusId    
,CASE WHEN Title != '' THEN CONCAT(Title,'<br/>', NoteText)   
 ELSE NoteText END NoteText    
,PN.ProjectId  
,PN.CustomerId  
,PN.IsDeleted  
,NoteCode  
,COALESCE(PN.Title,'') as NoteType
FROM ProjectNote PN WITH (NOLOCK)   
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK) ON PN.SegmentStatusId = PSS.SegmentStatusId     
WHERE PN.ProjectId=@PProjectId and PN.CustomerId=@PCustomerId AND ISNULL(PN.IsDeleted, 0) = 0    
UNION ALL    
SELECT NoteId    
,0 SectionId    
,PSS.SegmentStatusId SegmentStatusId    
,PSS.mSegmentStatusId mSegmentStatusId    
,NoteText    
,@PProjectId ProjectId     
,@PCustomerId CustomerId     
,0 IsDeleted    
,0 NoteCode
,'' As NoteType
 FROM SLCMaster..Note MN  WITH (NOLOCK)  
INNER JOIN #tmpProjectSegmentStatusForNote PSS  WITH (NOLOCK)  
ON MN.SegmentStatusId = PSS.mSegmentStatusId   
/*End - User Story 35059: Implementation of Print/Export: Print Master and Project Notes*/    
END
GO
PRINT N'Altering [dbo].[usp_GetSegmentsForSection]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSegmentsForSection]  
@ProjectId INT,      
@SectionId INT,       
@CustomerId INT,       
@UserId INT,       
@CatalogueType NVARCHAR (50) NULL='FS'      
AS                                      
BEGIN    
            
 SET NOCOUNT ON;        
            
 DECLARE @PProjectId INT = @ProjectId;                             
         
 DECLARE @PSectionId INT = @SectionId;                              
 DECLARE @PCustomerId INT = @CustomerId;                              
 DECLARE @PUserId INT = @UserId;                              
 DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;                              
            
 --Set mSectionId                                
 DECLARE @MasterSectionId AS INT, @SectionTemplateId AS INT, @SectionTitle NVARCHAR(500) = ''; 
 --SET @MasterSectionId = (SELECT TOP 1 mSectionId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);            
                                
 DECLARE @MasterDataTypeId INT;        
 DECLARE @ProjectTemplateId AS INT;                            
 --SET @MasterDataTypeId = (SELECT TOP 1 MasterDataTypeId FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);             
 SELECT TOP 1 @MasterDataTypeId = MasterDataTypeId, @ProjectTemplateId = ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId        
            
 --FIND TEMPLATE ID FROM                                 
 --DECLARE @ProjectTemplateId AS INT = (SELECT TOP 1 ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);                              
 --DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1 TemplateId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);            
   
 SELECT TOP 1  @MasterSectionId = mSectionId, @SectionTemplateId = TemplateId, @SectionTitle = [Description]  
 FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId;       
   
 DECLARE @DocumentTemplateId INT = 0;            
 DECLARE @IsMasterSection INT = CASE WHEN @MasterSectionId IS NULL THEN 0 ELSE 1 END;    
  
                              
 IF (@SectionTemplateId IS NOT NULL AND @SectionTemplateId > 0)                              
  BEGIN                              
   SET @DocumentTemplateId = @SectionTemplateId;            
  END                                
 ELSE                                
  BEGIN                              
   SET @DocumentTemplateId = @ProjectTemplateId;                              
  END                          
                              
 --CatalogueTypeTbl table                              
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(10));            
                              
 IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'                              
 BEGIN                              
  INSERT INTO @CatalogueTypeTbl (TagType)             
  SELECT splitdata AS TagType FROM fn_SplitString(@PCatalogueType, ',');            
                              
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'OL')                              
  BEGIN                              
   INSERT INTO @CatalogueTypeTbl VALUES ('UO')                              
  END                              
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'SF')                              
  BEGIN                              
   INSERT INTO @CatalogueTypeTbl VALUES ('US')                              
  END                              
 END
       
--IF @IsMasterSection = 1  
-- BEGIN -- Data Mapping SP's                  
--   EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                              
--  ,@SectionId = @PSectionId                              
--  ,@CustomerId = @PCustomerId                              
--  ,@UserId = @PUserId  
--  ,@MasterSectionId =@MasterSectionId;                              
--   EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                    
--  ,@SectionId = @PSectionId                              
--  ,@CustomerId = @PCustomerId                              
--  ,@UserId = @PUserId  
--  ,@MasterSectionId =@MasterSectionId;                              
--   EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                   
--    ,@SectionId = @PSectionId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@UserId = @PUserId  
--    ,@MasterSectionId=@MasterSectionId;                              
--   EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                              
--    ,@SectionId = @PSectionId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@UserId = @PUserId  
--     ,@MasterSectionId=@MasterSectionId;            
--   EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                            
--   ,@SectionId = @PSectionId                              
--   ,@CustomerId = @PCustomerId                              
--   ,@UserId = @PUserId;                              
--   EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@SectionId = @PSectionId       
--    -- NOT IN USE hence commented                         
--   --EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                              
--   --,@CustomerId = @PCustomerId                              
--   --,@SectionId = @PSectionId                    
-- END        
        
 DROP TABLE IF EXISTS #ProjectSegmentStatus;                        
 SELECT                          
  PSS.ProjectId                          
    ,PSS.CustomerId                          
    ,PSS.SectionId                     
    ,PSS.SegmentStatusId                               
    ,PSS.ParentSegmentStatusId                          
    ,ISNULL(PSS.mSegmentStatusId, 0) AS mSegmentStatusId                          
    ,ISNULL(PSS.mSegmentId, 0) AS mSegmentId                          
    ,ISNULL(PSS.SegmentId, 0) AS SegmentId                          
    ,PSS.SegmentSource                          
    ,TRIM(PSS.SegmentOrigin) as SegmentOrigin                  
    ,PSS.IndentLevel                          
    ,ISNULL(MSST.IndentLevel, 0) AS MasterIndentLevel                          
    ,PSS.SequenceNumber                          
    ,PSS.SegmentStatusTypeId                          
    ,PSS.SegmentStatusCode                          
    ,PSS.IsParentSegmentStatusActive                          
    ,PSS.IsShowAutoNumber                          
    ,PSS.FormattingJson                          
    ,STT.TagType                          
    ,CASE                          
   WHEN PSS.SpecTypeTagId IS NULL THEN 0                          
   ELSE PSS.SpecTypeTagId                          
  END AS SpecTypeTagId                          
    ,PSS.IsRefStdParagraph                          
    ,PSS.IsPageBreak                          
    ,PSS.IsDeleted                          
    ,MSST.SpecTypeTagId AS MasterSpecTypeTagId                          
    ,ISNULL(MSST.ParentSegmentStatusId, 0) AS MasterParentSegmentStatusId                          
    ,CASE                          
   WHEN MSST.SegmentStatusId IS NOT NULL AND                          
    MSST.SpecTypeTagId = PSS.SpecTypeTagId THEN CAST(1 AS BIT)                          
   ELSE CAST(0 AS BIT)                          
  END AS IsMasterSpecTypeTag                          
    ,PSS.TrackOriginOrder AS TrackOriginOrder                    
    ,PSS.MTrackDescription                    
    INTO #ProjectSegmentStatus                          
 FROM ProjectSegmentStatus AS PSS WITH (NOLOCK)                          
 LEFT JOIN SLCMaster..SegmentStatus MSST WITH (NOLOCK)                          
  ON PSS.mSegmentStatusId = MSST.SegmentStatusId                          
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)                          
  ON PSS.SpecTypeTagId = STT.SpecTypeTagId                          
 WHERE PSS.SectionId = @PSectionId                          
 AND PSS.ProjectId = @PProjectId                          
 AND PSS.CustomerId = @PCustomerId                          
 AND ISNULL(PSS.IsDeleted, 0) = 0                          
 AND (@PCatalogueType = 'FS'                          
 OR STT.TagType IN (SELECT  TagType FROM @CatalogueTypeTbl))    
    
    
 BEGIN -- Fetching Master and Project Notes    
  SELECT Distinct MN.SegmentStatusId    
  INTO #MasterNotes    
  FROM SLCMaster..Note MN WITH (NOLOCK)    
  WHERE MN.SectionId = @MasterSectionId;    
    
  SELECT Distinct PN.SegmentStatusId    
  INTO #ProjectNotes    
  FROM ProjectNote PN WITH (NOLOCK)    
  WHERE PN.SectionId = @PSectionId AND PN.ProjectId = @PProjectId  AND ISNULL(PN.IsDeleted,0)=0 
  --AND PN.CustomerId=@CustomerId 
 END    
    
    
 SELECT        
  PSS.SegmentStatusId        
 ,PSS.ParentSegmentStatusId        
 ,PSS.mSegmentStatusId        
 ,PSS.mSegmentId        
 ,PSS.SegmentId        
 ,PSS.SegmentSource        
 ,PSS.SegmentOrigin        
 ,PSS.IndentLevel        
 ,PSS.MasterIndentLevel        
 ,PSS.SequenceNumber        
 ,PSS.SegmentStatusTypeId        
 ,PSS.SegmentStatusCode        
 ,PSS.IsParentSegmentStatusActive        
 ,PSS.IsShowAutoNumber        
 ,PSS.FormattingJson        
 ,PSS.TagType        
 ,PSS.SpecTypeTagId        
 ,PSS.IsRefStdParagraph    
 ,PSS.IsPageBreak        
 ,PSS.IsDeleted        
 ,PSS.MasterSpecTypeTagId        
 ,PSS.MasterParentSegmentStatusId        
 ,PSS.IsMasterSpecTypeTag        
 ,PSS.TrackOriginOrder        
 ,PSS.MTrackDescription    
 ,CASE WHEN (MN.SegmentStatusId IS NOT NULL AND @IsMasterSection = 1) THEN 1 ELSE 0 END AS HasMasterNote      
 ,CASE WHEN (PN.SegmentStatusId IS NOT NULL) THEN 1 ELSE 0 END AS HasProjectNote    
 FROM #ProjectSegmentStatus PSS WITH (NOLOCK)    
 LEFT JOIN #MasterNotes MN WITH (NOLOCK)      
  ON MN.SegmentStatusId = PSS.mSegmentStatusId      
 LEFT JOIN #ProjectNotes PN WITH (NOLOCK)    
  ON PN.SegmentStatusId = PSS.SegmentStatusId    
 ORDER BY SequenceNumber;        
    
                          
 SELECT                          
  *                          
 FROM (SELECT                          
   PSG.SegmentId                          
  ,PSST.SegmentStatusId                          
  ,PSG.SectionId                          
  ,ISNULL(PSG.SegmentDescription, '') AS SegmentDescription                          
  ,PSG.SegmentSource                          
  ,PSG.SegmentCode                          
  FROM #ProjectSegmentStatus AS PSST WITH (NOLOCK)                          
  INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)                          
   ON PSST.SegmentId = PSG.SegmentId                          
   AND PSST.SectionId = PSG.SectionId                          
   AND PSST.ProjectId = PSG.ProjectId                          
   AND PSST.CustomerId = PSG.CustomerId                          
  WHERE PSG.SectionId = @PSectionId                          
  AND ISNULL(PSST.IsDeleted, 0) = 0                          
  UNION ALL                          
  SELECT                          
   MSG.SegmentId                          
  ,PST.SegmentStatusId                          
  ,PST.SectionId                          
  ,CASE WHEN PST.ParentSegmentStatusId = 0 AND PST.SequenceNumber = 0 THEN @SectionTitle ELSE ISNULL(MSG.SegmentDescription, '') END AS SegmentDescription                          
  ,MSG.SegmentSource  
  ,MSG.SegmentCode                          
  FROM #ProjectSegmentStatus AS PST WITH (NOLOCK)                          
  --INNER JOIN ProjectSection AS PS WITH (NOLOCK)                          
  -- ON PST.SectionId = PS.SectionId                          
  INNER JOIN SLCMaster.dbo.Segment AS MSG WITH (NOLOCK)                          
   ON PST.mSegmentId = MSG.SegmentId                             
  ) AS X        
          
		  --NOTE- @Sanjay - Create new SP usp_GetSectionChoices hence commented                    
 ----NOTE -- Need to fetch distinct SelectedChoiceOption records     
 --DROP TABLE IF EXISTS #SelectedChoiceOptionTempMaster    SELECT DISTINCT   
 -- SCHOP.SegmentChoiceCode   
 --   ,SCHOP.ChoiceOptionCode   
 --   ,SCHOP.ChoiceOptionSource   
 --   ,SCHOP.IsSelected   
 --   ,SCHOP.ProjectId   
 --   ,SCHOP.SectionId   
 --   ,SCHOP.CustomerId   
 --   ,0 AS SelectedChoiceOptionId   
 --   ,SCHOP.OptionJson  
 --INTO #SelectedChoiceOptionTempMaster   
 --FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
 --WHERE SCHOP.SectionId = @PSectionId      
 --AND SCHOP.ProjectId = @PProjectId  
 --AND SCHOP.CustomerId = @PCustomerId   
 --AND ISNULL(SCHOP.IsDeleted, 0) = 0  
 --AND SCHOP.ChoiceOptionSource = 'M'    
  
 ----NOTE -- Need to fetch distinct SelectedChoiceOption records     
 --DROP TABLE IF EXISTS #SelectedChoiceOptionTempProject  
 --SELECT DISTINCT   
 -- SCHOP.SegmentChoiceCode   
 --   ,SCHOP.ChoiceOptionCode   
 --   ,SCHOP.ChoiceOptionSource   
 --   ,SCHOP.IsSelected   
 --   ,SCHOP.ProjectId   
 --   ,SCHOP.SectionId   
 --   ,SCHOP.CustomerId   
 --   ,0 AS SelectedChoiceOptionId   
 --   ,SCHOP.OptionJson  
 --INTO #SelectedChoiceOptionTempProject   
 --FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
 --WHERE SCHOP.SectionId = @PSectionId      
 --AND SCHOP.ProjectId = @PProjectId  
 --AND SCHOP.CustomerId = @PCustomerId   
 --AND ISNULL(SCHOP.IsDeleted, 0) = 0  
 --AND SCHOP.ChoiceOptionSource = 'U'    
  
   
 ----FETCH MASTER + USER CHOICES AND THEIR OPTIONS  
 --SELECT    
 -- 0 AS SegmentId    
 --   ,MCH.SegmentId AS mSegmentId    
 --   ,MCH.ChoiceTypeId    
 --   ,'M' AS ChoiceSource    
 --   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
 --   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
 --   ,PSCHOP.IsSelected    
 --   ,PSCHOP.ChoiceOptionSource    
 --   ,CASE    
 --  WHEN PSCHOP.IsSelected = 1 AND    
 --   PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson    
 --  ELSE MCHOP.OptionJson    
 -- END AS OptionJson    
 --   ,MCHOP.SortOrder    
 --   ,MCH.SegmentChoiceId    
 --   ,MCHOP.ChoiceOptionId    
 --   ,PSCHOP.SelectedChoiceOptionId    
 --FROM #ProjectSegmentStatus PSST WITH (NOLOCK)    
 --INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)    
 -- ON PSST.mSegmentId = MCH.SegmentId AND MCH.SectionId=@MasterSectionId  
 --INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)    
 -- ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId    
 --INNER JOIN #SelectedChoiceOptionTempMaster PSCHOP WITH (NOLOCK)    
 --  --AND PSCHOP.ChoiceOptionSource = 'M'    
 --  ON PSCHOP.SectionId = @PSectionId    
 --  AND PSCHOP.ProjectId = @PProjectId    
 --  AND MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode    
 --  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
 --WHERE  
 --PSST.SectionId = @PSectionId   AND   
 --MCH.SectionId = @MasterSectionId     
 --AND PSST.ProjectId = @PProjectId    
 --AND PSST.CustomerId = @PCustomerId    
 --AND ISNULL(PSST.IsDeleted, 0) = 0    
 --UNION ALL    
 --SELECT    
 -- PCH.SegmentId    
 --   ,0 AS mSegmentId    
 --   ,PCH.ChoiceTypeId    
 --   ,PCH.SegmentChoiceSource AS ChoiceSource    
 --   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
 --   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
 --   ,PSCHOP.IsSelected    
 --   ,PSCHOP.ChoiceOptionSource    
 --   ,PCHOP.OptionJson    
 --   ,PCHOP.SortOrder    
 --   ,PCH.SegmentChoiceId    
 --   ,PCHOP.ChoiceOptionId    
 --   ,PSCHOP.SelectedChoiceOptionId    
 --FROM #ProjectSegmentStatus PSST WITH (NOLOCK)    
 --INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)    
 -- ON PSST.SegmentId = PCH.SegmentId AND PCH.SectionId = PSST.SectionId  
 --  AND ISNULL(PCH.IsDeleted, 0) = 0    
 --INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)    
 -- ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId AND PCHOP.SectionId = PCH.SectionId  
 --  AND ISNULL(PCHOP.IsDeleted, 0) = 0    
 --INNER JOIN #SelectedChoiceOptionTempProject PSCHOP WITH (NOLOCK)    
 -- ON PCHOP.SectionId = PSCHOP.SectionId    
 -- AND PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
 --  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode    
 --  --AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource    
 --  AND PSCHOP.SectionId = @PSectionId    
 --  AND PSCHOP.ProjectId = @PProjectId    
 --  --AND PSCHOP.ChoiceOptionSource = 'U'    
 --WHERE PCH.SectionId = @PSectionId  
 --AND PSST.ProjectId = @PProjectId    
 --AND PSST.SectionId = @PSectionId    
 --AND PSST.CustomerId = @PCustomerId    
 --AND ISNULL(PSST.IsDeleted, 0) = 0                             
                             
 --FETCH SEGMENT REQUIREMENT TAGS LIST                                
 SELECT                              
  PSRT.SegmentStatusId                              
    ,PSRT.SegmentRequirementTagId                              
    ,Temp.mSegmentStatusId                              
    ,LPRT.RequirementTagId                              
    ,LPRT.TagType                             
    ,LPRT.Description AS TagName                              
    ,CASE                              
   WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)                              
   ELSE CAST(1 AS BIT)                              
  END AS IsMasterRequirementTag                              
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                              
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)                              
  ON PSRT.RequirementTagId = LPRT.RequirementTagId                              
 INNER JOIN #ProjectSegmentStatus Temp WITH (NOLOCK)                              
  ON PSRT.SegmentStatusId = Temp.SegmentStatusId                              
 WHERE        
  PSRT.SectionId = @PSectionId        
 AND PSRT.ProjectId = @PProjectId        
  AND PSRT.CustomerId = @PCustomerId        
 AND ISNULL(PSRT.IsDeleted,0)=0    
END
GO
PRINT N'Altering [dbo].[usp_GetTagReports]...';


GO
ALTER PROCEDURE [dbo].[usp_GetTagReports]                    
(                  
@ProjectId INT,                    
@CustomerId INT,                   
@TagType INT,                   
@TagIdList NVARCHAR(MAX) NULL                  
)                    
AS                    
BEGIN          
DROP TABLE IF EXISTS #SegmentStatusIds          
DROP TABLE IF EXISTS #SectionsContainingTaggedSegments          
          
DECLARE @PProjectId INT = @ProjectId;          
DECLARE @PCustomerId INT = @CustomerId;          
DECLARE @PTagType INT = @TagType;          
DECLARE @PTagIdList NVARCHAR(MAX) = @TagIdList;          
          
--CONVERT STRING INTO TABLE                            
CREATE TABLE #TagIdTbl (          
 TagId INT          
);          
INSERT INTO #TagIdTbl (TagId)          
 SELECT          
  *          
 FROM dbo.fn_SplitString(@PTagIdList, ',');          
          
CREATE TABLE #SegmentStatusIds (          
 SegmentStatusId INT          
   ,TagId INT          
   ,TagName NVARCHAR(MAX)          
);          
          
INSERT INTO #SegmentStatusIds (SegmentStatusId, TagId, TagName)          
 (SELECT          
  PSRT.SegmentStatusId          
    ,TIT.TagId          
    ,LPRTI.Description AS TagName          
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)          
 INNER JOIN LuProjectRequirementTag LPRTI WITH (NOLOCK)          
  ON PSRT.RequirementTagId = LPRTI.RequirementTagId          
 INNER JOIN #TagIdTbl TIT          
  ON PSRT.RequirementTagId = TIT.TagId          
 WHERE PSRT.ProjectId = @PProjectId          
 --AND PSRT.RequirementTagId = @PTagId                  
 UNION ALL          
 SELECT          
  PSUT.SegmentStatusId          
    ,TIT.TagId          
    ,PUT.Description AS TagName          
 FROM ProjectSegmentUserTag PSUT WITH (NOLOCK)          
 INNER JOIN #TagIdTbl TIT          
  ON PSUT.UserTagId = TIT.TagId          
 INNER JOIN ProjectUserTag PUT  WITH (NOLOCK)        
  ON PUT.UserTagId = TIT.TagId          
 WHERE PSUT.ProjectId = @PProjectId          
 --AND PSUT.UserTagId = @PTagId                  
 )          
--END                  
          
--Inserts Sections Containing Tagged Segments                    
SELECT          
 PSS.SectionId          
   ,SI.TagId          
   ,SI.TagName          
   ,PSS.ProjectId          
   ,PSS.CustomerId INTO #SectionsContainingTaggedSegments          
FROM ProjectSegmentStatusView PSS WITH (NOLOCK)          
INNER JOIN #SegmentStatusIds SI          
 ON PSS.SegmentStatusId = SI.SegmentStatusId          
WHERE PSS.ProjectId = @PProjectId          
AND PSS.CustomerId = @PCustomerId          
AND PSS.IsDeleted = 0          
AND PSS.IsSegmentStatusActive <> 0          
          
--Select Sections with Tags                    
SELECT DISTINCT          
ISNULL(PS.SectionId,0)as SectionId
   ,ISNULL(PS.DivisionId,0)  as DivisionId       
   ,PS.DivisionCode          
   ,PS.[Description]          
   ,PS.SourceTag          
   ,PS.Author          
   ,ISNULL(PS.SectionCode,0) as SectionCode         
   ,ISNULL(SCTS.Tagid,0) as Tagid      
   ,SCTS.TagName          
FROM ProjectSection PS WITH (NOLOCK)          
JOIN #SectionsContainingTaggedSegments SCTS          
 ON PS.ProjectId = SCTS.ProjectId          
  AND PS.SectionId = SCTS.SectionId          
  AND PS.CustomerId = SCTS.CustomerId          
WHERE PS.ProjectId = @PProjectId          
AND PS.CustomerId = @PCustomerId          
ORDER BY SCTS.Tagname, PS.SourceTag;          
          
--Select Division For Sections who has tagged segments                    
SELECT DISTINCT          
 ISNULL(D.DivisionId,0) as Id         
   ,D.DivisionCode          
   ,D.DivisionTitle          
   ,D.SortOrder          
   ,D.IsActive          
   ,ISNULL(D.MasterDataTypeId,0) as MasterDataTypeId        
   ,ISNULL(D.FormatTypeId ,0) as  FormatTypeId 
   ,@PCustomerId as CustomerId
FROM SLCMaster..Division D WITH (NOLOCK)          
INNER JOIN ProjectSection PS WITH (NOLOCK)          
 ON PS.DivisionId = D.DivisionId          
JOIN #SectionsContainingTaggedSegments SCTS WITH (NOLOCK)          
 ON PS.ProjectId = SCTS.ProjectId          
  AND PS.SectionId = SCTS.SectionId          
  AND PS.CustomerId = SCTS.CustomerId          
WHERE PS.ProjectId = @PProjectId          
AND PS.CustomerId = @PCustomerId          
order by D.DivisionCode    
          
SELECT DISTINCT          
 COALESCE(TemplateId, 1) TemplateId INTO #TEMPLATE          
FROM Project WITH (NOLOCK)          
WHERE ProjectId = @PProjectID          
          
-- SELECT TEMPLATE STYLE DATA                    
SELECT          
 ST.StyleId          
   ,ST.Alignment          
   ,ST.IsBold          
   ,ST.CharAfterNumber          
   ,ST.CharBeforeNumber          
   ,ST.FontName          
   ,ST.FontSize          
   ,ST.HangingIndent          
   ,ST.IncludePrevious          
   ,ST.IsItalic          
   ,ST.LeftIndent          
   ,ST.NumberFormat          
   ,ST.NumberPosition          
   ,ST.PrintUpperCase          
   ,ST.ShowNumber          
   ,ST.StartAt          
   ,ST.Strikeout          
   ,ST.Name          
   ,ST.TopDistance          
   ,ST.Underline          
   ,ST.SpaceBelowParagraph          
   ,ST.IsSystem          
   ,ST.IsDeleted          
   ,TSY.Level     
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing  
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId  
   ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId  
   ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId     
   ,@PCustomerId as CustomerId
FROM Style ST WITH (NOLOCK)          
INNER JOIN TemplateStyle TSY WITH (NOLOCK)          
 ON ST.StyleId = TSY.StyleId          
INNER JOIN #TEMPLATE T          
 ON TSY.TemplateId = T.TemplateId  
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) 
 ON SPS.StyleId=ST.StyleId;
          
-- GET SourceTagFormat                     
SELECT          
 SourceTagFormat          
FROM ProjectSummary WITH (NOLOCK)          
WHERE ProjectId = @PProjectId;          
          
END
GO
PRINT N'Altering [dbo].[usp_GetTagsReportDataOfHeaderFooter]...';


GO
ALTER PROCEDURE [dbo].[usp_GetTagsReportDataOfHeaderFooter]           
(          
@ProjectId INT,          
@CustomerId INT,          
@CatalogueType NVARCHAR(MAX)='FS',          
@TCPrintModeId INT = 1  
)              
AS              
BEGIN  
    
    
DECLARE @PProjectId INT = @ProjectId;  
    
DECLARE @PCustomerId INT = @CustomerId;  
    
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;  
    
    
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';  
    
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';  

 DECLARE @ImagSegment int =1
 DECLARE @ImageHeaderFooter int =3
    
    
DECLARE @MasterDataTypeId INT = ( SELECT  
  P.MasterDataTypeId  
 FROM Project P with(NOLOCK)  
 WHERE P.ProjectId = @PProjectId  
 AND P.CustomerId = @PCustomerId);  
  
  
--SELECT GLOBAL TERM DATA               
SELECT
@PProjectId AS ProjectId 
,@PCustomerId as CustomerId 
 ,PGT.GlobalTermId  
   ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId  
   ,PGT.Name  
   ,ISNULL(PGT.value, '') AS value  
   ,PGT.CreatedDate  
   ,PGT.CreatedBy  
   ,PGT.ModifiedDate  
   ,PGT.ModifiedBy  
   ,PGT.GlobalTermSource  
   ,PGT.GlobalTermCode  
   ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId  
   ,GlobalTermFieldTypeId as GTFieldType  
FROM ProjectGlobalTerm PGT WITH (NOLOCK)  
WHERE PGT.ProjectId = @PProjectId  
AND PGT.CustomerId = @PCustomerId;  

--SELECT Image DATA
SELECT     
  PIMG.SegmentImageId    
 ,IMG.ImageId    
 ,IMG.ImagePath    
 ,COALESCE(PIMG.ImageStyle,'') as ImageStyle   
 ,PIMG.SectionId     
 ,ISNULL(IMG.LuImageSourceTypeId ,0) AS LuImageSourceTypeId   
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)          
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId          
 WHERE PIMG.ProjectId = @PProjectId          
  AND PIMG.CustomerId = @PCustomerId          
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter) 
  
  
--SELECT Project Summary information          
SELECT  
 P.ProjectId AS ProjectId  
   ,P.Name AS ProjectName  
   ,'' AS ProjectLocation  
   ,PS.IsPrintReferenceEditionDate AS IsPrintReferenceEditionDate  
   ,PS.SourceTagFormat AS SourceTagFormat  
   ,CONCAT(LState.StateProvinceAbbreviation, ', ', LCity.City) AS DbInfoProjectLocationKeyword  
   ,ISNULL(PGT.value, '') AS ProjectLocationKeyword  
   ,PS.UnitOfMeasureValueTypeId  
FROM Project P with(NOLOCK)  
INNER JOIN ProjectSummary PS WITH (NOLOCK)  
 ON P.ProjectId = PS.ProjectId  
INNER JOIN ProjectAddress PA WITH (NOLOCK)  
 ON P.ProjectId = PA.ProjectId  
INNER JOIN LuCountry LCountry WITH (NOLOCK)  
 ON PA.CountryId = LCountry.CountryId  
INNER JOIN LuStateProvince LState WITH (NOLOCK)  
 ON PA.StateProvinceId = LState.StateProvinceID  
  AND PA.CountryId = LState.CountryId  
INNER JOIN LuCity LCity WITH (NOLOCK)  
 ON PA.CityId = LCity.CityId  
  AND PA.StateProvinceId = LCity.StateProvinceID  
LEFT JOIN ProjectGlobalTerm PGT WITH (NOLOCK)  
 ON P.ProjectId = PGT.ProjectId  
  AND PGT.mGlobalTermId = 11  
WHERE P.ProjectId = @PProjectId  
AND P.CustomerId = @PCustomerId  
  
--SELECT Header/Footer information                    
IF EXISTS (SELECT  
  TOP 1  
   1  
  FROM Header with(NOLOCK)  
  WHERE ProjectId = @PProjectId  
  AND CustomerId = @PCustomerId  
  AND DocumentTypeId = 2)  
BEGIN  
SELECT  
 H.HeaderId  
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(H.SectionId, 0) AS SectionId  
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(H.TypeId, 1) AS TypeId  
   ,H.DateFormat  
   ,H.TimeFormat  
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader  
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader  
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader  
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader  
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId 
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H with(NOLOCK)  
WHERE H.ProjectId = @PProjectId  
AND H.CustomerId = @PCustomerId  
AND H.DocumentTypeId = 2  
END  
ELSE  
BEGIN  
SELECT  
 H.HeaderId  
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(H.SectionId, 0) AS SectionId  
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(H.TypeId, 1) AS TypeId  
   ,H.DateFormat  
   ,H.TimeFormat  
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader  
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader  
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader  
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader  
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId  
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader
   ,H.IsShowLineBelowHeader AS IsShowLineBelowHeader
FROM Header H with(NOLOCK)  
WHERE H.ProjectId IS NULL  
AND H.CustomerId IS NULL  
AND H.SectionId IS NULL  
AND H.DocumentTypeId = 2  
END  
IF EXISTS (SELECT  
  TOP 1  
   1  
  FROM Footer with(NOLOCK)  
  WHERE ProjectId = @PProjectId  
  AND CustomerId = @PCustomerId  
  AND DocumentTypeId = 2)  
BEGIN  
SELECT  
 F.FooterId  
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(F.SectionId, 0) AS SectionId  
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(F.TypeId, 1) AS TypeId  
   ,F.DateFormat  
   ,F.TimeFormat  
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter  
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter  
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter  
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter  
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId  
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter
  
FROM Footer F WITH (NOLOCK)  
WHERE F.ProjectId = @PProjectId  
AND F.CustomerId = @PCustomerId  
AND F.DocumentTypeId = 2  
END  
ELSE  
BEGIN  
SELECT  
 F.FooterId  
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId  
   ,ISNULL(F.SectionId, 0) AS SectionId  
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId  
   ,ISNULL(F.TypeId, 1) AS TypeId  
   ,F.DateFormat  
   ,F.TimeFormat  
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId  
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter  
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter  
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter  
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter  
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId  
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter
   ,F.IsShowLineBelowFooter AS IsShowLineBelowFooter
FROM Footer F WITH(NOLOCK)  
WHERE F.ProjectId IS NULL  
AND F.CustomerId IS NULL  
AND F.SectionId IS NULL  
AND F.DocumentTypeId = 2  
END  
--SELECT PageSetup INFORMATION                
SELECT  
 PageSetting.ProjectPageSettingId AS ProjectPageSettingId  
   ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId  
   ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop  
   ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom  
   ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft  
   ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight  
   ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader  
   ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter  
   ,PageSetting.IsMirrorMargin AS IsMirrorMargin  
   ,PageSetting.ProjectId AS ProjectId  
   ,PageSetting.CustomerId AS CustomerId  
   ,COALESCE(PaperSetting.PaperName,'A4') AS PaperName  
   ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth  
   ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight  
   ,COALESCE(PaperSetting.PaperOrientation,'') AS PaperOrientation  
   ,COALESCE(PaperSetting.PaperSource,'') AS PaperSource  
FROM ProjectPageSetting PageSetting WITH (NOLOCK)  
INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK)  
 ON PageSetting.ProjectId = PaperSetting.ProjectId  
WHERE PageSetting.ProjectId = @PProjectId  
END
GO
PRINT N'Altering [dbo].[usp_getTOCReport]...';


GO
ALTER Procedure usp_getTOCReport
(                  
@ProjectId INT,                        
@CustomerId INT,            
@CatalogueType NVARCHAR(MAX)         
)
AS
BEGIN              
            
DECLARE @PProjectId INT = @ProjectId;            
DECLARE @PCustomerId INT = @CustomerId;            
DECLARE @OldKeywordFormat NVARCHAR(MAX) = '{\kw\';              
DECLARE @NewKeywordFormat NVARCHAR(MAX) = '{KW#';              
DECLARE @PCatalogueType NVARCHAR(MAX) =@CatalogueType;          
DECLARE @PCatalogueTypelIST NVARCHAR(MAX) ;   
 DECLARE @ImagSegment int =1  
 DECLARE @ImageHeaderFooter int =3  
  
DECLARE @CatalogueTypeTbl TABLE (                
 TagType NVARCHAR(MAX)                
);            
            
  SELECT @PCatalogueTypelIST=          
(CASE          
    WHEN @PCatalogueType ='OL' THEN '2'          
 WHEN @PCatalogueType ='SF' THEN '1,2'          
    ELSE '1,2,3'           
END);          
          
--CONVERT CATALOGUE TYPE INTO TABLE                
IF @PCatalogueType IS NOT NULL                
 AND @PCatalogueType != 'FS'                
BEGIN                  
INSERT INTO @CatalogueTypeTbl (TagType)                
 SELECT                
  *                
 FROM dbo.fn_SplitString(@PCatalogueTypelIST, ',');             
 END          
  
--SELECT SEGMENT MASTER TAGS DATA                     
SELECT            
 PSRT.SegmentStatusId            
   ,PSRT.SegmentRequirementTagId            
   ,PSST.mSegmentStatusId            
   ,LPRT.RequirementTagId            
   ,LPRT.TagType            
   ,LPRT.Description AS TagName            
   ,CASE            
  WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)            
  ELSE CAST(1 AS BIT)            
 END AS IsMasterRequirementTag            
   ,PSST.SectionId INTO #MasterTagList            
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)            
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)            
 ON PSRT.RequirementTagId = LPRT.RequirementTagId            
INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK)            
 ON PSRT.SegmentStatusId = PSST.SegmentStatusId            
WHERE PSRT.ProjectId = @PProjectId            
AND PSRT.CustomerId = @PCustomerId            
AND PSST.ParentSegmentStatusId=0             
AND LPRT.RequirementTagId IN (2,3)--NS,NP            
            
			
--SELECT Active Section DATA                     
SELECT * INTO #ActiveSectionList            
 FROM(            
SELECT            
PSST.SegmentStatusId            
,PS.SourceTag            
,PS.Author            
,PS.SectionId            
,PS.mSectionId            
,PS.DivisionId            
,PS.Description            
,PSST.SpecTypeTagId   
,PS.ParentSectionId       
FROM ProjectSection PS WITH(NOLOCK)            
INNER JOIN ProjectSegmentStatus PSST WITH(NOLOCK)            
ON PS.SectionId = PSST.SectionId            
WHERE PS.ProjectId = @PProjectId            
AND PS.CustomerId = @PCustomerId            
AND PS.IsDeleted = 0            
AND PSST.SequenceNumber = 0            
AND PSST.IndentLevel = 0            
AND PSST.ParentSegmentStatusId = 0            
AND (PSST.IsParentSegmentStatusActive = 1 AND PSST.SegmentStatusTypeId<6)            
AND (@PCatalogueType = 'FS'                
OR PSST.SpecTypeTagId IN (SELECT * FROM @CatalogueTypeTbl))          
) AS T            
    
	  
--TOC List            
SELECT T.SegmentStatusId,T.SourceTag,T.Author,T.SectionId,ISNULL(T.mSectionId,0) as mSectionId ,ISNULL(DivisionId,0) AS DivisionId,Description,SpecTypeTagId,T.ParentSectionId INTO #TOCSectionList FROM #MasterTagList M WITH(NOLOCK)            
FULL OUTER JOIN  #ActiveSectionList T WITH(NOLOCK)            
ON T.SegmentStatusId=M.SegmentStatusId            
WHERE M.SegmentStatusId IS NULL            
ORDER BY T.SegmentStatusId            
            
----Added for to delete parent delete section CSI ticket 35671
DELETE P FROM #TOCSectionList P WITH (NOLOCK)
INNER JOIN ProjectSection PS WITH (NOLOCK)
ON PS.SectionId = P.ParentSectionId
where ISNULL(PS.IsDeleted,0)=1


SELECT * FROM #TOCSectionList WITH(NOLOCK)   ORDER BY sourcetag     

--Select Division For Sections who has tagged segments                        
SELECT DISTINCT              
 ISNULL(D.DivisionId,0)  as Id
 ,D.DivisionCode              
   ,D.DivisionTitle              
   ,D.SortOrder              
   ,D.IsActive              
   , ISNULL(D.MasterDataTypeId,0) MasterDataTypeId              
   ,ISNULL(D.FormatTypeId,0) FormatTypeId
FROM SLCMaster..Division D WITH (NOLOCK)              
INNER JOIN ProjectSection PS WITH (NOLOCK)              
 ON PS.DivisionId = D.DivisionId              
JOIN #TOCSectionList SCTS WITH (NOLOCK)              
  ON PS.SectionId = SCTS.SectionId              
WHERE PS.ProjectId = @PProjectId              
AND PS.CustomerId = @PCustomerId              
ORDER BY D.DivisionCode 
           
SELECT DISTINCT              
 TemplateId INTO #TEMPLATE              
FROM Project WITH (NOLOCK)              
WHERE ProjectId = @PProjectID              
              
-- SELECT TEMPLATE STYLE DATA                        
SELECT              
 ST.StyleId              
   ,ST.Alignment              
   ,ST.IsBold              
   ,ST.CharAfterNumber              
   ,ST.CharBeforeNumber              
   ,ST.FontName              
   ,ST.FontSize              
   ,ST.HangingIndent              
   ,ST.IncludePrevious              
   ,ST.IsItalic              
   ,ST.LeftIndent              
   ,ST.NumberFormat              
   ,ST.NumberPosition              
   ,ST.PrintUpperCase              
   ,ST.ShowNumber              
   ,ST.StartAt              
   ,ST.Strikeout              
   ,ST.Name              
   ,ST.TopDistance              
   ,ST.Underline              
   ,ST.SpaceBelowParagraph 
   ,@PCustomerId as CustomerId            
   ,ST.IsSystem              
   ,ST.IsDeleted              
   --,TSY.Level            
   ,CAST(TSY.Level as INT) as Level       
   ,ISNULL(SPS.CustomLineSpacing,0) as CustomLineSpacing  
   ,ISNULL(SPS.DefaultSpacesId,0) as  DefaultSpacesId
   ,ISNULL(SPS.BeforeSpacesId,0) as   BeforeSpacesId
   ,ISNULL(SPS.AfterSpacesId,0) as AfterSpacesId
FROM Style ST WITH (NOLOCK)            
INNER JOIN TemplateStyle TSY WITH (NOLOCK)              
 ON ST.StyleId = TSY.StyleId              
INNER JOIN #TEMPLATE T              
 ON TSY.TemplateId = COALESCE(T.TemplateId, 1)        
LEFT JOIN StyleParagraphLineSpace SPS WITH(NOLOCK) ON SPS.StyleId=ST.StyleId       
  
-- GET SourceTagFormat                         
SELECT              
 SourceTagFormat              
FROM ProjectSummary WITH (NOLOCK)              
WHERE ProjectId = @PProjectId;              
              
--SELECT Header/Footer information                              
IF EXISTS (SELECT              
   TOP 1 1            
  FROM Header WITH (NOLOCK)            
  WHERE ProjectId = @PProjectId              
  AND CustomerId = @PCustomerId              
  AND DocumentTypeId = 3)              
BEGIN              
SELECT              
 H.HeaderId              
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId              
   ,ISNULL(H.SectionId, 0) AS SectionId              
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId              
   ,ISNULL(H.TypeId, 1) AS TypeId              
   ,H.DateFormat              
   ,H.TimeFormat              
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId              
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader              
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader              
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader              
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader              
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId              
   ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader  
   ,H.IsShowLineBelowHeader AS   IsShowLineBelowHeader         
FROM Header H  WITH (NOLOCK)            
WHERE H.ProjectId = @PProjectId              
AND H.CustomerId = @PCustomerId              
AND H.DocumentTypeId = 3             
END              
ELSE              
BEGIN              
SELECT              
 H.HeaderId              
   ,ISNULL(H.ProjectId, @PProjectId) AS ProjectId              
   ,ISNULL(H.SectionId, 0) AS SectionId              
   ,ISNULL(H.CustomerId, @PCustomerId) AS CustomerId              
   ,ISNULL(H.TypeId, 1) AS TypeId              
   ,H.DateFormat              
   ,H.TimeFormat              
   ,ISNULL(H.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId              
   ,REPLACE(ISNULL(H.DefaultHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultHeader              
   ,REPLACE(ISNULL(H.FirstPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageHeader              
   ,REPLACE(ISNULL(H.OddPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageHeader              
   ,REPLACE(ISNULL(H.EvenPageHeader, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageHeader              
   ,H.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId              
    ,H.IsShowLineAboveHeader AS IsShowLineAboveHeader  
   ,H.IsShowLineBelowHeader AS   IsShowLineBelowHeader   
FROM Header H  WITH (NOLOCK)            
WHERE H.ProjectId IS NULL              
AND H.CustomerId IS NULL              
AND H.SectionId IS NULL              
AND H.DocumentTypeId = 3              
END              
IF EXISTS (SELECT              
   TOP 1 1              
  FROM Footer WITH (NOLOCK)             
  WHERE ProjectId = @PProjectId              
  AND CustomerId = @PCustomerId              
  AND DocumentTypeId = 3)              
BEGIN              
SELECT              
 F.FooterId              
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId              
   ,ISNULL(F.SectionId, 0) AS SectionId              
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId              
   ,ISNULL(F.TypeId, 1) AS TypeId              
   ,F.DateFormat              
   ,F.TimeFormat              
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId              
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter              
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter              
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter              
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter              
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId              
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter  
   ,F.IsShowLineBelowFooter AS   IsShowLineBelowFooter         
              
FROM Footer F WITH (NOLOCK)              
WHERE F.ProjectId = @PProjectId              
AND F.CustomerId = @PCustomerId              
AND F.DocumentTypeId = 3              
END              
ELSE              
BEGIN              
SELECT              
 F.FooterId              
   ,ISNULL(F.ProjectId, @PProjectId) AS ProjectId              
   ,ISNULL(F.SectionId, 0) AS SectionId              
   ,ISNULL(F.CustomerId, @PCustomerId) AS CustomerId              
   ,ISNULL(F.TypeId, 1) AS TypeId              
   ,F.DateFormat              
   ,F.TimeFormat              
   ,ISNULL(F.HeaderFooterCategoryId, 1) AS HeaderFooterCategoryId              
   ,REPLACE(ISNULL(F.DefaultFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS DefaultFooter              
   ,REPLACE(ISNULL(F.FirstPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS FirstPageFooter              
   ,REPLACE(ISNULL(F.OddPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS OddPageFooter              
   ,REPLACE(ISNULL(F.EvenPageFooter, ''), @OldKeywordFormat, @NewKeywordFormat) AS EvenPageFooter              
   ,F.HeaderFooterDisplayTypeId AS HeaderFooterDisplayTypeId              
   ,F.IsShowLineAboveFooter AS IsShowLineAboveFooter  
   ,F.IsShowLineBelowFooter AS   IsShowLineBelowFooter         
                      
FROM Footer F  WITH (NOLOCK)            
WHERE F.ProjectId IS NULL              
AND F.CustomerId IS NULL              
AND F.SectionId IS NULL              
AND F.DocumentTypeId = 3              
END              
--SELECT PageSetup INFORMATION                          
SELECT              
 PageSetting.ProjectPageSettingId AS ProjectPageSettingId              
   ,PaperSetting.ProjectPaperSettingId AS ProjectPaperSettingId              
   ,ISNULL(PageSetting.MarginTop, 1.00) AS MarginTop              
   ,ISNULL(PageSetting.MarginBottom, 1.00) AS MarginBottom              
   ,ISNULL(PageSetting.MarginLeft, 1.00) AS MarginLeft              
   ,ISNULL(PageSetting.MarginRight, 1.00) AS MarginRight              
   ,ISNULL(PageSetting.EdgeHeader, 0.05) AS EdgeHeader              
   ,ISNULL(PageSetting.EdgeFooter, 0.05) AS EdgeFooter              
   ,PageSetting.IsMirrorMargin AS IsMirrorMargin              
   ,PageSetting.ProjectId AS ProjectId              
   ,PageSetting.CustomerId AS CustomerId              
   ,COALESCE(PaperSetting.PaperName,'A4') AS PaperName              
   ,ISNULL(PaperSetting.PaperWidth, 0.00) AS PaperWidth              
   ,ISNULL(PaperSetting.PaperHeight, 0.00) AS PaperHeight              
   ,COALESCE(PaperSetting.PaperOrientation,'') AS PaperOrientation              
   ,COALESCE(PaperSetting.PaperSource,'') AS PaperSource              
FROM ProjectPageSetting PageSetting WITH (NOLOCK)              
INNER JOIN ProjectPaperSetting PaperSetting WITH (NOLOCK)              
 ON PageSetting.ProjectId = PaperSetting.ProjectId              
WHERE PageSetting.ProjectId = @PProjectId     
            
--SELECT GLOBAL TERM DATA                      
SELECT  
@PProjectId  as  ProjectId
,@PCustomerId   as  CustomerId          
, PGT.GlobalTermId                  
   ,COALESCE(PGT.mGlobalTermId, 0) AS mGlobalTermId                  
   ,PGT.Name                  
   ,ISNULL(PGT.value, '') AS value                  
   ,PGT.CreatedDate                  
   ,PGT.CreatedBy                  
   ,PGT.ModifiedDate                  
   ,PGT.ModifiedBy                  
   ,PGT.GlobalTermSource                  
   ,isnull(PGT.GlobalTermCode ,0) as  GlobalTermCode              
   ,COALESCE(PGT.UserGlobalTermId, 0) AS UserGlobalTermId                  
   ,GlobalTermFieldTypeId  as GTFieldType                 
FROM ProjectGlobalTerm PGT WITH (NOLOCK)                  
WHERE PGT.ProjectId = @PProjectId                  
AND PGT.CustomerId = @PCustomerId;         
  
--SELECT IMAGES DATA       
 SELECT         
  PIMG.SegmentImageId        
 ,IMG.ImageId        
 ,IMG.ImagePath        
 ,COALESCE(PIMG.ImageStyle,'')  as ImageStyle      
 ,PIMG.SectionId         
 ,isnull(IMG.LuImageSourceTypeId ,0) as LuImageSourceTypeId        
 FROM ProjectSegmentImage PIMG WITH (NOLOCK)              
 INNER JOIN ProjectImage IMG WITH (NOLOCK) ON PIMG.ImageId = IMG.ImageId                        
 WHERE PIMG.ProjectId = @PProjectId              
  AND PIMG.CustomerId = @PCustomerId              
  AND IMG.LuImageSourceTypeId IN(@ImagSegment,@ImageHeaderFooter)     
END
GO
PRINT N'Altering [dbo].[usp_GetSubmittalsReport]...';


GO
ALTER PROCEDURE [dbo].[usp_GetSubmittalsReport]           
 @ProjectId INT,                  
 @CustomerID INT                
AS                  
BEGIN  
    
          
              
 DECLARE @PProjectId INT = @ProjectId;  
    
          
 DECLARE @PCustomerID INT = @CustomerID;  
    
          
 DECLARE @ActiveSectionCount INT=0;  
  
--Set @ActiveSectionCount              
SET @ActiveSectionCount = (SELECT  
  COUNT(PS.SectionId) AS OpenSectionCount  
 FROM ProjectSection PS WITH (NOLOCK)  
 INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK)  
  ON PS.ProjectId = PSS.ProjectId  
  AND PS.CustomerId = PSS.CustomerId  
  AND PS.SectionId = PSS.SectionId  
 WHERE PSS.IndentLevel = 0  
 AND PS.ProjectId = @PProjectId  
 AND PS.CustomerId = @PCustomerID  
 AND PS.IsLastLevel = 1  
 AND PSS.SequenceNumber = 0  
 AND PS.IsDeleted = 0  
 AND PSS.SegmentStatusTypeId < 6  
 GROUP BY PS.ProjectId);  
  
  
--Select Active Sections into #SegmentWithTags              
SELECT  
 PSRT.SectionId  
   ,LPRT.TagType  
   ,PS.SourceTagFormat INTO #SegmentWithTags  
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)  
 ON LPRT.RequirementTagId = PSRT.RequirementTagId  
INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK)  
 ON PSS.SegmentStatusId = PSRT.SegmentStatusId  
INNER JOIN [ProjectSummary] PS WITH (NOLOCK)  
 ON PS.ProjectId = PSRT.ProjectId  
  AND PSS.SegmentStatusTypeId < 6  
  AND PSS.IsParentSegmentStatusActive = 1  
  
WHERE PSRT.ProjectId = @PProjectId  
AND PSRT.CustomerId = @PCustomerId  
AND PSRT.RequirementTagId IN (17, 26, 27)  
  
--Sections with filtered tags              
SELECT  
 SectionId  
   ,  
 --Row Values into Column                  
 CASE  
  WHEN [PD] = 0 THEN 'N'  
  ELSE 'Y'  
 END AS IsProductData  
   ,CASE  
  WHEN [SD] = 0 THEN 'N'  
  ELSE 'Y'  
 END AS IsShopDrawings  
   ,CASE  
  WHEN [SA] = 0 THEN 'N'  
  ELSE 'Y'  
 END AS IsSamples  
   ,SourceTagFormat INTO #SectionWithTags  
FROM #SegmentWithTags  
PIVOT  
(  
COUNT(TagType)  
FOR TagType IN ([PD], [SD], [SA])  
) AS SWT  
  
--Selects final Result with section and tags info              
SELECT  
 PS.SectionId  
   ,PS.[Description]  
   ,PS.[Description] as SectionName
   ,PS.DivisionId  
   ,PS.ParentSectionId  
   ,PS.DivisionCode  
   ,'DIVISION ' + UPPER(D.DivisionCode) + ' - ' + UPPER(D.DivisionTitle) AS DivisionTitle  
   ,PS.SourceTag  
   ,SWT.IsProductData  
   ,SWT.IsShopDrawings  
   ,SWT.IsSamples  
   ,SWT.SourceTagFormat  
FROM #SectionWithTags SWT WITH (NOLOCK)  
INNER JOIN ProjectSection PS WITH (NOLOCK)  
 ON PS.SectionId = SWT.SectionId  
INNER JOIN SLCMaster..Division D WITH (NOLOCK)  
 ON D.DivisionId = PS.DivisionId  
WHERE PS.ProjectId = @PProjectId  
AND PS.CustomerId = @PCustomerId  
ORDER BY PS.DivisionCode ASC, PS.SourceTag ASC  
  
END
GO
--PRINT N'Altering [dbo].[sp_UnArchiveMigratedCycles_ArchServer01]...';


--GO



--ALTER PROCEDURE [dbo].[sp_UnArchiveMigratedCycles_ArchServer01]
--(
--	@PSLC_CustomerId		INT
--	,@PSLC_UserId			INT
--	,@PProjectID			INT
--	,@POldSLC_ProjectID		INT
--	,@PArchive_ServerId		INT
--)
--AS
--BEGIN
--	DECLARE @ErrorCode INT = 0
--	DECLARE @Return_Message VARCHAR(1024)
--	DECLARE @ErrorStep VARCHAR(50)
--	DECLARE @NumberRecords int, @RowCount int
--	DECLARE @RequestId AS INT

--	--Handled Parameter Sniffing here
--	DECLARE @SLC_CustomerId INT
--	SET @SLC_CustomerId = @PSLC_CustomerId
--	DECLARE @SLC_UserId INT
--	SET @SLC_UserId = @PSLC_UserId
--	DECLARE @ProjectID INT
--	SET @ProjectID = @PProjectID
--	DECLARE @OldSLC_ProjectID INT
--	SET @OldSLC_ProjectID = @POldSLC_ProjectID
--	DECLARE @Archive_ServerId INT
--	SET @Archive_ServerId = @PArchive_ServerId

--	--IF OBJECT_ID('tempdb..#tmpUnArchiveCycleIDs') IS NOT NULL DROP TABLE #tmpUnArchiveCycleIDs
--	--CREATE TABLE #tmpUnArchiveCycleIDs
--	--(
--	--	RowID					INT IDENTITY(1, 1), 
--	--	CycleID					BIGINT NULL,
--	--	CustomerID				INT NOT NULL,
--	--	SubscriptionID			INT NULL, 
--	--	ProjectID				INT NOT NULL,
--	--	SLC_CustomerId			INT NOT NULL,
--	--	SLC_UserId				INT NOT NULL,
--	--	SLC_ArchiveProjectId	INT NOT NULL,
--	--	SLC_ProdProjectId		INT NULL,
--	--	SLC_ServerId			INT NULL,
--	--	MigrateStatus			INT NULL,
--	--	CreatedDate				DATETIME NULL,
--	--	MovedDate				DATETIME NULL,
--	--	MigratedDate			DATETIME NULL,
--	--	IsProcessed				BIT NULL DEFAULT((0))
--	--)
	
--	DECLARE @IsProjectMigrationFailed AS INT = 0
--	DECLARE @IsRestoreDeleteFailed AS INT = 0

--	--Drop all Temp Tables
--	DROP TABLE IF EXISTS #NewOldSectionIdMapping;
--	DROP TABLE IF EXISTS #NewOldSegmentStatusIdMapping;
--	DROP TABLE IF EXISTS #TGTProImg;
--	DROP TABLE IF EXISTS #tmp_TgtSection;
--	DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;
--	DROP TABLE IF EXISTS #tmpProjectGlobalTerm;
--	DROP TABLE IF EXISTS #tmpProjectHyperLink;
--	DROP TABLE IF EXISTS #tmpProjectImage;
--	DROP TABLE IF EXISTS #tmpProjectNote;
--	DROP TABLE IF EXISTS #tmpProjectNoteImage;
--	DROP TABLE IF EXISTS #tmpProjectSection;
--	DROP TABLE IF EXISTS #ProjectSegment_Staging;
--	DROP TABLE IF EXISTS #tmpProjectSegment;
--	DROP TABLE IF EXISTS #tmpProjectSegmentChoice;
--	DROP TABLE IF EXISTS #tmpProjectSegmentImage;
--	DROP TABLE IF EXISTS #tmpProjectSegmentStatus;
--	DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;
--	DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;
--	DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;
--	DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;
--	DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;
--	DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;
--	DROP TABLE IF EXISTS #ProjectHyperLink_Staging;
--	DROP TABLE IF EXISTS #ProjectNote_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;
--	DROP TABLE IF EXISTS #ProjectNoteImage_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;
--	DROP TABLE IF EXISTS #MaterialSection_Staging;
--	DROP TABLE IF EXISTS #LinkedSections_Staging;

--	DECLARE @Records INT = 1; 
--	DECLARE @TableRows INT;
--	DECLARE @Section_BatchSize INT;
--	DECLARE @Segment_BatchSize INT;
--	DECLARE @SegmentStatus_BatchSize INT;
--	DECLARE @ProjectSegmentChoice_BatchSize INT;
--	DECLARE @ProjectChoiceOption_BatchSize INT;
--	DECLARE @SelectedChoiceOption_BatchSize INT;
--	DECLARE @ProjectHyperLink_BatchSize INT;
--	DECLARE @ProjectNote_BatchSize INT;
--	DECLARE @ProjectSegmentLink_BatchSize INT;
--	DECLARE @Start INT = 1;
--	DECLARE @End INT;
--	DECLARE @StartTime AS DATETIME = GETUTCDATE()
--	DECLARE @EndTime AS DATETIME = GETUTCDATE()

--	--INSERT INTO #tmpUnArchiveCycleIDs (CycleID, CustomerID, SubscriptionID, ProjectID, SLC_CustomerId, SLC_UserId, SLC_ArchiveProjectId, SLC_ProdProjectId, SLC_ServerId, MigrateStatus, MigratedDate, IsProcessed)
--	--SELECT AP.CycleID, AP.LegacyCustomerID, AP.LegacySubscriptionID, AP.LegacyProjectID, AP.SLC_CustomerId, AP.SLC_UserId, AP.SLC_ArchiveProjectId, AP.SLC_ProdProjectId, AP.SLC_ServerId, AP.MigrateStatus, AP.MigratedDate, 0 AS IsProcessed
--	--FROM [ARCHIVESERVER02].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH (NOLOCK)
--	----INNER JOIN [SQLADMINOP].[Authentication].[dbo].[CustomerTenantDbServer] CS ON CS.CustomerId = AP.SLC_CustomerId 
--	--	--AND AP.TenantDbServerId IN (SELECT TenantDbServerId FROM [SQLADMINOP].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))
--	--WHERE AP.InProgressStatusId = 3 --UnArchiveInitiated
--	--	AND AP.ProcessInitiatedById IN (1,2) --SLE or SLEWeb
--	--	AND AP.MigrateStatus = 1 AND AP.DisplayTabId = 1 --MigratedTab
--	--	AND AP.IsArchived = 1
--	--	--AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SQLADMINOP].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))

--	---- Get the number of records in the temporary table
--	--SET @NumberRecords = @@ROWCOUNT
--	--SET @RowCount = 1

--	---- loop through all records in the temporary table using the WHILE loop construct
--	--WHILE @RowCount <= @NumberRecords
--	--BEGIN
--	--	--Set IsProjectMigrationFailed to 0 to reset it
--	--	SET @IsProjectMigrationFailed = 0

--	--	DECLARE @CustomerID INT, @SubscriptionID INT, @SLE_ProjectID INT, @MigrateStatus INT, @MigratedDate DATETIME, @SLC_CustomerId INT, @SLC_UserId INT, @ProjectID INT, @IsProcessed INT, @CycleID BIGINT
--	--		, @SLC_ServerId INT, @OldSLC_ProjectID INT
--	--	--Get next CycleID
--	--	SELECT @CustomerID = CustomerID, @SubscriptionID = SubscriptionID, @SLE_ProjectID = ProjectID, @SLC_CustomerId = SLC_CustomerId, @SLC_UserId = SLC_UserId, @CycleID = CycleID
--	--		,@MigrateStatus = MigrateStatus, @ProjectID = SLC_ArchiveProjectId, @OldSLC_ProjectID = ISNULL(SLC_ProdProjectId, 0), @SLC_ServerId = SLC_ServerId, @MigratedDate = MigratedDate, @IsProcessed = IsProcessed
--	--	FROM #tmpUnArchiveCycleIDs WHERE RowID = @RowCount AND IsProcessed = 0


--	BEGIN TRY

--		IF(EXISTS(SELECT TOP 1 1 FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK) WHERE Servername=@@servername))
--		BEGIN
--			SELECT TOP 1 @Section_BatchSize=ProjectSection,
--				@SegmentStatus_BatchSize=ProjectSegmentStatus,
--				@Segment_BatchSize =ProjectSegment,
--				@ProjectSegmentChoice_BatchSize =ProjectSegmentChoice,
--				@ProjectChoiceOption_BatchSize =ProjectChoiceOption,
--				@SelectedChoiceOption_BatchSize =SelectedChoiceOption,
--				@ProjectSegmentLink_BatchSize =ProjectSegmentLink,
--				@ProjectHyperLink_BatchSize =ProjectHyperLink,
--				@ProjectNote_BatchSize =ProjectNote
--				FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK)
--				WHERE Servername=@@servername
--		END
--		ELSE
--		BEGIN
--			SELECT TOP 1 @Section_BatchSize=ProjectSection,
--				@SegmentStatus_BatchSize=ProjectSegmentStatus,
--				@Segment_BatchSize =ProjectSegment,
--				@ProjectSegmentChoice_BatchSize =ProjectSegmentChoice,
--				@ProjectChoiceOption_BatchSize =ProjectChoiceOption,
--				@SelectedChoiceOption_BatchSize =SelectedChoiceOption,
--				@ProjectSegmentLink_BatchSize =ProjectSegmentLink,
--				@ProjectHyperLink_BatchSize =ProjectHyperLink,
--				@ProjectNote_BatchSize =ProjectNote
--				FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK)
--				WHERE Servername IS NULL
--		END

--		--UnArchive Project Data

			
--		SET @RequestId = 0

--		DECLARE @New_ProjectID AS INT, @IsOfficeMaster AS INT, @ProjectAccessTypeId AS INT, @ProjectOwnerId AS INT

--		DECLARE @OldCount AS INT = 0, @NewCount AS INT = 0, @StepName AS NVARCHAR(100), @Description AS NVARCHAR(500), @Step AS NVARCHAR(100)

--		--Update previousely migrated projects A_ProjectId to NULL so it wont duplicate the records in other child tables.
--		UPDATE P SET P.A_ProjectId = NULL
--		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		WHERE A_ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId;

--		--Move Project table
--		--Insert
--		INSERT INTO [SLCProject].[dbo].[Project]
--		([Name], IsOfficeMaster, [Description], TemplateId, MasterDataTypeId, UserId, CustomerId, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsDeleted, IsNamewithHeld
--			,IsMigrated, IsLocked, A_ProjectId, IsProjectMoved, [GlobalProjectID], [IsPermanentDeleted], [ModifiedByFullName], [MigratedDate], [IsArchived], [IsShowMigrationPopup])
--		SELECT
--			S.[Name], S.IsOfficeMaster, S.[Description], S.TemplateId, S.MasterDataTypeId, S.UserId, S.CustomerId, S.CreateDate, S.CreatedBy
--			,S.ModifiedBy, S.ModifiedDate, S.IsDeleted, S.IsNamewithHeld, S.IsMigrated, S.IsLocked, S.ProjectId AS A_ProjectId, 0 AS IsProjectMoved
--			,S.GlobalProjectID AS [GlobalProjectID], S.[IsPermanentDeleted], S.[ModifiedByFullName], S.[MigratedDate], S.[IsArchived], S.[IsShowMigrationPopup]
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[Project] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT @New_ProjectID = ProjectId, @IsOfficeMaster = IsOfficeMaster FROM [SLCProject].[dbo].[Project] WITH (NOLOCK) WHERE A_ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId

--		--Set IsDeleted flag to 1 for a temporary basis until whole project is Unarchived
--		UPDATE P
--			SET IsDeleted = 1--, ModifiedDate = GETUTCDATE()
--		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		WHERE P.ProjectId = @New_ProjectID

--		--Get RequestId from 
--		SELECT @RequestId = RequestId FROM [SLCProject].[dbo].[UnArchiveProjectRequest] WITH (NOLOCK)
--		WHERE [SLC_CustomerId] = @SLC_CustomerId AND [SLC_ArchiveProjectId] = @ProjectID AND [StatusId] = 1--StatusId 1 as Queued

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'New Project created', 'New Project created', '1', 3, @OldCount, @NewCount

--		--Move ProjectAddress table
--		INSERT INTO [SLCProject].[dbo].[ProjectAddress]
--		(ProjectId, CustomerId, AddressLine1, AddressLine2, CountryId, StateProvinceId, CityId, PostalCode, CreateDate, CreatedBy, ModifiedBy
--			,ModifiedDate, StateProvinceName, CityName)
--		SELECT @New_ProjectID AS ProjectId, S.CustomerId, S.AddressLine1, S.AddressLine2, S.CountryId, S.StateProvinceId, S.CityId, S.PostalCode
--			,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.StateProvinceName, S.CityName
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectAddress] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project Address created', 'Project Address created', '2', 6, @OldCount, @NewCount

			
--		--Move UserFolder table
--		INSERT INTO [SLCProject].[dbo].[UserFolder]
--		(FolderTypeId, ProjectId, UserId, LastAccessed, CustomerId, LastAccessByFullName)
--		SELECT S.FolderTypeId, @New_ProjectID AS ProjectId, S.UserId, S.LastAccessed, S.CustomerId, S.LastAccessByFullName
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[UserFolder] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		
--		EXECUTE [SLCProject].[dbo].[usp_GetMigratedProjectDefaultPrivacySetting] @SLC_CustomerId, @SLC_UserId, @IsOfficeMaster, @ProjectAccessTypeId OUTPUT, @ProjectOwnerId OUTPUT

--		--Move ProjectSummary table
--		INSERT INTO [SLCProject].[dbo].[ProjectSummary]
--		([ProjectId],[CustomerId],[UserId],[ProjectTypeId],[FacilityTypeId],[SizeUoM],[IsIncludeRsInSection],[IsIncludeReInSection]
--			,[SpecViewModeId],[UnitOfMeasureValueTypeId],[SourceTagFormat],[IsPrintReferenceEditionDate],[IsActivateRsCitation],[LastMasterUpdate]
--			,[BudgetedCostId],[BudgetedCost],[ActualCost],[EstimatedArea],[SpecificationIssueDate],[SpecificationModifiedDate],[ActualCostId]
--			,[ActualSizeId],[EstimatedSizeId],[EstimatedSizeUoM],[Cost],[Size],[ProjectAccessTypeId],[OwnerId],[TrackChangesModeId])
--		SELECT @New_ProjectID AS ProjectId,S.[CustomerId],S.[UserId],S.[ProjectTypeId],S.[FacilityTypeId],S.[SizeUoM],S.[IsIncludeRsInSection],S.[IsIncludeReInSection]
--			,S.[SpecViewModeId],S.[UnitOfMeasureValueTypeId],S.[SourceTagFormat],S.[IsPrintReferenceEditionDate],S.[IsActivateRsCitation],S.[LastMasterUpdate]
--			,S.[BudgetedCostId],S.[BudgetedCost],S.[ActualCost],S.[EstimatedArea],S.[SpecificationIssueDate],S.[SpecificationModifiedDate],S.[ActualCostId]
--			,S.[ActualSizeId],S.[EstimatedSizeId],S.[EstimatedSizeUoM],S.[Cost],S.[Size],@ProjectAccessTypeId AS [ProjectAccessTypeId],@ProjectOwnerId AS [OwnerId],S.[TrackChangesModeId]
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSummary] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSummary created', 'ProjectSummary created', '3', 9, @OldCount, @NewCount


--		--Move ProjectPageSetting table
--		INSERT INTO [SLCProject].[dbo].[ProjectPageSetting]
--		([MarginTop],[MarginBottom],[MarginLeft],[MarginRight],[EdgeHeader],[EdgeFooter],[IsMirrorMargin],[ProjectId],[CustomerId])
--		SELECT S.[MarginTop],S.[MarginBottom],S.[MarginLeft],S.[MarginRight],S.[EdgeHeader],S.[EdgeFooter],S.[IsMirrorMargin]
--			,@New_ProjectID AS [ProjectId],S.[CustomerId]
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectPageSetting] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPageSetting created', 'ProjectPageSetting created', '4', 12, @OldCount, @NewCount

			
--		--Move ProjectPaperSetting table
--		INSERT INTO [SLCProject].[dbo].[ProjectPaperSetting]
--		(PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId)
--		SELECT S.PaperName, S.PaperWidth, S.PaperHeight, S.PaperOrientation, S.PaperSource, @New_ProjectID AS ProjectId, S.CustomerId
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectPaperSetting] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPaperSetting created', 'ProjectPaperSetting created', '5', 15, @OldCount, @NewCount

			
--		--Move ProjectPaperSetting table
--		INSERT INTO [SLCProject].[dbo].[ProjectPrintSetting]
--		([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage]
--			,[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount],[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo])
--		SELECT @New_ProjectID AS [ProjectId],S.[CustomerId],S.[CreatedBy],S.[CreateDate],S.[ModifiedBy],S.[ModifiedDate],S.[IsExportInMultipleFiles],S.[IsBeginSectionOnOddPage]
--			,S.[IsIncludeAuthorInFileName],S.[TCPrintModeId], S.[IsIncludePageCount], S.IsIncludeHyperLink, S.KeepWithNext, S.[IsPrintMasterNote],S.[IsPrintProjectNote],S.[IsPrintNoteImage],S.[IsPrintIHSLogo]
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectPrintSetting] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPrintSetting created', 'ProjectPrintSetting created', '6', 18, @OldCount, @NewCount

--		SELECT ROW_NUMBER() OVER(ORDER BY S.SectionId) AS RowNumber, S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
--				,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
--				,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
--				,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
--		INTO #tmp_TgtSection
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @Section_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			INSERT INTO [SLCProject].[dbo].[ProjectSection]
--			(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
--				,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
--				,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
--				,TrackChangeLockedBy, DataMapDateTimeStamp)
--			SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
--					,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
--					,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
--					,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
--			FROM #tmp_TgtSection S
--			WHERE RowNumber BETWEEN @Start AND @End
 
--			SET @Records += @Section_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @Section_BatchSize - 1;
--		END

--		--INSERT INTO [SLCProject].[dbo].[ProjectSection]
--		--(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
--		--	,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
--		--	,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
--		--	,TrackChangeLockedBy, DataMapDateTimeStamp)
--		--SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
--		--		,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
--		--		,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
--		--		,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
--		--FROM #tmp_TgtSection S

--		SELECT SectionId, ParentSectionId, ProjectId, CustomerId, A_SectionId INTO #tmpProjectSection
--		FROM [SLCProject].[dbo].[ProjectSection] WITH (NOLOCK) WHERE ProjectId = @New_ProjectID AND CustomerId = @SLC_CustomerId

--		SELECT ProjectId, CustomerId, SectionId, A_SectionId INTO #NewOldSectionIdMapping FROM #tmpProjectSection

--		--UPDATE ParentSectionId in TGT Section table                  
--		UPDATE TGT_TMP SET TGT_TMP.ParentSectionId = NOSM.SectionId
--		FROM #tmpProjectSection TGT_TMP
--		INNER JOIN #NewOldSectionIdMapping NOSM ON TGT_TMP.ParentSectionId = NOSM.A_SectionId
--		WHERE TGT_TMP.ProjectId = @New_ProjectID;
			
--		--UPDATE ParentSectionId in original table                  
--		UPDATE PS SET PS.ParentSectionId = PS_TMP.ParentSectionId
--		FROM [SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSection PS_TMP ON PS.SectionId = PS_TMP.SectionId
--		WHERE PS.ProjectId = @New_ProjectID AND PS.CustomerId = @SLC_CustomerId;

--		DROP TABLE IF EXISTS #tmp_TgtSection;
--		DROP TABLE IF EXISTS #NewOldSectionIdMapping;
			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSection created', 'ProjectSection created', '7', 21, @OldCount, @NewCount

--		--DELETE FROM [ARCHIVESERVER02].[SLCProject].[dbo].[Staging_ProjectSection]
--		--WHERE ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId

--		--INSERT INTO [ARCHIVESERVER02].[SLCProject].[dbo].[Staging_ProjectSection]
--		--(SectionId, ProjectId, CustomerId)
--		--SELECT PS.SectionId, PS.ProjectId, PS.CustomerId
--		--FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
--		--WHERE PS.ProjectId = @ProjectID AND PS.CustomerId = @SLC_CustomerId
--		--AND ISNULL(PS.IsDeleted, 0) = 0;

			
--		--Move ProjectGlobalTerm table
--		INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
--		([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
--			,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
--		SELECT S.mGlobalTermId, @New_ProjectID AS ProjectId, S.CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode, S.CreatedDate, S.CreatedBy
--				,S.ModifiedDate, S.ModifiedBy, S.SLE_GlobalChoiceID, S.UserGlobalTermId, S.IsDeleted, S.GlobalTermId AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT P.GlobalTermId, P.CustomerId, P.ProjectId, P.UserGlobalTermId, P.GlobalTermCode, P.A_GlobalTermId INTO #tmpProjectGlobalTerm
--		FROM [SLCProject].[dbo].[ProjectGlobalTerm] P WITH (NOLOCK)
--		WHERE P.ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectGlobalTerm created', 'ProjectGlobalTerm created', '8', 24, @OldCount, @NewCount

--		--Insert #tmpProjectImage table
--		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
--					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.[ImageId] AS A_ImageId
--		INTO #TGTProImg
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectImage] SRC WITH (NOLOCK)
--		WHERE SRC.CustomerId = @SLC_CustomerId

--		--Update ProjectImage table
--		UPDATE TGT
--			SET TGT.[ImagePath] = SRC.[ImagePath], TGT.[LuImageSourceTypeId] = SRC.[LuImageSourceTypeId],TGT.[CreateDate] = SRC.[CreateDate]
--				,TGT.[ModifiedDate] = SRC.[ModifiedDate],TGT.[SLE_ProjectID] = SRC.[SLE_ProjectID],TGT.[SLE_DocID] = SRC.[SLE_DocID]
--				,TGT.[SLE_StatusID] = SRC.[SLE_StatusID],TGT.[SLE_SegmentID] = SRC.[SLE_SegmentID],TGT.[SLE_ImageNo] = SRC.[SLE_ImageNo]
--				,TGT.[SLE_ImageID] = SRC.[SLE_ImageID],TGT.[A_ImageId] = SRC.A_ImageId
--		FROM [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK)
--		INNER JOIN #TGTProImg SRC
--			ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND SRC.CustomerId = @SLC_CustomerId
--		WHERE TGT.CustomerId = @SLC_CustomerId

--		--Insert ProjectImage table
--		INSERT INTO [SLCProject].[dbo].[ProjectImage]
--		([ImagePath],[LuImageSourceTypeId],[CreateDate],[ModifiedDate],[CustomerId],[SLE_ProjectID],[SLE_DocID],[SLE_StatusID],[SLE_SegmentID]
--			,[SLE_ImageNo],[SLE_ImageID],[A_ImageId])
--		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
--					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.A_ImageId
--		FROM #TGTProImg SRC
--		LEFT OUTER JOIN [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK) ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND TGT.CustomerId = @SLC_CustomerId
--		WHERE SRC.CustomerId = @SLC_CustomerId AND TGT.ImagePath IS NULL

--		SELECT I.ImageId, I.CustomerId, I.ImagePath, I.A_ImageId INTO #tmpProjectImage
--		FROM [SLCProject].[dbo].[ProjectImage] I WITH (NOLOCK) WHERE I.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #TGTProImg;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectImage created', 'ProjectImage created', '9', 27, @OldCount, @NewCount

--		--Move ProjectSegment_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentId) AS RowNumber, S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
--				,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
--		INTO #ProjectSegment_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
--		--INNER JOIN [ARCHIVESERVER02].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
--		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId --AND S.CustomerId = PSC.CustomerId
--		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @Segment_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Insert ProjectSegment Table
--			INSERT INTO [SLCProject].[dbo].[ProjectSegment]
--			(SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID
--				,SLE_SegmentID, SLE_StatusID, A_SegmentId, IsDeleted, BaseSegmentDescription)
--			SELECT NULL AS SegmentStatusId, S2.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
--					,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
--			FROM #ProjectSegment_Staging S
--			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @Segment_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @Segment_BatchSize - 1;
--		END

--		----Insert ProjectSegment Table
--		--INSERT INTO [SLCProject].[dbo].[ProjectSegment]
--		--(SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID
--		--	,SLE_SegmentID, SLE_StatusID, A_SegmentId, IsDeleted, BaseSegmentDescription)
--		--SELECT NULL AS SegmentStatusId, S2.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
--		--		,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
--		--FROM #ProjectSegment_Staging S
--		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT S.SegmentId, S.SegmentStatusId, S.SegmentSource, S.SegmentCode, S.SectionId, S.ProjectId, S.CustomerId, S.SegmentDescription, S.A_SegmentId
--		INTO #tmpProjectSegment FROM [SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegment_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment created', 'ProjectSegment created', '10', 30, @OldCount, @NewCount


--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentStatusId) AS RowNumber, S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
--			,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
--			,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
--			,S.SLE_ProjectSegID, S.SLE_StatusID, S.SegmentStatusId AS A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
--		INTO #tmp_TgtSegmentStatus
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		--Update SectionId in ProjectSegmentStatus table
--		UPDATE S
--			SET S.SectionId = S1.SectionId
--		FROM #tmp_TgtSegmentStatus S
--		INNER JOIN #tmpProjectSection S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
--			AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Update SegmentId in ProjectSegmentStatus table
--		UPDATE S
--			SET S.SegmentId = S1.SegmentId
--		FROM #tmp_TgtSegmentStatus S
--		--FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegment S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
--			AND S.SectionId = S1.SectionId AND S.SegmentId = S1.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId;

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @SegmentStatus_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Insert ProjectSegmentStatus
--			INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
--			(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
--				,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
--				,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
--				,IsDeleted, TrackOriginOrder, MTrackDescription)
--			SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
--				,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
--				,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
--				,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
--			FROM #tmp_TgtSegmentStatus S
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @SegmentStatus_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @SegmentStatus_BatchSize - 1;
--		END

--		----Insert ProjectSegmentStatus
--		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
--		--(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
--		--	,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
--		--	,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
--		--	,IsDeleted, TrackOriginOrder, MTrackDescription)
--		--SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
--		--	,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
--		--	,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
--		--	,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
--		--FROM #tmp_TgtSegmentStatus S

--		SELECT S.* INTO #tmpProjectSegmentStatus FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT SegmentStatusId, A_SegmentStatusId INTO #NewOldSegmentStatusIdMapping
--		FROM #tmpProjectSegmentStatus S

--		--UPDATE ParentSegmentStatusId in temp table
--		UPDATE CPSST
--		SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId
--		FROM #tmpProjectSegmentStatus CPSST
--		INNER JOIN #NewOldSegmentStatusIdMapping PPSST
--			ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId AND CPSST.ParentSegmentStatusId <> 0

--		--UPDATE ParentSegmentStatusId in original table
--		UPDATE PSS
--		SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId
--		FROM [SLCProject].[dbo].[ProjectSegmentStatus] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegmentStatus PSS_TMP ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID
--		AND PSS.CustomerId = @SLC_CustomerId;


--		--Update SegmentStatusId in #tmpProjectSegment
--		UPDATE PS
--			SET PS.SegmentStatusId = SS.SegmentStatusId
--		FROM #tmpProjectSegment PS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegmentStatus SS WITH (NOLOCK) ON SS.ProjectId = PS.ProjectId AND SS.CustomerId = PS.CustomerId
--			AND SS.SectionId = PS.SectionId AND SS.SegmentId = PS.SegmentId
--		WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId;

--		--UPDATE SegmentStatusId in original table
--		UPDATE PSS
--		SET PSS.SegmentStatusId = PSS_TMP.SegmentStatusId
--		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

--		----RefStdCode need NOT be updated because there is no difference between RefStdCode on any of the SLC Servers

--		------Update SegmentDescription for ReferenceStandard Paragraph with new tag {RSTEMP#[RefStdCode]} when it is Master RefStdCode
--		----UPDATE P
--		----SET P.SegmentDescription = ([DE_Projects_Staging].[dbo].[fn_ReplaceSLEPlaceHolder] (P.SegmentDescription, '{RSTEMP#', '{RSTEMP#'
--		----		, [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
--		----		, NEWRS.RefStdCode))
--		----FROM [SLCProject].[dbo].[ProjectSegment] P 
--		----INNER JOIN [SLCProject].[dbo].[ProjectSegmentStatus] PS WITH (NOLOCK) ON PS.CustomerId = P.CustomerId AND PS.ProjectId = P.ProjectId AND PS.SectionId = P.SectionId
--		----	AND PS.SegmentId = P.SegmentId
--		----INNER JOIN [ARCHIVESERVER02].[SLCMaster].[dbo].[ReferenceStandard] OLDRS WITH (NOLOCK) ON OLDRS.MasterDataTypeId = 1 AND OLDRS.IsObsolete = 0
--		----	AND OLDRS.RefStdCode = [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
--		----INNER JOIN [SLCMaster].[dbo].[ReferenceStandard] NEWRS WITH (NOLOCK) ON NEWRS.RefStdName = OLDRS.RefStdName AND NEWRS.MasterDataTypeId = 1 AND NEWRS.IsObsolete = 0
--		----WHERE PS.CustomerId = @SLC_CustomerId AND PS.ProjectId = @New_ProjectID AND PS.IsRefStdParagraph = 1
--		----	AND [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription) < 10000000

--		DROP TABLE IF EXISTS #NewOldSegmentStatusIdMapping;
--		DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentStatus created', 'ProjectSegmentStatus created', '11', 33, @OldCount, @NewCount

--		--Insert ProjectSegmentGlobalTerm_Staging table
--		SELECT S.SegmentGlobalTermId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentId, S.mSegmentId, G1.UserGlobalTermId, G1.GlobalTermCode, S.IsLocked
--			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		INTO #ProjectSegmentGlobalTerm_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
--		LEFT JOIN [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectGlobalTerm] G WITH (NOLOCK) ON G.CustomerId = S.CustomerId AND G.UserGlobalTermId = S.UserGlobalTermId
--		LEFT JOIN #tmpProjectGlobalTerm G1 ON G1.CustomerId = G.CustomerId AND G1.A_GlobalTermId = G.GlobalTermId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentGlobalTerm table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentGlobalTerm]
--		(CustomerId, ProjectId, SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy
--			,ModifiedDate, ModifiedBy, IsDeleted)
--		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentId, S.mSegmentId, S.UserGlobalTermId, S.GlobalTermCode, S.IsLocked
--			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		FROM #ProjectSegmentGlobalTerm_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		LEFT JOIN #tmpProjectSegment S3 ON S2.ProjectId = S3.ProjectId AND S2.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentId = S3.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #tmpProjectGlobalTerm;
--		DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;
		
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentGlobalTerm created', 'ProjectSegmentGlobalTerm created', '12', 36, @OldCount, @NewCount

--		--Move Header table
--		INSERT INTO [SLCProject].[dbo].[Header]
--		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
--			,ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_HeaderId
--			,HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId, IsShowLineAboveHeader
--			,IsShowLineBelowHeader)
--		SELECT @New_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
--			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltHeader, S.FPHeader, S.UseSeparateFPHeader, S.HeaderFooterCategoryId
--			,S.[DateFormat], S.TimeFormat, S.HeaderId AS A_HeaderId, S.HeaderFooterDisplayTypeId, S.DefaultHeader, S.FirstPageHeader, S.OddPageHeader, S.EvenPageHeader
--			,S.DocumentTypeId, S.IsShowLineAboveHeader, S.IsShowLineBelowHeader
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[Header] S WITH (NOLOCK)
--		LEFT JOIN #tmpProjectSection S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S2.A_SectionId = S.SectionId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Header created', 'Header created', '13', 39, @OldCount, @NewCount

--		--Move Footer table
--		INSERT INTO [SLCProject].[dbo].[Footer]
--		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
--			,ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_FooterId
--			,HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId, IsShowLineAboveFooter
--			,IsShowLineBelowFooter)
--		SELECT @New_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
--			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltFooter, S.FPFooter, S.UseSeparateFPFooter, S.HeaderFooterCategoryId
--			,S.[DateFormat], S.TimeFormat, S.FooterId AS A_FooterId, S.HeaderFooterDisplayTypeId, S.DefaultFooter, S.FirstPageFooter, S.OddPageFooter, S.EvenPageFooter
--			,S.DocumentTypeId, S.IsShowLineAboveFooter, IsShowLineBelowFooter
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[Footer] S WITH (NOLOCK)
--		LEFT JOIN #tmpProjectSection S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S.SectionId = S2.A_SectionId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Footer created', 'Footer created', '14', 42, @OldCount, @NewCount


--		--Move HeaderFooterGlobalTermUsage_Staging table
--		SELECT S.HeaderFooterGTId, S.HeaderId, S.FooterId, G1.UserGlobalTermId, S.CustomerId, @New_ProjectID AS ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
--		INTO #HeaderFooterGlobalTermUsage_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[HeaderFooterGlobalTermUsage] S WITH (NOLOCK)
--		LEFT JOIN [SLCProject].[dbo].[UserGlobalTerm] G1 WITH (NOLOCK) ON G1.CustomerId = S.CustomerId AND G1.UserGlobalTermId = S.UserGlobalTermId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move HeaderFooterGlobalTermUsage table
--		INSERT INTO [SLCProject].[dbo].[HeaderFooterGlobalTermUsage]
--		(HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
--		SELECT S2.HeaderId, S3.FooterId, S.UserGlobalTermId, S.CustomerId, S.ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
--		FROM #HeaderFooterGlobalTermUsage_Staging S
--		LEFT JOIN [SLCProject].[dbo].[Header] S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.HeaderId = S2.A_HeaderId
--		LEFT JOIN [SLCProject].[dbo].[Footer] S3 WITH (NOLOCK) ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S.FooterId = S3.A_FooterId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HeaderFooterGlobalTermUsage created', 'HeaderFooterGlobalTermUsage created', '15', 45, @OldCount, @NewCount

		
--		--Insert ProjectReferenceStandard_Staging table
--		SELECT @New_ProjectID AS ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
--			,S.SectionId, S.CustomerId, S.ProjRefStdId, S.IsDeleted
--		INTO #ProjectReferenceStandard_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectReferenceStandard table
--		INSERT INTO [SLCProject].[dbo].[ProjectReferenceStandard]
--		(ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)
--		SELECT S.ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
--			,S2.SectionId, S.CustomerId, S.IsDeleted
--		FROM #ProjectReferenceStandard_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId
		
--		DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectReferenceStandard created', 'ProjectReferenceStandard created', '16', 48, @OldCount, @NewCount

--		--Insert ProjectSegmentChoice_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.SegmentChoiceId, S.SectionId, S.SegmentStatusId, S.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
--				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
--				,S.SegmentChoiceId AS A_SegmentChoiceId, S.IsDeleted
--		INTO #ProjectSegmentChoice_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentChoice] S WITH (NOLOCK)
--		--INNER JOIN [ARCHIVESERVER02].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
--		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId AND S.CustomerId = PSC.CustomerId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectSegmentChoice table
--			INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
--			(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--				,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
--			SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
--					,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
--					,S.A_SegmentChoiceId, S.IsDeleted
--			FROM #ProjectSegmentChoice_Staging S
--			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentStatusId = S3.A_SegmentStatusId
--			INNER JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--				AND S.SegmentId = S4.A_SegmentId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectSegmentChoice_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1;
--		END

--		----Move ProjectSegmentChoice table
--		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
--		--(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--		--	,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
--		--SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
--		--		,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
--		--		,S.A_SegmentChoiceId, S.IsDeleted
--		--FROM #ProjectSegmentChoice_Staging S
--		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
--		--INNER JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--		--	AND S.SegmentId = S4.A_SegmentId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT C.SegmentChoiceId, C.ProjectId, C.SectionId, C.CustomerId, C.A_SegmentChoiceId INTO #tmpProjectSegmentChoice FROM [SLCProject].[dbo].[ProjectSegmentChoice] C WITH (NOLOCK)
--		WHERE C.ProjectId = @New_ProjectID AND C.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice created', 'ProjectSegmentChoice created', '17', 51, @OldCount, @NewCount

--		--Insert ProjectChoiceOption_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.ChoiceOptionId, S.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, @New_ProjectID AS ProjectId, S.SectionId, S.CustomerId, S.ChoiceOptionCode
--			,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.ChoiceOptionId AS A_ChoiceOptionId, S.IsDeleted
--		INTO #ProjectChoiceOption_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectChoiceOption] S WITH (NOLOCK)
--		--INNER JOIN [ARCHIVESERVER02].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK) 
--		--	ON S.ProjectId = PSC.ProjectId AND S.Sectionid = PSC.SectionId AND S.CustomerId = PSC.CustomerId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectChoiceOption_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectChoiceOption table
--			INSERT INTO [SLCProject].[dbo].[ProjectChoiceOption]
--			(SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--				,A_ChoiceOptionId, IsDeleted)
--			SELECT S3.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, S.ProjectId, S2.SectionId, S.CustomerId, S.ChoiceOptionCode
--				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.A_ChoiceOptionId, S.IsDeleted
--			FROM #ProjectChoiceOption_Staging S
--			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentChoice S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentChoiceId = S3.A_SegmentChoiceId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectChoiceOption_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectChoiceOption_BatchSize - 1;
--		END

--		----Move ProjectChoiceOption table
--		--INSERT INTO [SLCProject].[dbo].[ProjectChoiceOption]
--		--(SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--		--	,A_ChoiceOptionId, IsDeleted)
--		--SELECT S3.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, S.ProjectId, S2.SectionId, S.CustomerId, S.ChoiceOptionCode
--		--	,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.A_ChoiceOptionId, S.IsDeleted
--		--FROM #ProjectChoiceOption_Staging S
--		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentChoice S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentChoiceId = S3.A_SegmentChoiceId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #tmpProjectSegmentChoice;
--		DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectChoiceOption created', 'ProjectChoiceOption created', '18', 54, @OldCount, @NewCount

--		--Insert SelectedChoiceOption_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SelectedChoiceOptionId) AS RowNumber, S.SelectedChoiceOptionId, S.SegmentChoiceCode, S.ChoiceOptionCode
--				,S.ChoiceOptionSource, S.IsSelected, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId
--				,S.OptionJson, S.IsDeleted
--		INTO #SelectedChoiceOption_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[SelectedChoiceOption] S WITH (NOLOCK)
--		--INNER JOIN [ARCHIVESERVER02].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)	
--		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId AND S.CustomerId = PSC.CustomerId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @SelectedChoiceOption_BatchSize - 1
--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move SelectedChoiceOption table
--			INSERT INTO [SLCProject].[dbo].[SelectedChoiceOption]
--			(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
--			SELECT S.SegmentChoiceCode, S.ChoiceOptionCode, S.ChoiceOptionSource, S.IsSelected, S2.SectionId, S.ProjectId, S.CustomerId, S.OptionJson, S.IsDeleted
--			FROM #SelectedChoiceOption_Staging S
--			--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSection S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
--			WHERE S.SectionId = S2.A_SectionId AND S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @SelectedChoiceOption_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @SelectedChoiceOption_BatchSize - 1;
--		END

--		----Move SelectedChoiceOption table
--		--INSERT INTO [SLCProject].[dbo].[SelectedChoiceOption]
--		--(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
--		--SELECT S.SegmentChoiceCode, S.ChoiceOptionCode, S.ChoiceOptionSource, S.IsSelected, S2.SectionId, S.ProjectId, S.CustomerId, S.OptionJson, S.IsDeleted
--		--FROM #SelectedChoiceOption_Staging S
--		--INNER JOIN #tmpProjectSection S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SelectedChoiceOption created', 'SelectedChoiceOption created', '19', 57, @OldCount, @NewCount

--		--Move ProjectHyperLink table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.HyperLinkId) AS RowNumber, S.HyperLinkId, S.SectionId, S.SegmentId
--				,S.SegmentStatusId, @New_ProjectID AS ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
--				,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
--				,S.HyperLinkId AS A_HyperLinkId
--		INTO #ProjectHyperLink_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectHyperLink] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectHyperLink_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectHyperLink table
--			INSERT INTO [SLCProject].[dbo].[ProjectHyperLink]
--			(SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
--				,ModifiedDate, ModifiedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
--			SELECT S2.SectionId, CASE WHEN S4.SegmentId IS NULL THEN S.SegmentId ELSE S4.SegmentId END AS SegmentId, S3.SegmentStatusId, S.ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
--					,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
--					,S.A_HyperLinkId
--			FROM #ProjectHyperLink_Staging S
--			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentStatusId = S3.A_SegmentStatusId
--			LEFT JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--				AND S.SegmentId = S4.A_SegmentId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectHyperLink_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectHyperLink_BatchSize - 1;
--		END

--		----Move ProjectHyperLink table
--		--INSERT INTO [SLCProject].[dbo].[ProjectHyperLink]
--		--(SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
--		--	,ModifiedDate, ModifiedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
--		--SELECT S2.SectionId, CASE WHEN S4.SegmentId IS NULL THEN S.SegmentId ELSE S4.SegmentId END AS SegmentId, S3.SegmentStatusId, S.ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
--		--		,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
--		--		,S.A_HyperLinkId
--		--FROM #ProjectHyperLink_Staging S
--		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
--		--LEFT JOIN #tmpProjectSegment S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--		--	AND S.SegmentId = S4.A_SegmentId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT H.HyperLinkId, H.A_HyperLinkId, H.CustomerId, H.ProjectId, H.SectionId, H.SegmentStatusId, H.SegmentId
--		INTO #tmpProjectHyperLink FROM [SLCProject].[dbo].[ProjectHyperLink] H WITH (NOLOCK) WHERE H.ProjectId = @New_ProjectID AND H.CustomerId = @SLC_CustomerId

--		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
--		UPDATE A
--			SET A.SegmentDescription = B.NewSegmentDescription
--		FROM #tmpProjectSegment A
--		INNER JOIN (
--					SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentId) AS SegmentId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
--					FROM #tmpProjectSegment PS
--					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
--						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
--					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
--		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
--		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

		
--		DROP TABLE IF EXISTS #ProjectHyperLink_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink created', 'ProjectHyperLink created', '20', 60, @OldCount, @NewCount

--		--Insert ProjectNote_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.NoteId) AS RowNumber, S.NoteId, S.SectionId, S.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.Title
--				,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.NoteId AS A_NoteId
--		INTO #ProjectNote_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectNote] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectNote_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectNote table
--			INSERT INTO [SLCProject].[dbo].[ProjectNote]
--			(SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName
--				,ModifiedUserName, IsDeleted, NoteCode, A_NoteId)
--			SELECT S2.SectionId, S3.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId, S.Title
--					,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.A_NoteId
--			FROM #ProjectNote_Staging S
--			INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentStatusId = S3.A_SegmentStatusId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectNote_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectNote_BatchSize - 1;
--		END

--		----Move ProjectNote table
--		--INSERT INTO [SLCProject].[dbo].[ProjectNote]
--		--(SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName
--		--	,ModifiedUserName, IsDeleted, NoteCode, A_NoteId)
--		--SELECT S2.SectionId, S3.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId, S.Title
--		--		,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.A_NoteId
--		--FROM #ProjectNote_Staging S
--		--INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT P.NoteId, P.SectionId, P.SegmentStatusId, P.NoteText, P.ProjectId, P.CustomerId, P.A_NoteId INTO #tmpProjectNote
--		FROM [SLCProject].[dbo].[ProjectNote] P WITH (NOLOCK)
--		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

--		--Upate HyperLink placeholders with new HyperLinkId in ProjectNote table
--		UPDATE A
--			SET A.NoteText = B.NoteText
--		FROM #tmpProjectNote A
--		INNER JOIN (
--					SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentStatusId) AS SegmentStatusId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
--					FROM #tmpProjectNote PS
--					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectHyperLink HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
--						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
--					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
--		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.NoteText = PSS_TMP.NoteText
--		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectNote PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

--		DROP TABLE IF EXISTS #ProjectNote_Staging;
--		DROP TABLE IF EXISTS #tmpProjectHyperLink;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote created', 'ProjectNote created', '21', 63, @OldCount, @NewCount

--		--Insert ProjectSegmentReferenceStandard_Staging table
--		SELECT S.SegmentRefStandardId, S.SectionId, S.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
--				,@New_ProjectID AS ProjectId, S.CustomerId, S.RefStdCode, S.IsDeleted
--		INTO #ProjectSegmentReferenceStandard_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


--		--Move ProjectSegmentReferenceStandard table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentReferenceStandard]
--		(SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, mSegmentId, ProjectId, CustomerId
--			,RefStdCode, IsDeleted)
--		SELECT S2.SectionId, S3.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
--				,S.ProjectId, S.CustomerId, S.RefStdCode, S.IsDeleted
--		FROM #ProjectSegmentReferenceStandard_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		LEFT JOIN #tmpProjectSegment S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentId = S3.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentReferenceStandard created', 'ProjectSegmentReferenceStandard created', '22', 66, @OldCount, @NewCount

--		--Insert ProjectSegmentTab_Staging table
--		SELECT S.SegmentTabId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy
--				,S.ModifiedDate, S.ModifiedBy
--		INTO #ProjectSegmentTab_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentTab] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentTab table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTab]
--		(CustomerId, ProjectId, SectionId, SegmentStatusId, TabTypeId, TabPosition, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
--		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy
--		FROM #ProjectSegmentTab_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentStatusId = S3.A_SegmentStatusId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTab created', 'ProjectSegmentTab created', '23', 69, @OldCount, @NewCount

--		--Move ProjectSegmentRequirementTag_Staging table
--		SELECT S.SegmentRequirementTagId, S.SectionId, S.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId
--				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
--		INTO #ProjectSegmentRequirementTag_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentRequirementTag] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentRequirementTag table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentRequirementTag]
--		(SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId
--			,IsDeleted)
--		SELECT S2.SectionId, S3.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId
--				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
--		FROM #ProjectSegmentRequirementTag_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentStatusId = S3.A_SegmentStatusId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentRequirementTag created', 'ProjectSegmentRequirementTag created', '24', 72, @OldCount, @NewCount

--		--Insert ProjectSegmentUserTag_Staging table
--		SELECT S.SegmentUserTagId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy
--				,S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		INTO #ProjectSegmentUserTag_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentUserTag] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentUserTag table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentUserTag]
--		(CustomerId, ProjectId, SectionId, SegmentStatusId, UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted)
--		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		FROM #ProjectSegmentUserTag_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectSegmentStatus S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentStatusId = S3.A_SegmentStatusId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentUserTag created', 'ProjectSegmentUserTag created', '25', 75, @OldCount, @NewCount

--		--Insert ProjectSegmentImage_Staging table
--		SELECT S.SegmentImageId, S.SegmentId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
--		INTO #ProjectSegmentImage_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentImage table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentImage]
--		(SegmentId, SectionId, ImageId, ProjectId, CustomerId, ImageStyle)
--		SELECT S3.SegmentId, S2.SectionId, S4.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
--		FROM #ProjectSegmentImage_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectSegment S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentId = S3.A_SegmentId
--		INNER JOIN #tmpProjectImage S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT S.SegmentImageId, S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.ImageId INTO #tmpProjectSegmentImage
--		FROM [SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK) WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Update Image plaholders with new ImageId in ProjectSegment table
--		UPDATE A
--			SET A.SegmentDescription = B.NewSegmentDescription
--		FROM #tmpProjectSegment A
--		INNER JOIN (
--					SELECT S5.CustomerId, S5.ProjectId, MAX(S5.SectionId) AS SectionId, MAX(S5.SegmentId) AS SegmentId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NewSegmentDescription
--					FROM #tmpProjectSegment PS
--					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectSegmentImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
--						AND PS.SegmentId = S5.SegmentId
--					INNER JOIN #tmpProjectImage ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
--					GROUP BY S5.ProjectId, S5.CustomerId, S5.SectionId, S5.SegmentId
--		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
--		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegment PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

--		DROP TABLE IF EXISTS #tmpProjectSegmentImage;
--		DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentImage created', 'ProjectSegmentImage created', '26', 78, @OldCount, @NewCount

--		--Insert ProjectNoteImage_Staging table
--		SELECT S.NoteImageId, S.NoteId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, S.CustomerId
--		INTO #ProjectNoteImage_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectNoteImage] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectNoteImage table
--		INSERT INTO [SLCProject].[dbo].[ProjectNoteImage]
--		(NoteId, SectionId, ImageId, ProjectId, CustomerId)
--		SELECT S3.NoteId, S2.SectionId, S4.ImageId, S.ProjectId, S.CustomerId
--		FROM #ProjectNoteImage_Staging S
--		INNER JOIN #tmpProjectSection S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectNote S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.NoteId = S3.A_NoteId
--		INNER JOIN #tmpProjectImage S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT P.NoteImageId, P.ProjectId, P.CustomerId, P.SectionId, P.NoteId, P.ImageId INTO #tmpProjectNoteImage FROM [SLCProject].[dbo].[ProjectNoteImage] P WITH (NOLOCK)
--		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

--		--Update Image placeholders with new ImageId in ProjectNote table
--		UPDATE A
--			SET A.NoteText = B.NoteText
--		FROM #tmpProjectNote A
--		INNER JOIN (
--					SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NoteText
--					FROM #tmpProjectNote PS
--					INNER JOIN #tmpProjectSection S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatus S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectNoteImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
--						AND PS.NoteId = S5.NoteId
--					INNER JOIN #tmpProjectImage ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
--					GROUP BY PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId--, S5.NoteId, S5.ImageId
--		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.NoteText = PSS_TMP.NoteText
--		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectNote PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

--		DROP TABLE IF EXISTS #tmpProjectImage;
--		DROP TABLE IF EXISTS #tmpProjectNote;
--		DROP TABLE IF EXISTS #tmpProjectSegmentStatus;
--		DROP TABLE IF EXISTS #ProjectNoteImage_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNoteImage created', 'ProjectNoteImage created', '27', 81, @OldCount, @NewCount

--		--Move ProjectSegmentLink table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentLinkId) AS RowNumber, S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
--			,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
--			,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentLinkCode
--			,S.SegmentLinkSourceTypeId
--		INTO #ProjectSegmentLink_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentLink] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectSegmentLink_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Insert ProjectSegmentLink table
--			INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
--			(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource
--				,TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId
--				,IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
--			SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
--				,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
--				,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.ProjectId, S.CustomerId, S.SegmentLinkCode
--				,S.SegmentLinkSourceTypeId
--			FROM #ProjectSegmentLink_Staging S
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectSegmentLink_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectSegmentLink_BatchSize - 1;
--		END

--		----Insert ProjectSegmentLink table
--		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
--		--(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource
--		--	,TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId
--		--	,IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
--		--SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
--		--	,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
--		--	,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.ProjectId, S.CustomerId, S.SegmentLinkCode
--		--	,S.SegmentLinkSourceTypeId
--		--FROM #ProjectSegmentLink_Staging S
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentLink created', 'ProjectSegmentLink created', '28', 84, @OldCount, @NewCount

--		--Move ProjectSegmentTracking table
--		SELECT S.[SegmentId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
--		INTO #ProjectSegmentTracking_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectSegmentTracking] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTracking]
--		([SegmentId], [ProjectId], [CustomerId], [UserId], [SegmentDescription], [CreatedBy], [CreateDate], [VersionNumber])
--		SELECT S1.[SegmentId], S.[ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
--		FROM #ProjectSegmentTracking_Staging S
--		INNER JOIN #tmpProjectSegment S1 ON S.CustomerId = S1.CustomerId AND S.SegmentId = S1.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTracking created', 'ProjectSegmentTracking created', '29', 87, @OldCount, @NewCount

--		--Move ProjectDisciplineSection table
--		SELECT S.[SectionId], S.[Disciplineld], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[IsActive]
--		INTO #ProjectDisciplineSection_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectDisciplineSection] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[ProjectDisciplineSection]
--		([SectionId], [Disciplineld], [ProjectId], [CustomerId], [IsActive])
--		SELECT S1.[SectionId], S.[Disciplineld], S.[ProjectId], S.[CustomerId], S.[IsActive]
--		FROM #ProjectDisciplineSection_Staging S
--		INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDisciplineSection created', 'ProjectDisciplineSection created', '30', 90, @OldCount, @NewCount

--		--Move ProjectDateFormat table
--		INSERT INTO [SLCProject].[dbo].[ProjectDateFormat]
--		([MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate])
--		SELECT S.[MasterDataTypeId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[ClockFormat], S.[DateFormat], S.[CreateDate]
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[ProjectDateFormat] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDateFormat created', 'ProjectDateFormat created', '31', 93, @OldCount, @NewCount

--		--Move MaterialSection table
--		SELECT @New_ProjectID AS [ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId]
--		INTO #MaterialSection_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[MaterialSection]
--		([ProjectId], [VimId], [MaterialId], [SectionId], [CustomerId])
--		SELECT S.[ProjectId], S.[VimId], S.[MaterialId], S1.[SectionId], S.[CustomerId]
--		FROM #MaterialSection_Staging S
--		INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #MaterialSection_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'MaterialSection created', 'MaterialSection created', '32', 96, @OldCount, @NewCount

--		--Move LinkedSections table
--		SELECT @New_ProjectID AS [ProjectId], S.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
--		INTO #LinkedSections_Staging
--		FROM [ARCHIVESERVER02].[SLCProject].[dbo].[LinkedSections] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[LinkedSections]
--		([ProjectId], [SectionId], [VimId], [MaterialId], [Linkedby], [LinkedDate], [customerId])
--		SELECT S.[ProjectId], S1.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
--		FROM #LinkedSections_Staging S
--		INNER JOIN #tmpProjectSection S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #tmpProjectSection;
--		DROP TABLE IF EXISTS #LinkedSections_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'LinkedSections created', 'LinkedSections created', '33', 99, @OldCount, @NewCount

--		--Load Project Migration Exception table
--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Choice' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegment S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\ch\#%'

--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'ReferenceStandard' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegment S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\rs\#%'

--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'HyperLink' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegment S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\hl\#%'

--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Image' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegment S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\img\#%'

--		DROP TABLE IF EXISTS #tmpProjectSegment;

--		----Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
--		--UPDATE P
--		--SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0--, P.ModifiedDate = GETUTCDATE()
--		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		--WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

--		----Mark Old ProjectID as Deleted in SLCProject..Project table
--		--UPDATE P
--		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		--WHERE P.ProjectId = @OldSLC_ProjectID AND P.CustomerId = @SLC_CustomerId;

--		----Update Project details in Archive server for the project that has been UnArchived successfully
--		--UPDATE A
--		--SET A.SLC_ProdProjectId = @New_ProjectID, A.IsArchived = 0, A.UnArchiveTimeStamp = GETUTCDATE()
--		--	,A.InProgressStatusId = 4 --UnArchiveCompleted --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER02].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveCompleted')
--		--	,A.DisplayTabId = 3 --ActiveProjectsTab
--		--	,A.ProcessInitiatedById = 3 --SLC
--		--FROM [ARCHIVESERVER02].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--		--WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

--		----Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
--		--UPDATE P
--		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1
--		--FROM [ARCHIVESERVER02].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		--WHERE P.ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId;

--		--EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '34', 100, 0, 0

--		--UPDATE U
--		--SET U.SLCProd_ProjectId = @New_ProjectID
--		--FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
--		--WHERE U.RequestId = @RequestId;

--		--Restore Deleted global data
--		EXECUTE [SLCProject].[dbo].[sp_RestoreDeletedGlobalData] @SLC_CustomerId, @New_ProjectID, @IsRestoreDeleteFailed OUTPUT
--		IF @IsRestoreDeleteFailed = 1
--		BEGIN
--			SET @IsProjectMigrationFailed = 1

--			--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
--			UPDATE P
--			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId;

--			--Update Project details in Archive server for the project that has been UnArchived successfully
--			UPDATE A
--			SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
--				,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER02].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
--				,A.DisplayTabId = 1 --MigratedTab
--			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

--			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Failed with Restore Delete', 'Failed with Restore Delete', '35', NULL, 0, 0
--		END
--		ELSE
--		BEGIN
--			--Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
--			UPDATE P
--			SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0--, P.ModifiedDate = GETUTCDATE()
--			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

--			--Mark Old ProjectID as Deleted in SLCProject..Project table
--			UPDATE P
--			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.ProjectId = @OldSLC_ProjectID AND P.CustomerId = @SLC_CustomerId;

--			--Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
--			UPDATE P
--			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1
--			FROM [ARCHIVESERVER02].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId;

--			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '34', 100, 0, 0

--			UPDATE U
--			SET U.SLCProd_ProjectId = @New_ProjectID
--			FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
--			WHERE U.RequestId = @RequestId;

--			--Update Project details in Archive server for the project that has been UnArchived successfully
--			UPDATE A
--			SET A.SLC_ProdProjectId = @New_ProjectID, A.IsArchived = 0, A.UnArchiveTimeStamp = GETUTCDATE()
--				,A.InProgressStatusId = 4 --UnArchiveCompleted --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER02].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveCompleted')
--				,A.DisplayTabId = 3 --ActiveProjectsTab
--				,A.ProcessInitiatedById = 3 --SLC
--			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId
--		END

--	END TRY

--	BEGIN CATCH
--		/*************************************
--		*  Get the Error Message for @@Error
--		*************************************/
--		--Set IsProjectMigrationFailed to 1
--		SET @IsProjectMigrationFailed = 1

--		--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
--		UPDATE P
--		SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId;

--		--Update Project details in Archive server for the project that has been UnArchived successfully
--		UPDATE A
--		SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
--			,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER02].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
--			,A.DisplayTabId = 1 --MigratedTab
--		FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--		WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived Failed', 'Project UnArchived Failed', '35', NULL, 0, 0

--		SET @ErrorStep = 'UnArchiveMigrateProjectTables'

--		SELECT @ErrorCode = ERROR_NUMBER()
--			, @Return_Message = @ErrorStep + ' '
--			+ cast(ERROR_NUMBER() as varchar(20)) + ' line: '
--			+ cast(ERROR_LINE() as varchar(20)) + ' ' 
--			+ ERROR_MESSAGE() + ' > ' 
--			+ ERROR_PROCEDURE()

--		EXEC [SLCProject].[dbo].[spb_LogErrors] @ProjectID, @ErrorCode, @ErrorStep, @Return_Message

    
--	END CATCH
		
--	--	--Update Processed to 1
--	--	UPDATE A
--	--	SET A.IsProcessed = 1
--	--	FROM #tmpUnArchiveCycleIDs A
--	--	WHERE SLC_CustomerId = @SLC_CustomerId AND SLC_ArchiveProjectId = @ProjectID;

--	--	SET @RowCount = @RowCount + 1
--	--END

--	--DROP TABLE #tmpUnArchiveCycleIDs
--END
--GO
--PRINT N'Altering [dbo].[sp_UnArchiveMigratedCycles_SyncedMaster]...';


--GO
--ALTER PROCEDURE [dbo].[sp_UnArchiveMigratedCycles_SyncedMaster]  
--AS  
--BEGIN  
    
-- DECLARE @ErrorCode INT = 0  
-- DECLARE @Return_Message VARCHAR(1024)  
-- DECLARE @ErrorStep VARCHAR(50)  
-- DECLARE @NumberRecords int, @RowCount int  
-- DECLARE @RequestId AS INT  
  
-- IF OBJECT_ID('tempdb..#tmpUnArchiveCycleIDs') IS NOT NULL DROP TABLE #tmpUnArchiveCycleIDs  
-- CREATE TABLE #tmpUnArchiveCycleIDs  
-- (  
--  RowID     INT IDENTITY(1, 1),   
--  CycleID     BIGINT NULL,  
--  CustomerID    INT NOT NULL,  
--  SubscriptionID   INT NULL,   
--  ProjectID    INT NOT NULL,  
--  SLC_CustomerId   INT NOT NULL,  
--  SLC_UserId    INT NOT NULL,  
--  SLC_ArchiveProjectId INT NOT NULL,  
--  SLC_ProdProjectId  INT NULL,  
--  SLC_ServerId   INT NULL,  
--  MigrateStatus   INT NULL,  
--  CreatedDate    DATETIME NULL,  
--  MovedDate    DATETIME NULL,  
--  MigratedDate   DATETIME NULL,  
--  IsProcessed    BIT NULL DEFAULT((0)),  
--  Archive_ServerId  INT NOT NULL  
-- )  
   
-- DECLARE @IsProjectMigrationFailed AS INT = 0  
  
-- INSERT INTO #tmpUnArchiveCycleIDs (CycleID, CustomerID, SubscriptionID, ProjectID, SLC_CustomerId, SLC_UserId, SLC_ArchiveProjectId, SLC_ProdProjectId, SLC_ServerId, MigrateStatus, MigratedDate, IsProcessed  
--  ,Archive_ServerId)  
-- SELECT AP.CycleID, AP.LegacyCustomerID, AP.LegacySubscriptionID, AP.LegacyProjectID, AP.SLC_CustomerId, AP.SLC_UserId, AP.SLC_ArchiveProjectId, AP.SLC_ProdProjectId, AP.SLC_ServerId, AP.MigrateStatus  
--  ,AP.MigratedDate, 0 AS IsProcessed, AP.Archive_ServerId  
-- FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH (NOLOCK)  
-- INNER JOIN [SLCADMIN].[Authentication].[dbo].[CustomerTenantDbServer] CS ON CS.CustomerId = AP.SLC_CustomerId   
--  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
-- WHERE AP.InProgressStatusId = 3 --UnArchiveInitiated  
--  AND AP.ProcessInitiatedById IN (1,2) --SLE or SLEWeb  
--  AND AP.MigrateStatus = 1 AND AP.DisplayTabId = 1 --MigratedTab  
--  AND AP.IsArchived = 1  
--  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
  
-- -- Get the number of records in the temporary table  
-- SET @NumberRecords = @@ROWCOUNT  
-- SET @RowCount = 1  
  
-- WHILE @RowCount <= @NumberRecords  
-- BEGIN  
--  --Set IsProjectMigrationFailed to 0 to reset it  
--  SET @IsProjectMigrationFailed = 0  
  
--  DECLARE @CustomerID INT, @SubscriptionID INT, @SLE_ProjectID INT, @MigrateStatus INT, @MigratedDate DATETIME, @SLC_CustomerId INT, @SLC_UserId INT, @ProjectID INT, @IsProcessed INT, @CycleID BIGINT  
--   , @SLC_ServerId INT, @OldSLC_ProjectID INT, @Archive_ServerId INT  
--  --Get next CycleID  
--  SELECT @CustomerID = CustomerID, @SubscriptionID = SubscriptionID, @SLE_ProjectID = ProjectID, @SLC_CustomerId = SLC_CustomerId, @SLC_UserId = SLC_UserId, @CycleID = CycleID  
--   ,@MigrateStatus = MigrateStatus, @ProjectID = SLC_ArchiveProjectId, @OldSLC_ProjectID = ISNULL(SLC_ProdProjectId, 0), @SLC_ServerId = SLC_ServerId, @MigratedDate = MigratedDate, @IsProcessed = IsProcessed  
--   ,@Archive_ServerId = Archive_ServerId  
--  FROM #tmpUnArchiveCycleIDs WHERE RowID = @RowCount AND IsProcessed = 0  
  
--  --Call Unarchive Project for MigratedCycle procedure depend on the ArchiveServer mapping  
--  IF @Archive_ServerId = 1  
--  BEGIN  
--   EXECUTE [SLCProject].[dbo].[sp_UnArchiveMigratedCycles_ArchServer01] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
--  END  
--  ELSE IF @Archive_ServerId = 2  
--  BEGIN  
--   EXECUTE [SLCProject].[dbo].[sp_UnArchiveMigratedCycles_ArchServer02] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
--  END  
  
--  --Update Processed to 1  
--  UPDATE A  
--  SET A.IsProcessed = 1  
--  FROM #tmpUnArchiveCycleIDs A  
--  WHERE SLC_CustomerId = @SLC_CustomerId AND SLC_ArchiveProjectId = @ProjectID;  
  
--  SET @RowCount = @RowCount + 1  
-- END  
  
-- DROP TABLE #tmpUnArchiveCycleIDs;  
--END
--GO
--PRINT N'Altering [dbo].[sp_UnArchiveProject]...';


--GO
--ALTER PROCEDURE [dbo].[sp_UnArchiveProject]  
--AS  
--BEGIN  
    
-- DECLARE @ErrorCode INT = 0  
-- DECLARE @Return_Message VARCHAR(1024)  
-- DECLARE @ErrorStep VARCHAR(50)  
-- DECLARE @NumberRecords int, @RowCount int  
-- DECLARE @RequestId AS INT  
  
-- IF OBJECT_ID('tempdb..#tmpUnArchiveCycleIDs') IS NOT NULL DROP TABLE #tmpUnArchiveCycleIDs  
-- CREATE TABLE #tmpUnArchiveCycleIDs  
-- (  
--  RowID     INT IDENTITY(1, 1),   
--  SLC_CustomerId   INT NOT NULL,  
--  SLC_UserId    INT NOT NULL,  
--  SLC_ArchiveProjectId INT NOT NULL,  
--  OldSLC_ProjectID  INT NULL,  
--  SLC_ServerId   INT NULL,  
--  MigrateStatus   INT NULL,  
--  CreatedDate    DATETIME NULL,  
--  MovedDate    DATETIME NULL,  
--  MigratedDate   DATETIME NULL,  
--  IsProcessed    BIT NULL DEFAULT((0)),  
--  Archive_ServerId  INT NOT NULL  
-- )  
  
-- DECLARE @IsProjectMigrationFailed AS INT = 0  
  
-- INSERT INTO #tmpUnArchiveCycleIDs (SLC_CustomerId, SLC_UserId, SLC_ArchiveProjectId, OldSLC_ProjectID, SLC_ServerId, IsProcessed, Archive_ServerId)  
-- SELECT AP.SLC_CustomerId, AP.SLC_UserId, AP.SLC_ArchiveProjectId, AP.SLC_ProdProjectId AS OldSLC_ProjectID, AP.SLC_ServerId, 0 AS IsProcessed, AP.Archive_ServerId  
-- FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] AP WITH (NOLOCK)  
-- INNER JOIN [SLCADMIN].[Authentication].[dbo].[CustomerTenantDbServer] CS ON CS.CustomerId = AP.SLC_CustomerId   
--  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
-- WHERE AP.InProgressStatusId = 3 --UnArchiveInitiated  
--  AND AP.ProcessInitiatedById = 3 --SLC  
--  AND AP.DisplayTabId = 2 --ArchivedTab  
--  AND AP.IsArchived = 1  
--  AND AP.SLC_ServerId IN (SELECT TenantDbServerId FROM [SLCADMIN].[Authentication].[dbo].[LuTenantDbServer] WHERE ServerName IN (Select SERVERPROPERTY('MachineName') as 'MachineName'))  
  
-- -- Get the number of records in the temporary table  
-- SET @NumberRecords = @@ROWCOUNT  
-- SET @RowCount = 1  
  
-- -- loop through all records in the temporary table using the WHILE loop construct  
-- WHILE @RowCount <= @NumberRecords  
-- BEGIN  
  
--  --Set IsProjectMigrationFailed to 0 to reset it  
--  SET @IsProjectMigrationFailed = 0  
--  SET @RequestId = 0  
  
--  DECLARE @OldSLC_ProjectID INT = 0  
  
--  DECLARE @CustomerID INT, @SubscriptionID INT, @SLE_ProjectID INT, @MigrateStatus INT, @MigratedDate DATETIME, @SLC_CustomerId INT, @SLC_UserId INT, @ProjectID INT, @IsProcessed INT, @CycleID BIGINT = 0  
--   , @SLC_ServerId INT, @Archive_ServerId INT  
--  --Get next CycleID  
--  SELECT @SLC_CustomerId = SLC_CustomerId, @SLC_UserId = SLC_UserId, @ProjectID = SLC_ArchiveProjectId, @OldSLC_ProjectID = OldSLC_ProjectID, @SLC_ServerId = SLC_ServerId, @IsProcessed = IsProcessed  
--   ,@Archive_ServerId = Archive_ServerId  
--  FROM #tmpUnArchiveCycleIDs WHERE RowID = @RowCount AND IsProcessed = 0  
  
--  --Call Unarchive Project for SLC Project procedure depend on the ArchiveServer mapping  
--  IF @Archive_ServerId = 1  
--  BEGIN  
--   EXECUTE [SLCProject].[dbo].[sp_UnArchiveProject_ArchServer01] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
--  END  
--  ELSE IF @Archive_ServerId = 2  
--  BEGIN  
--   EXECUTE [SLCProject].[dbo].[sp_UnArchiveProject_ArchServer02] @SLC_CustomerId, @SLC_UserId, @ProjectID, @OldSLC_ProjectID, @Archive_ServerId  
--  END  
  
--  --Update Processed to 1  
--  UPDATE A  
--  SET A.IsProcessed = 1  
--  FROM #tmpUnArchiveCycleIDs A  
--  WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID;  
  
--  SET @RowCount = @RowCount + 1  
-- END  
  
-- DROP TABLE #tmpUnArchiveCycleIDs  
  
--END
--GO
--PRINT N'Altering [dbo].[sp_UnArchiveProject_ArchServer01]...';


--GO


--ALTER PROCEDURE [dbo].[sp_UnArchiveProject_ArchServer01]
--(
--	@PSLC_CustomerId		INT
--	,@PSLC_UserId			INT
--	,@PProjectID			INT
--	,@POldSLC_ProjectID		INT
--	,@PArchive_ServerId		INT
--)
--AS
--BEGIN

--	--Handled Parameter Sniffing here
--	DECLARE @SLC_CustomerId INT
--	SET @SLC_CustomerId = @PSLC_CustomerId
--	DECLARE @SLC_UserId INT
--	SET @SLC_UserId = @PSLC_UserId
--	DECLARE @ProjectID INT
--	SET @ProjectID = @PProjectID
--	DECLARE @OldSLC_ProjectID INT
--	SET @OldSLC_ProjectID = @POldSLC_ProjectID
--	DECLARE @Archive_ServerId INT
--	SET @Archive_ServerId = @PArchive_ServerId

--	DECLARE @ErrorCode INT = 0
--	DECLARE @Return_Message VARCHAR(1024)
--	DECLARE @ErrorStep VARCHAR(50)
--	DECLARE @NumberRecords int, @RowCount int
--	DECLARE @RequestId AS INT

--	DECLARE @IsProjectMigrationFailed AS INT = 0
--	DECLARE @IsRestoreDeleteFailed AS INT = 0

--	--Set IsProjectMigrationFailed to 0 to reset it
--	SET @IsProjectMigrationFailed = 0
--	SET @RequestId = 0

--	--Drop all Temp Tables
--	DROP TABLE IF EXISTS #NewOldSectionIdMappingSLC;
--	DROP TABLE IF EXISTS #NewOldSegmentStatusIdMappingSLC;
--	DROP TABLE IF EXISTS #TGTProImgSLC;
--	DROP TABLE IF EXISTS #tmp_TgtSectionSLC;
--	DROP TABLE IF EXISTS #tmp_TgtSegmentStatusSLC;
--	DROP TABLE IF EXISTS #tmpProjectGlobalTermSLC;
--	DROP TABLE IF EXISTS #tmpProjectHyperLinkSLC;
--	DROP TABLE IF EXISTS #tmpProjectImageSLC;
--	DROP TABLE IF EXISTS #tmpProjectNoteSLC;
--	DROP TABLE IF EXISTS #tmpProjectNoteImageSLC;
--	DROP TABLE IF EXISTS #tmpProjectSectionSLC;
--	DROP TABLE IF EXISTS #ProjectSegment_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;
--	DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;
--	DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;
--	DROP TABLE IF EXISTS #tmpProjectSegmentSLC;
--	DROP TABLE IF EXISTS #tmpProjectSegmentChoiceSLC;
--	DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;
--	DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;
--	DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;
--	DROP TABLE IF EXISTS #ProjectHyperLink_Staging;
--	DROP TABLE IF EXISTS #ProjectNote_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;
--	DROP TABLE IF EXISTS #ProjectNoteImage_Staging;
--	DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;
--	DROP TABLE IF EXISTS #SegmentComment_Staging;
--	DROP TABLE IF EXISTS #TrackAcceptRejectProjectSegmentHistory_Staging;
--	DROP TABLE IF EXISTS #TrackProjectSegment_Staging;
--	DROP TABLE IF EXISTS #tmpProjectSegmentStatusSLC;
--	DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;
--	DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;
--	DROP TABLE IF EXISTS #MaterialSection_Staging;
--	DROP TABLE IF EXISTS #LinkedSections_Staging;
--	DROP TABLE IF EXISTS #tmpSectionLevelTrackChangesLoggingSLC;
--	DROP TABLE IF EXISTS #tmpTrackAcceptRejectHistorySLC;

--	--UnArchive Project Data

--	DECLARE @New_ProjectID AS INT, @IsOfficeMaster AS INT, @ProjectAccessTypeId AS INT, @ProjectOwnerId AS INT
--	DECLARE @OldCount AS INT = 0, @NewCount AS INT = 0, @StepName AS NVARCHAR(100), @Description AS NVARCHAR(500), @Step AS NVARCHAR(100)

--	DECLARE @Records INT = 1; 
--	DECLARE @TableRows INT;
--	DECLARE @Section_BatchSize INT;
--	DECLARE @Segment_BatchSize INT;
--	DECLARE @SegmentStatus_BatchSize INT;
--	DECLARE @ProjectSegmentChoice_BatchSize INT;
--	DECLARE @ProjectChoiceOption_BatchSize INT;
--	DECLARE @SelectedChoiceOption_BatchSize INT;
--	DECLARE @ProjectHyperLink_BatchSize INT;
--	DECLARE @ProjectNote_BatchSize INT;
--	DECLARE @ProjectSegmentLink_BatchSize INT;
--	DECLARE @Start INT = 1;
--	DECLARE @End INT;
--	DECLARE @StartTime AS DATETIME = GETUTCDATE()
--	DECLARE @EndTime AS DATETIME = GETUTCDATE()

--	BEGIN TRY
		
--		IF(EXISTS(SELECT TOP 1 1 FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK) WHERE Servername=@@servername))
--		BEGIN
--			SELECT TOP 1 @Section_BatchSize=ProjectSection,
--				@SegmentStatus_BatchSize=ProjectSegmentStatus,
--				@Segment_BatchSize =ProjectSegment,
--				@ProjectSegmentChoice_BatchSize =ProjectSegmentChoice,
--				@ProjectChoiceOption_BatchSize =ProjectChoiceOption,
--				@SelectedChoiceOption_BatchSize =SelectedChoiceOption,
--				@ProjectSegmentLink_BatchSize =ProjectSegmentLink,
--				@ProjectHyperLink_BatchSize =ProjectHyperLink,
--				@ProjectNote_BatchSize =ProjectNote
--				FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK)
--				WHERE Servername=@@servername
--		END
--		ELSE
--		BEGIN
--			SELECT TOP 1 @Section_BatchSize=ProjectSection,
--				@SegmentStatus_BatchSize=ProjectSegmentStatus,
--				@Segment_BatchSize =ProjectSegment,
--				@ProjectSegmentChoice_BatchSize =ProjectSegmentChoice,
--				@ProjectChoiceOption_BatchSize =ProjectChoiceOption,
--				@SelectedChoiceOption_BatchSize =SelectedChoiceOption,
--				@ProjectSegmentLink_BatchSize =ProjectSegmentLink,
--				@ProjectHyperLink_BatchSize =ProjectHyperLink,
--				@ProjectNote_BatchSize =ProjectNote
--				FROM SLCMaster.dbo.LuTableInsertBatchSize WITH(NOLOCK)
--				WHERE Servername IS NULL
--		END

--		--Update previousely migrated projects A_ProjectId to NULL so it wont duplicate the records in other child tables.
--		UPDATE P
--		SET P.A_ProjectId = NULL, P.ModifiedDate = GETUTCDATE()
--		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		WHERE P.A_ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId;

--		--Move Project table
--		--Insert
--		INSERT INTO [SLCProject].[dbo].[Project]
--		([Name], IsOfficeMaster, [Description], TemplateId, MasterDataTypeId, UserId, CustomerId, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, IsDeleted, IsNamewithHeld
--			,IsMigrated, IsLocked, A_ProjectId, IsProjectMoved, [GlobalProjectID], [IsPermanentDeleted], [ModifiedByFullName], [MigratedDate], [IsArchived], [IsShowMigrationPopup]
--			,[LockedBy],[LockedDate],[LockedById],[IsIncomingProject],[TransferredDate])
--		SELECT
--			S.[Name], S.IsOfficeMaster, S.[Description], S.TemplateId, S.MasterDataTypeId, S.UserId, S.CustomerId, S.CreateDate, S.CreatedBy
--			,S.ModifiedBy, S.ModifiedDate, S.IsDeleted, S.IsNamewithHeld, S.IsMigrated, S.IsLocked, S.ProjectId AS A_ProjectId, 0 AS IsProjectMoved
--			,S.GlobalProjectID AS [GlobalProjectID], S.[IsPermanentDeleted], S.[ModifiedByFullName], S.[MigratedDate], S.[IsArchived], S.IsShowMigrationPopup
--			,S.[LockedBy], S.[LockedDate], S.[LockedById], S.[IsIncomingProject], S.[TransferredDate]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT @New_ProjectID = ProjectId, @IsOfficeMaster = IsOfficeMaster FROM [SLCProject].[dbo].[Project] WITH (NOLOCK) WHERE CustomerId = @SLC_CustomerId AND A_ProjectId = @ProjectID

--		--Set IsDeleted flag to 1 for a temporary basis until whole project is Unarchived
--		UPDATE P
--		SET P.IsDeleted = 1, P.ModifiedDate = GETUTCDATE()
--		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		WHERE P.ProjectId = @New_ProjectID;

			
--		SELECT @RequestId = RequestId FROM [SLCProject].[dbo].[UnArchiveProjectRequest] WITH (NOLOCK)
--		WHERE [SLC_CustomerId] = @SLC_CustomerId AND [SLC_ArchiveProjectId] = @ProjectID
--			AND [StatusId] = 1 --StatusId 1 as Queued

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'New Project created', 'New Project created', '1', 3, @OldCount, @NewCount

--		--Move ProjectAddress table
--		INSERT INTO [SLCProject].[dbo].[ProjectAddress]
--		(ProjectId, CustomerId, AddressLine1, AddressLine2, CountryId, StateProvinceId, CityId, PostalCode, CreateDate, CreatedBy, ModifiedBy
--			,ModifiedDate, StateProvinceName, CityName)
--		SELECT @New_ProjectID AS ProjectId, S.CustomerId, S.AddressLine1, S.AddressLine2, S.CountryId, S.StateProvinceId, S.CityId, S.PostalCode
--			,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.StateProvinceName, S.CityName
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectAddress] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectAddress created', 'ProjectAddress created', '2', 5, @OldCount, @NewCount

			
--		--Move UserFolder table
--		INSERT INTO [SLCProject].[dbo].[UserFolder]
--		(FolderTypeId, ProjectId, UserId, LastAccessed, CustomerId, LastAccessByFullName)
--		SELECT S.FolderTypeId, @New_ProjectID AS ProjectId, S.UserId, S.LastAccessed, S.CustomerId, S.LastAccessByFullName
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[UserFolder] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

		
--		EXECUTE [SLCProject].[dbo].[usp_GetMigratedProjectDefaultPrivacySetting] @SLC_CustomerId, @SLC_UserId, @IsOfficeMaster, @ProjectAccessTypeId OUTPUT, @ProjectOwnerId OUTPUT

--		--Move ProjectSummary table
--		INSERT INTO [SLCProject].[dbo].[ProjectSummary]
--		([ProjectId],[CustomerId],[UserId],[ProjectTypeId],[FacilityTypeId],[SizeUoM],[IsIncludeRsInSection],[IsIncludeReInSection]
--			,[SpecViewModeId],[UnitOfMeasureValueTypeId],[SourceTagFormat],[IsPrintReferenceEditionDate],[IsActivateRsCitation],[LastMasterUpdate]
--			,[BudgetedCostId],[BudgetedCost],[ActualCost],[EstimatedArea],[SpecificationIssueDate],[SpecificationModifiedDate],[ActualCostId]
--			,[ActualSizeId],[EstimatedSizeId],[EstimatedSizeUoM],[Cost],[Size],[ProjectAccessTypeId],[OwnerId],[TrackChangesModeId])
--		SELECT @New_ProjectID AS ProjectId,S.[CustomerId],S.[UserId],S.[ProjectTypeId],S.[FacilityTypeId],S.[SizeUoM],S.[IsIncludeRsInSection],S.[IsIncludeReInSection]
--			,S.[SpecViewModeId],S.[UnitOfMeasureValueTypeId],S.[SourceTagFormat],S.[IsPrintReferenceEditionDate],S.[IsActivateRsCitation],S.[LastMasterUpdate]
--			,S.[BudgetedCostId],S.[BudgetedCost],S.[ActualCost],S.[EstimatedArea],S.[SpecificationIssueDate],S.[SpecificationModifiedDate],S.[ActualCostId]
--			,S.[ActualSizeId],S.[EstimatedSizeId],S.[EstimatedSizeUoM],S.[Cost],S.[Size]
--			,CASE WHEN S.[ProjectAccessTypeId] IS NULL THEN @ProjectAccessTypeId ELSE S.[ProjectAccessTypeId] END AS [ProjectAccessTypeId]
--			,CASE WHEN S.[OwnerId] IS NULL THEN @ProjectOwnerId ELSE S.[OwnerId] END AS [OwnerId],S.[TrackChangesModeId]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSummary] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSummary created', 'ProjectSummary created', '3', 7, @OldCount, @NewCount

			
--		--Move ProjectPageSetting table
--		INSERT INTO [SLCProject].[dbo].[ProjectPageSetting]
--		([MarginTop],[MarginBottom],[MarginLeft],[MarginRight],[EdgeHeader],[EdgeFooter],[IsMirrorMargin],[ProjectId],[CustomerId])
--		SELECT S.[MarginTop],S.[MarginBottom],S.[MarginLeft],S.[MarginRight],S.[EdgeHeader],S.[EdgeFooter],S.[IsMirrorMargin]
--			,@New_ProjectID AS [ProjectId],S.[CustomerId]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPageSetting] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPageSetting created', 'ProjectPageSetting created', '4', 10, @OldCount, @NewCount

			
--		--Move ProjectPaperSetting table
--		INSERT INTO [SLCProject].[dbo].[ProjectPaperSetting]
--		(PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId)
--		SELECT S.PaperName, S.PaperWidth, S.PaperHeight, S.PaperOrientation, S.PaperSource, @New_ProjectID AS ProjectId, S.CustomerId
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPaperSetting] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPaperSetting created', 'ProjectPaperSetting created', '5', 12, @OldCount, @NewCount

			
--		--Move ProjectPaperSetting table
--		INSERT INTO [SLCProject].[dbo].[ProjectPrintSetting]
--		([ProjectId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsExportInMultipleFiles],[IsBeginSectionOnOddPage]
--			,[IsIncludeAuthorInFileName],[TCPrintModeId],[IsIncludePageCount],[IsIncludeHyperLink],[KeepWithNext],[IsPrintMasterNote],[IsPrintProjectNote],[IsPrintNoteImage],[IsPrintIHSLogo])
--		SELECT @New_ProjectID AS [ProjectId],S.[CustomerId],S.[CreatedBy],S.[CreateDate],S.[ModifiedBy],S.[ModifiedDate],S.[IsExportInMultipleFiles],S.[IsBeginSectionOnOddPage]
--			,S.[IsIncludeAuthorInFileName],S.[TCPrintModeId], S.[IsIncludePageCount], S.IsIncludeHyperLink, S.KeepWithNext, S.[IsPrintMasterNote],S.[IsPrintProjectNote],S.[IsPrintNoteImage],S.[IsPrintIHSLogo]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectPrintSetting] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

			
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectPrintSetting created', 'ProjectPrintSetting created', '6', 15, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SELECT ROW_NUMBER() OVER(ORDER BY S.SectionId) AS RowNumber, S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
--				,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
--				,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
--				,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
--		INTO #tmp_TgtSectionSLC
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT
--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @Section_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			INSERT INTO [SLCProject].[dbo].[ProjectSection]
--			(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
--				,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
--				,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
--				,TrackChangeLockedBy, DataMapDateTimeStamp)
--			SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
--					,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
--					,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
--					,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
--			FROM #tmp_TgtSectionSLC S
--			WHERE RowNumber BETWEEN @Start AND @End
 
--			SET @Records += @Section_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @Section_BatchSize - 1;
--		END

--		--SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
--		--		,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
--		--		,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
--		--		,S.SectionId AS A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
--		--INTO #tmp_TgtSectionSLC
--		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSection] S WITH (NOLOCK)
--		--WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--INSERT INTO [SLCProject].[dbo].[ProjectSection]
--		--(ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode, [Description], LevelId, IsLastLevel, SourceTag, Author
--		--	,TemplateId, SectionCode, IsDeleted, IsLocked, LockedBy, LockedByFullName, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, FormatTypeId
--		--	,SLE_FolderID, SLE_ParentID, SLE_DocID, SpecViewModeId, A_SectionId, IsLockedImportSection, IsTrackChanges, IsTrackChangeLock
--		--	,TrackChangeLockedBy, DataMapDateTimeStamp)
--		--SELECT S.ParentSectionId, S.mSectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.UserId, S.DivisionId, S.DivisionCode, S.[Description]
--		--		,S.LevelId, S.IsLastLevel, S.SourceTag, S.Author, S.TemplateId, S.SectionCode, S.IsDeleted, S.IsLocked, S.LockedBy, S.LockedByFullName
--		--		,S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.FormatTypeId, S.SLE_FolderID, S.SLE_ParentID, S.SLE_DocID, S.SpecViewModeId
--		--		,A_SectionId, S.IsLockedImportSection, S.IsTrackChanges, S.IsTrackChangeLock, S.TrackChangeLockedBy, S.DataMapDateTimeStamp
--		--FROM #tmp_TgtSectionSLC S

--		SELECT SectionId, ParentSectionId, ProjectId, CustomerId, A_SectionId INTO #tmpProjectSectionSLC
--		FROM [SLCProject].[dbo].[ProjectSection] WITH (NOLOCK) WHERE ProjectId = @New_ProjectID AND CustomerId = @SLC_CustomerId

--		SELECT ProjectId, CustomerId, SectionId, A_SectionId INTO #NewOldSectionIdMappingSLC FROM #tmpProjectSectionSLC

--		--UPDATE ParentSectionId in TGT Section table                  
--		UPDATE TGT_TMP SET TGT_TMP.ParentSectionId = NOSM.SectionId
--		FROM #tmpProjectSectionSLC TGT_TMP
--		INNER JOIN #NewOldSectionIdMappingSLC NOSM ON TGT_TMP.ParentSectionId = NOSM.A_SectionId
--		WHERE TGT_TMP.ProjectId = @New_ProjectID;
			
--		--UPDATE ParentSectionId in original table                  
--		UPDATE PS SET PS.ParentSectionId = PS_TMP.ParentSectionId
--		FROM [SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSectionSLC PS_TMP ON PS.SectionId = PS_TMP.SectionId
--		WHERE PS.ProjectId = @New_ProjectID AND PS.CustomerId = @SLC_CustomerId;

--		DROP TABLE IF EXISTS #tmp_TgtSectionSLC;
--		DROP TABLE IF EXISTS #NewOldSectionIdMappingSLC;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSection created', 'ProjectSection created', '7', 17, @OldCount, @NewCount

--		SET @OldCount = 0

--		--DELETE FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection]
--		--WHERE ProjectId = @ProjectID AND CustomerId = @SLC_CustomerId

--		--INSERT INTO [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection]
--		--(SectionId, ProjectId, CustomerId)
--		--SELECT PS.SectionId, PS.ProjectId, PS.CustomerId
--		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSection] PS WITH (NOLOCK)
--		--WHERE PS.ProjectId = @ProjectID AND PS.CustomerId = @SLC_CustomerId
--		--AND ISNULL(PS.IsDeleted, 0) = 0;

--		--Move ProjectGlobalTerm table
--		INSERT INTO [SLCProject].[dbo].[ProjectGlobalTerm]
--		([mGlobalTermId],[ProjectId],[CustomerId],[Name],[value],[GlobalTermSource],[GlobalTermCode],[CreatedDate],[CreatedBy],[ModifiedDate],[ModifiedBy]
--			,[SLE_GlobalChoiceID],[UserGlobalTermId],[IsDeleted],[A_GlobalTermId],[GlobalTermFieldTypeId],[OldValue])
--		SELECT S.mGlobalTermId, @New_ProjectID AS ProjectId, S.CustomerId, S.[Name], S.[value], S.GlobalTermSource, S.GlobalTermCode, S.CreatedDate, S.CreatedBy
--				,S.ModifiedDate, S.ModifiedBy, S.SLE_GlobalChoiceID, S.UserGlobalTermId, S.IsDeleted, S.GlobalTermId AS A_GlobalTermId, S.GlobalTermFieldTypeId, S.OldValue
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectGlobalTerm] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT P.GlobalTermId, P.CustomerId, P.ProjectId, P.UserGlobalTermId, P.GlobalTermCode, P.A_GlobalTermId INTO #tmpProjectGlobalTermSLC
--		FROM [SLCProject].[dbo].[ProjectGlobalTerm] P WITH (NOLOCK)
--		WHERE P.ProjectId = @ProjectID AND P.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectGlobalTerm created', 'ProjectGlobalTerm created', '8', 20, @OldCount, @NewCount

--		--Insert #tmpProjectImage table
--		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
--					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.[ImageId] AS A_ImageId
--		INTO #TGTProImgSLC
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectImage] SRC WITH (NOLOCK)
--		WHERE SRC.CustomerId = @SLC_CustomerId

--		--Update ProjectImage table
--		UPDATE TGT
--			SET TGT.[ImagePath] = SRC.[ImagePath], TGT.[LuImageSourceTypeId] = SRC.[LuImageSourceTypeId],TGT.[CreateDate] = SRC.[CreateDate]
--				,TGT.[ModifiedDate] = SRC.[ModifiedDate],TGT.[SLE_ProjectID] = SRC.[SLE_ProjectID],TGT.[SLE_DocID] = SRC.[SLE_DocID]
--				,TGT.[SLE_StatusID] = SRC.[SLE_StatusID],TGT.[SLE_SegmentID] = SRC.[SLE_SegmentID],TGT.[SLE_ImageNo] = SRC.[SLE_ImageNo]
--				,TGT.[SLE_ImageID] = SRC.[SLE_ImageID],TGT.[A_ImageId] = SRC.A_ImageId
--		FROM [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK)
--		INNER JOIN #TGTProImgSLC SRC
--			ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND SRC.CustomerId = @SLC_CustomerId
--		WHERE TGT.CustomerId = @SLC_CustomerId

--		--Insert ProjectImage table
--		INSERT INTO [SLCProject].[dbo].[ProjectImage]
--		([ImagePath],[LuImageSourceTypeId],[CreateDate],[ModifiedDate],[CustomerId],[SLE_ProjectID],[SLE_DocID],[SLE_StatusID],[SLE_SegmentID]
--			,[SLE_ImageNo],[SLE_ImageID],[A_ImageId])
--		SELECT SRC.[ImagePath],SRC.[LuImageSourceTypeId],SRC.[CreateDate],SRC.[ModifiedDate],SRC.[CustomerId],SRC.[SLE_ProjectID],SRC.[SLE_DocID]
--					,SRC.[SLE_StatusID],SRC.[SLE_SegmentID],SRC.[SLE_ImageNo],SRC.[SLE_ImageID],SRC.A_ImageId
--		FROM #TGTProImgSLC SRC
--		LEFT OUTER JOIN [SLCProject].[dbo].[ProjectImage] TGT WITH (NOLOCK) ON TGT.CustomerId = SRC.CustomerId AND TGT.ImagePath = SRC.ImagePath AND TGT.CustomerId = @SLC_CustomerId
--		WHERE SRC.CustomerId = @SLC_CustomerId AND TGT.ImagePath IS NULL

--		SELECT I.ImageId, I.CustomerId, I.ImagePath, I.A_ImageId INTO #tmpProjectImageSLC
--		FROM [SLCProject].[dbo].[ProjectImage] I WITH (NOLOCK) WHERE I.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #TGTProImgSLC;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectImage created', 'ProjectImage created', '9', 22, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Move ProjectSegment_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentId) AS RowNumber, S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
--				,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
--		INTO #ProjectSegment_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
--		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
--		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId --AND S.CustomerId = PSC.CustomerId
--		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment Staging Loaded', 'ProjectSegment Staging Loaded', '10', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @Segment_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Insert ProjectSegment Table
--			INSERT INTO [SLCProject].[dbo].[ProjectSegment]
--			(SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID
--				,SLE_SegmentID, SLE_StatusID, A_SegmentId, IsDeleted, BaseSegmentDescription)
--			SELECT NULL AS SegmentStatusId, S2.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
--					,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
--			FROM #ProjectSegment_Staging S
--			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
--				AND S.SectionId = S2.A_SectionId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @Segment_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @Segment_BatchSize - 1;
--		END

--		----Insert ProjectSegment Table
--		--INSERT INTO [SLCProject].[dbo].[ProjectSegment]
--		--(SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, SLE_DocID
--		--	,SLE_SegmentID, SLE_StatusID, A_SegmentId, IsDeleted, BaseSegmentDescription)
--		--SELECT NULL AS SegmentStatusId, S2.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
--		--		,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
--		--FROM #ProjectSegment_Staging S
--		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
--		--	AND S.SectionId = S2.A_SectionId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment Records Added', 'ProjectSegment Records Added', '10', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		----Move ProjectSegment_Staging table
--		--SELECT S.SegmentId, NULL AS SegmentStatusId, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentDescription, S.SegmentSource, S.SegmentCode, S.CreatedBy, S.CreateDate
--		--		,S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SegmentId AS A_SegmentId, S.IsDeleted, S.BaseSegmentDescription
--		--INTO #ProjectSegment_Staging
--		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
--		----INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
--		----	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId --AND S.CustomerId = PSC.CustomerId
--		--WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId


--		SELECT S.SegmentId, S.SegmentStatusId, S.SegmentSource, S.SegmentCode, S.SectionId, S.ProjectId, S.CustomerId, S.SegmentDescription, S.A_SegmentId
--		INTO #tmpProjectSegmentSLC FROM [SLCProject].[dbo].[ProjectSegment] S WITH (NOLOCK)
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegment_Staging;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegment created', 'ProjectSegment created', '10', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Insert #tmp_TgtSegmentStatusSLC table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentStatusId) AS RowNumber, S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
--			,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
--			,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
--			,S.SLE_ProjectSegID, S.SLE_StatusID, S.SegmentStatusId AS A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
--		INTO #tmp_TgtSegmentStatusSLC
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectId AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentStatus Staging Loaded', 'ProjectSegmentStatus Staging Loaded', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Update SectionId in ProjectSegmentStatus table
--		UPDATE S
--			SET S.SectionId = S1.SectionId
--		FROM #tmp_TgtSegmentStatusSLC S
--		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
--			AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SectionId Updated in ProjectSegmentStatus Staging', 'SectionId Updated in ProjectSegmentStatus Staging', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Update SegmentId in ProjectSegmentStatus table
--		UPDATE S
--			SET S.SegmentId = S1.SegmentId
--		FROM #tmp_TgtSegmentStatusSLC S
--		INNER JOIN #tmpProjectSegmentSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId
--			AND S.SectionId = S1.SectionId AND S.SegmentId = S1.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SegmentId Updated in ProjectSegmentStatus Staging', 'SegmentId Updated in ProjectSegmentStatus Staging', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @SegmentStatus_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectSegmentStatus table
--			INSERT INTO [dbo].[ProjectSegmentStatus]
--			(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
--				,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
--				,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
--				,IsDeleted, TrackOriginOrder, MTrackDescription)
--			SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
--				,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, S.ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
--				,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
--				,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
--			FROM #tmp_TgtSegmentStatusSLC S
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @SegmentStatus_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @SegmentStatus_BatchSize - 1;
--		END

--		----Move ProjectSegmentStatus table
--		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentStatus]
--		--(SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId
--		--	,SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId, SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson
--		--	,CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsPageBreak, SLE_DocID, SLE_ParentID, SLE_SegmentID, SLE_ProjectSegID, SLE_StatusID, A_SegmentStatusId
--		--	,IsDeleted, TrackOriginOrder, MTrackDescription)
--		--SELECT S.SectionId, S.ParentSegmentStatusId, S.mSegmentStatusId, S.mSegmentId, S.SegmentId, S.SegmentSource, S.SegmentOrigin, S.IndentLevel, S.SequenceNumber
--		--	,S.SpecTypeTagId, S.SegmentStatusTypeId, S.IsParentSegmentStatusActive, S.ProjectId, S.CustomerId, S.SegmentStatusCode, S.IsShowAutoNumber
--		--	,S.IsRefStdParagraph, S.FormattingJson, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsPageBreak, S.SLE_DocID, S.SLE_ParentID, S.SLE_SegmentID
--		--	,S.SLE_ProjectSegID, S.SLE_StatusID, S.A_SegmentStatusId, S.IsDeleted, S.TrackOriginOrder, S.MTrackDescription
--		--FROM #tmp_TgtSegmentStatusSLC S

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Records Inserted ProjectSegmentStatus', 'Records Inserted ProjectSegmentStatus', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SELECT S.* INTO #tmpProjectSegmentStatusSLC FROM [SLCProject].[dbo].[ProjectSegmentStatus] S WITH (NOLOCK)
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT SegmentStatusId, A_SegmentStatusId INTO #NewOldSegmentStatusIdMappingSLC
--		FROM #tmpProjectSegmentStatusSLC S

--		DROP TABLE IF EXISTS #tmp_TgtSegmentStatusSLC;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table created for ProjectSegmentStatus', 'Temp Table created for ProjectSegmentStatus', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--UPDATE ParentSegmentStatusId in temp table
--		UPDATE CPSST
--		SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId
--		FROM #tmpProjectSegmentStatusSLC CPSST
--		INNER JOIN #NewOldSegmentStatusIdMappingSLC PPSST
--			ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId AND CPSST.ParentSegmentStatusId <> 0

--		DROP TABLE IF EXISTS #NewOldSegmentStatusIdMappingSLC;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table - Updated ParentSegmentStatusId', 'Temp Table - Updated ParentSegmentStatusId', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--UPDATE ParentSegmentStatusId in original table
--		UPDATE PSS
--		SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId
--		FROM [dbo].[ProjectSegmentStatus] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegmentStatusSLC PSS_TMP ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId AND PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId
--		WHERE PSS.SegmentStatusId = PSS_TMP.SegmentStatusId AND PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ParentSegmentStatusId in Original Table', 'ParentSegmentStatusId in Original Table', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Update SegmentStatusId in #tmpProjectSegment
--		UPDATE PS
--			SET PS.SegmentStatusId = SS.SegmentStatusId
--		FROM #tmpProjectSegmentSLC PS
--		INNER JOIN #tmpProjectSegmentStatusSLC SS ON SS.ProjectId = PS.ProjectId AND SS.CustomerId = PS.CustomerId
--			AND SS.SectionId = PS.SectionId AND SS.SegmentId = PS.SegmentId
--		WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table - Updated SegmentStatusId', 'Temp Table - Updated SegmentStatusId', '11', 25, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--UPDATE SegmentStatusId in original table
--		UPDATE PSS
--		SET PSS.SegmentStatusId = PSS_TMP.SegmentStatusId
--		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId;

--		----RefStdCode need NOT be updated because there is no difference between RefStdCode on any of the SLC Servers

--		------Update SegmentDescription for ReferenceStandard Paragraph with new tag {RSTEMP#[RefStdCode]} when it is Master RefStdCode
--		----UPDATE P
--		----SET P.SegmentDescription = ([DE_Projects_Staging].[dbo].[fn_ReplaceSLEPlaceHolder] (P.SegmentDescription, '{RSTEMP#', '{RSTEMP#'
--		----		, [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
--		----		, NEWRS.RefStdCode))
--		----FROM [SLCProject].[dbo].[ProjectSegment] P 
--		----INNER JOIN [SLCProject].[dbo].[ProjectSegmentStatus] PS WITH (NOLOCK) ON PS.CustomerId = P.CustomerId AND PS.ProjectId = P.ProjectId AND PS.SectionId = P.SectionId
--		----	AND PS.SegmentId = P.SegmentId
--		----INNER JOIN [ARCHIVESERVER01].[SLCMaster].[dbo].[ReferenceStandard] OLDRS WITH (NOLOCK) ON OLDRS.MasterDataTypeId = 1 AND OLDRS.IsObsolete = 0
--		----	AND OLDRS.RefStdCode = [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription)
--		----INNER JOIN [SLCMaster].[dbo].[ReferenceStandard] NEWRS WITH (NOLOCK) ON NEWRS.RefStdName = OLDRS.RefStdName AND NEWRS.MasterDataTypeId = 1 AND NEWRS.IsObsolete = 0
--		----WHERE PS.CustomerId = @SLC_CustomerId AND PS.ProjectId = @New_ProjectID AND PS.IsRefStdParagraph = 1
--		----	AND [DE_Projects_Staging].[dbo].[fn_GetRESTempPlaceholder](P.SegmentDescription) < 10000000

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentStatus created', 'ProjectSegmentStatus created', '11', 27, @OldCount, @NewCount

--		SET @OldCount = 0

--		--SET @LogMessage = CHAR(13)+CHAR(10) + 'ProjectSegmentGlobalTerm'
--		--EXECUTE [DE_Projects_Staging].[dbo].[spb_UnArchiveLog] @SLC_CustomerId, @New_ProjectID, @LogMessage

--		--SELECT @OldCount = COUNT(9) FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] WITH (NOLOCK) WHERE CustomerID = @SLC_CustomerId AND ProjectId = @ProjectID
--		--IF @Row_Count > 0
--		--BEGIN
--		--	SET @LogMessage = CAST(@Row_Count AS VARCHAR) + ' OLD ProjectSegmentGlobalTerm records'
--		--	EXECUTE [DE_Projects_Staging].[dbo].[spb_UnArchiveLog] @SLC_CustomerId, @New_ProjectID, @LogMessage
--		--END

--		--Insert ProjectSegmentGlobalTerm_Staging table
--		SELECT S.SegmentGlobalTermId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentId, S.mSegmentId, G1.UserGlobalTermId, G1.GlobalTermCode, S.IsLocked
--			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		INTO #ProjectSegmentGlobalTerm_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentGlobalTerm] S WITH (NOLOCK)
--		LEFT JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectGlobalTerm] G WITH (NOLOCK) ON S.CustomerId = G.CustomerId AND G.UserGlobalTermId = S.UserGlobalTermId
--		LEFT JOIN #tmpProjectGlobalTermSLC G1 ON G1.CustomerId = G.CustomerId AND G1.A_GlobalTermId = G.GlobalTermId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentGlobalTerm table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentGlobalTerm]
--		(CustomerId, ProjectId, SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode, IsLocked, LockedByFullName, UserLockedId, CreatedDate, CreatedBy
--			,ModifiedDate, ModifiedBy, IsDeleted)
--		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentId, S.mSegmentId, S.UserGlobalTermId, S.GlobalTermCode, S.IsLocked
--			,S.LockedByFullName, S.UserLockedId, S.CreatedDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		FROM #ProjectSegmentGlobalTerm_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentId = S3.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #tmpProjectGlobalTermSLC;
--		DROP TABLE IF EXISTS #ProjectSegmentGlobalTerm_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentGlobalTerm created', 'ProjectSegmentGlobalTerm created', '12', 30, @OldCount, @NewCount

--		--Move Header table
--		INSERT INTO [SLCProject].[dbo].[Header]
--		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
--			,ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_HeaderId
--			,HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId, IsShowLineAboveHeader
--			,IsShowLineBelowHeader)
--		SELECT @New_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
--			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltHeader, S.FPHeader, S.UseSeparateFPHeader, S.HeaderFooterCategoryId
--			,S.[DateFormat], S.TimeFormat, S.HeaderId AS A_HeaderId, S.HeaderFooterDisplayTypeId, S.DefaultHeader, S.FirstPageHeader, S.OddPageHeader, S.EvenPageHeader
--			,S.DocumentTypeId, S.IsShowLineAboveHeader, S.IsShowLineBelowHeader
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Header] S WITH (NOLOCK)
--		LEFT JOIN #tmpProjectSectionSLC S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S2.A_SectionId = S.SectionId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Header created', 'Header created', '13', 32, @OldCount, @NewCount

--		--Move Footer table
--		INSERT INTO [SLCProject].[dbo].[Footer]
--		(ProjectId, SectionId, CustomerId, [Description], IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy
--			,ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId, [DateFormat], TimeFormat, A_FooterId
--			,HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId, IsShowLineAboveFooter
--			,IsShowLineBelowFooter)
--		SELECT @New_ProjectID AS ProjectId, S2.SectionId, S.CustomerId, S.[Description], S.IsLocked, S.LockedByFullName, S.LockedBy, S.ShowFirstPage
--			,S.CreatedBy, S.CreatedDate, S.ModifiedBy, S.ModifiedDate, S.TypeId, S.AltFooter, S.FPFooter, S.UseSeparateFPFooter, S.HeaderFooterCategoryId
--			,S.[DateFormat], S.TimeFormat, S.FooterId AS A_FooterId, S.HeaderFooterDisplayTypeId, S.DefaultFooter, S.FirstPageFooter, S.OddPageFooter, S.EvenPageFooter
--			,S.DocumentTypeId, S.IsShowLineAboveFooter, IsShowLineBelowFooter
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Footer] S WITH (NOLOCK)
--		LEFT JOIN #tmpProjectSectionSLC S2 ON S2.ProjectId = @New_ProjectID AND S2.CustomerId = @SLC_CustomerId AND S.SectionId = S2.A_SectionId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Footer created', 'Footer created', '14', 35, @OldCount, @NewCount

--		--Move HeaderFooterGlobalTermUsage_Staging table
--		SELECT S.HeaderFooterGTId, S.HeaderId, S.FooterId, G1.UserGlobalTermId, S.CustomerId, @New_ProjectID AS ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
--		INTO #HeaderFooterGlobalTermUsage_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[HeaderFooterGlobalTermUsage] S WITH (NOLOCK)
--		LEFT JOIN [SLCProject].[dbo].[UserGlobalTerm] G1 WITH (NOLOCK) ON G1.CustomerId = S.CustomerId AND G1.UserGlobalTermId = S.UserGlobalTermId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move HeaderFooterGlobalTermUsage table
--		INSERT INTO [SLCProject].[dbo].[HeaderFooterGlobalTermUsage]
--		(HeaderId, FooterId, UserGlobalTermId, CustomerId, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)
--		SELECT S2.HeaderId, S3.FooterId, S.UserGlobalTermId, S.CustomerId, S.ProjectId, S.HeaderFooterCategoryId, S.CreatedDate, S.CreatedById
--		FROM #HeaderFooterGlobalTermUsage_Staging S
--		LEFT JOIN [SLCProject].[dbo].[Header] S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.HeaderId = S2.A_HeaderId
--		LEFT JOIN [SLCProject].[dbo].[Footer] S3 WITH (NOLOCK) ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S.FooterId = S3.A_FooterId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #HeaderFooterGlobalTermUsage_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HeaderFooterGlobalTermUsage created', 'HeaderFooterGlobalTermUsage created', '15', 37, @OldCount, @NewCount

--		--Insert ProjectReferenceStandard_Staging table
--		SELECT @New_ProjectID AS ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
--			,S.SectionId, S.CustomerId, S.ProjRefStdId, S.IsDeleted
--		INTO #ProjectReferenceStandard_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectReferenceStandard] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectReferenceStandard table
--		INSERT INTO [SLCProject].[dbo].[ProjectReferenceStandard]
--		(ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId, IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)
--		SELECT S.ProjectId, S.RefStandardId, S.RefStdSource, S.mReplaceRefStdId, S.RefStdEditionId, S.IsObsolete, S.RefStdCode, S.PublicationDate
--			,S2.SectionId, S.CustomerId, S.IsDeleted
--		FROM #ProjectReferenceStandard_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId
						
--		DROP TABLE IF EXISTS #ProjectReferenceStandard_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectReferenceStandard created', 'ProjectReferenceStandard created', '16', 40, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Insert ProjectSegmentChoice_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.SegmentChoiceId, S.SectionId, S.SegmentStatusId, S.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
--				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
--				,S.SegmentChoiceId AS A_SegmentChoiceId, S.IsDeleted
--		INTO #ProjectSegmentChoice_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentChoice] S WITH (NOLOCK)
--		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK)
--		--	ON S.Sectionid = PSC.SectionId AND S.ProjectId = PSC.ProjectId AND S.CustomerId = PSC.CustomerId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice Staging Loaded', 'ProjectSegmentChoice Staging Loaded', '17', 42, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectSegmentChoice table
--			INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
--			(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--				,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
--			SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
--					,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
--					,S.A_SegmentChoiceId, S.IsDeleted
--			FROM #ProjectSegmentChoice_Staging S
--			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentStatusId = S3.A_SegmentStatusId
--			INNER JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--				AND S.SegmentId = S4.A_SegmentId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectSegmentChoice_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectSegmentChoice_BatchSize - 1;
--		END

--		----Move ProjectSegmentChoice table
--		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentChoice]
--		--(SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--		--	,SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_ChoiceNo, SLE_ChoiceTypeID, A_SegmentChoiceId, IsDeleted)
--		--SELECT S2.SectionId, S3.SegmentStatusId, S4.SegmentId, S.ChoiceTypeId, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentChoiceSource, S.SegmentChoiceCode
--		--		,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_ChoiceNo, S.SLE_ChoiceTypeID
--		--		,S.A_SegmentChoiceId, S.IsDeleted
--		--FROM #ProjectSegmentChoice_Staging S
--		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
--		--INNER JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--		--	AND S.SegmentId = S4.A_SegmentId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice Records Inserted', 'ProjectSegmentChoice Records Inserted', '17', 42, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SELECT C.SegmentChoiceId, C.ProjectId, C.SectionId, C.CustomerId, C.A_SegmentChoiceId INTO #tmpProjectSegmentChoiceSLC FROM [SLCProject].[dbo].[ProjectSegmentChoice] C WITH (NOLOCK)
--		WHERE C.ProjectId = @New_ProjectID AND C.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentChoice_Staging;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentChoice created', 'ProjectSegmentChoice created', '17', 42, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Insert ProjectChoiceOption_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentChoiceId) AS RowNumber, S.ChoiceOptionId, S.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, @New_ProjectID AS ProjectId, S.SectionId, S.CustomerId, S.ChoiceOptionCode
--			,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.ChoiceOptionId AS A_ChoiceOptionId, S.IsDeleted
--		INTO #ProjectChoiceOption_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectChoiceOption] S WITH (NOLOCK)
--		--INNER JOIN [ARCHIVESERVER01].[SLCProject].[dbo].[Staging_ProjectSection] PSC WITH (NOLOCK) 
--		--	ON S.ProjectId = PSC.ProjectId AND S.Sectionid = PSC.SectionId AND S.CustomerId = PSC.CustomerId
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectChoiceOption Staging Loaded', 'ProjectChoiceOption Staging Loaded', '18', 45, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectChoiceOption_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectChoiceOption table
--			INSERT INTO [SLCProject].[dbo].[ProjectChoiceOption]
--			(SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--				,A_ChoiceOptionId, IsDeleted)
--			SELECT S3.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, S.ProjectId, S2.SectionId, S.CustomerId, S.ChoiceOptionCode
--				,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.A_ChoiceOptionId, S.IsDeleted
--			FROM #ProjectChoiceOption_Staging S
--			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentChoiceSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentChoiceId = S3.A_SegmentChoiceId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectChoiceOption_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectChoiceOption_BatchSize - 1;
--		END
		
--		----Move ProjectChoiceOption table
--		--INSERT INTO [SLCProject].[dbo].[ProjectChoiceOption]
--		--(SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate
--		--	,A_ChoiceOptionId, IsDeleted)
--		--SELECT S3.SegmentChoiceId, S.SortOrder, S.ChoiceOptionSource, S.OptionJson, S.ProjectId, S2.SectionId, S.CustomerId, S.ChoiceOptionCode
--		--	,S.CreatedBy, S.CreateDate, S.ModifiedBy, S.ModifiedDate, S.A_ChoiceOptionId, S.IsDeleted
--		--FROM #ProjectChoiceOption_Staging S
--		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentChoiceSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentChoiceId = S3.A_SegmentChoiceId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #tmpProjectSegmentChoiceSLC;
--		DROP TABLE IF EXISTS #ProjectChoiceOption_Staging;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectChoiceOption created', 'ProjectChoiceOption created', '18', 45, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Insert SelectedChoiceOption_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SelectedChoiceOptionId) AS RowNumber, S.SelectedChoiceOptionId, S.SegmentChoiceCode, S.ChoiceOptionCode
--				,S.ChoiceOptionSource, S.IsSelected, S.SectionId, @New_ProjectID AS ProjectId, S.CustomerId
--				,S.OptionJson, S.IsDeleted
--		INTO #SelectedChoiceOption_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SelectedChoiceOption] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = 0
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)
		
--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SelectedChoiceOption Staging Loaded', 'SelectedChoiceOption Staging Loaded', '19', 47, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @SelectedChoiceOption_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move SelectedChoiceOption table
--			INSERT INTO [SLCProject].[dbo].[SelectedChoiceOption]
--			(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
--			SELECT S.SegmentChoiceCode, S.ChoiceOptionCode, S.ChoiceOptionSource, S.IsSelected, S2.SectionId, S.ProjectId, S.CustomerId, S.OptionJson, S.IsDeleted
--			FROM #SelectedChoiceOption_Staging S
--			INNER JOIN #tmpProjectSectionSLC S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
--			WHERE S.SectionId = S2.A_SectionId AND S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @SelectedChoiceOption_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @SelectedChoiceOption_BatchSize - 1;
--		END

--		----Move SelectedChoiceOption table
--		--INSERT INTO [SLCProject].[dbo].[SelectedChoiceOption]
--		--(SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected, SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)
--		--SELECT S.SegmentChoiceCode, S.ChoiceOptionCode, S.ChoiceOptionSource, S.IsSelected, S2.SectionId, S.ProjectId, S.CustomerId, S.OptionJson, S.IsDeleted
--		--FROM #SelectedChoiceOption_Staging S
--		--INNER JOIN #tmpProjectSectionSLC S2 ON S.SectionId = S2.A_SectionId AND S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId
--		--WHERE S.SectionId = S2.A_SectionId AND S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #SelectedChoiceOption_Staging;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SelectedChoiceOption created', 'SelectedChoiceOption created', '19', 47, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Move ProjectHyperLink table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.HyperLinkId) AS RowNumber, S.HyperLinkId, S.SectionId, S.SegmentId
--				,S.SegmentStatusId, @New_ProjectID AS ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
--				,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
--				,S.HyperLinkId AS A_HyperLinkId
--		INTO #ProjectHyperLink_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectHyperLink] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink Staging Loaded', 'ProjectHyperLink Staging Loaded', '20', 50, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectHyperLink_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectHyperLink table
--			INSERT INTO [SLCProject].[dbo].[ProjectHyperLink]
--			(SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
--				,ModifiedDate, ModifiedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
--			SELECT S2.SectionId, CASE WHEN S4.SegmentId IS NULL THEN S.SegmentId ELSE S4.SegmentId END AS SegmentId, S3.SegmentStatusId, S.ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
--					,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
--					,S.A_HyperLinkId
--			FROM #ProjectHyperLink_Staging S
--			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentStatusId = S3.A_SegmentStatusId
--			LEFT JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--				AND S.SegmentId = S4.A_SegmentId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectHyperLink_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectHyperLink_BatchSize - 1;
--		END

--		----Move ProjectHyperLink table
--		--INSERT INTO [SLCProject].[dbo].[ProjectHyperLink]
--		--(SectionId, SegmentId, SegmentStatusId, ProjectId, CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy
--		--	,ModifiedDate, ModifiedBy, SLE_DocID, SLE_SegmentID, SLE_StatusID, SLE_LinkNo, A_HyperLinkId)
--		--SELECT S2.SectionId, CASE WHEN S4.SegmentId IS NULL THEN S.SegmentId ELSE S4.SegmentId END AS SegmentId, S3.SegmentStatusId, S.ProjectId, S.CustomerId, S.LinkTarget, S.LinkText, S.LuHyperLinkSourceTypeId
--		--		,S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.SLE_DocID, S.SLE_SegmentID, S.SLE_StatusID, S.SLE_LinkNo
--		--		,S.A_HyperLinkId
--		--FROM #ProjectHyperLink_Staging S
--		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
--		--LEFT JOIN #tmpProjectSegmentSLC S4 ON S.ProjectId = S4.ProjectId AND S.CustomerId = S4.CustomerId AND S2.SectionId = S4.SectionId
--		--	AND S.SegmentId = S4.A_SegmentId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink Records Added', 'ProjectHyperLink Records Added', '20', 50, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SELECT H.HyperLinkId, H.A_HyperLinkId, H.CustomerId, H.ProjectId, H.SectionId, H.SegmentStatusId, H.SegmentId
--		INTO #tmpProjectHyperLinkSLC FROM [SLCProject].[dbo].[ProjectHyperLink] H WITH (NOLOCK) WHERE H.ProjectId = @New_ProjectID AND H.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectHyperLink_Staging;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table Created from ProjectHyperLink', 'Temp Table Created from ProjectHyperLink', '20', 50, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		-----UPDATE NEW HyperLinkId in SegmentDescription      
--		--DECLARE @MultipleHyperlinkCount INT = 0;
--		--SELECT COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl FROM ProjectHyperLink WITH (NOLOCK) WHERE ProjectId = @New_ProjectID GROUP BY SegmentStatusId

--		--SELECT @MultipleHyperlinkCount = MAX(TotalCountSegmentStatusId) FROM #TotalCountSegmentStatusIdTbl
--		--WHILE (@MultipleHyperlinkCount > 0)
--		--BEGIN
--		--	UPDATE PS
--		--		SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}', '{HL#' + CAST(PHL.HyperLinkId AS NVARCHAR(20)) + '}')
--		--	FROM ProjectHyperLink PHL WITH (NOLOCK)
--		--	INNER JOIN ProjectSegment PS WITH (NOLOCK) ON PS.SegmentStatusId = PHL.SegmentStatusId AND PS.SegmentId = PHL.SegmentId AND PS.SectionId = PHL.SectionId
--		--		AND PS.ProjectId = PHL.ProjectId AND PS.CustomerId = PHL.CustomerId
--		--	WHERE PHL.ProjectId = @New_ProjectID AND PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%' AND PS.SegmentDescription LIKE '%{HL#%'

--		--	SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;
--		--END

--		--Update HyperLink placeholders with new HyperLinkId in ProjectSegment table
--		UPDATE A
--			SET A.SegmentDescription = B.NewSegmentDescription
--		FROM #tmpProjectSegmentSLC A
--		INNER JOIN (
--					SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentId) AS SegmentId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NewSegmentDescription
--					FROM #tmpProjectSegmentSLC PS
--					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
--						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId AND PS.SegmentId = HLNEW.SegmentId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{HL#%'
--					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
--		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HyperLink PlaceHolder Updated', 'HyperLink PlaceHolder Updated', '20', 50, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
--		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.SegmentDescription LIKE '%{HL#%';

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectHyperLink created', 'ProjectHyperLink created', '20', 50, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Insert ProjectNote_Staging table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.NoteId) AS RowNumber, S.NoteId, S.SectionId, S.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.Title
--				,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.NoteId AS A_NoteId
--		INTO #ProjectNote_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectNote] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote Staging Loaded', 'ProjectNote Staging Loaded', '21', 52, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectNote_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectNote table
--			INSERT INTO [SLCProject].[dbo].[ProjectNote]
--			(SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName
--				,ModifiedUserName, IsDeleted, NoteCode, A_NoteId)
--			SELECT S2.SectionId, S3.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId, S.Title
--					,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.A_NoteId
--			FROM #ProjectNote_Staging S
--			INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--			INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--				AND S.SegmentStatusId = S3.A_SegmentStatusId
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectNote_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectNote_BatchSize - 1;
--		END

--		----Move ProjectNote table
--		--INSERT INTO [SLCProject].[dbo].[ProjectNote]
--		--(SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId, CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName
--		--	,ModifiedUserName, IsDeleted, NoteCode, A_NoteId)
--		--SELECT S2.SectionId, S3.SegmentStatusId, S.NoteText, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId, S.Title
--		--		,S.CreatedBy, S.ModifiedBy, S.CreatedUserName, S.ModifiedUserName, S.IsDeleted, S.NoteCode, S.A_NoteId
--		--FROM #ProjectNote_Staging S
--		--INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		--INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--		--	AND S.SegmentStatusId = S3.A_SegmentStatusId
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote Records Inserted', 'ProjectNote Records Inserted', '21', 52, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SELECT P.NoteId, P.SectionId, P.SegmentStatusId, P.NoteText, P.ProjectId, P.CustomerId, P.A_NoteId INTO #tmpProjectNoteSLC
--		FROM [SLCProject].[dbo].[ProjectNote] P WITH (NOLOCK)
--		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectNote_Staging;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Temp Table created for ProjectNote', 'Temp Table created for ProjectNote', '21', 52, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Upate HyperLink placeholders with new HyperLinkId in ProjectNote table
--		UPDATE A
--			SET A.NoteText = B.NoteText
--		FROM #tmpProjectNoteSLC A
--		INNER JOIN (
--					SELECT HLNEW.CustomerId, HLNEW.ProjectId, MAX(HLNEW.SectionId) AS SectionId, MAX(HLNEW.SegmentStatusId) AS SegmentStatusId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{HL#'+CAST(HLNEW.A_HyperLinkId AS VARCHAR(32))+'}', '{HL#'+CAST(HLNEW.HyperLinkId AS VARCHAR(32))+'}') AS NoteText
--					FROM #tmpProjectNoteSLC PS
--					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectHyperLinkSLC HLNEW ON PS.ProjectId = HLNEW.ProjectId AND PS.CustomerId = HLNEW.CustomerId
--						AND PS.SectionId = HLNEW.SectionId AND PS.SegmentStatusId = HLNEW.SegmentStatusId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{HL#%'
--					GROUP BY HLNEW.CustomerId, HLNEW.ProjectId, HLNEW.SectionId, HLNEW.SegmentStatusId, HLNEW.SegmentId
--		) B ON A.ProjectId = B.ProjectId AND A.CustomerId = B.CustomerId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{HL#%'

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		DROP TABLE IF EXISTS #tmpProjectHyperLinkSLC;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'HyperLinkId updated in Temp ProjectNote', 'HyperLinkId updated in Temp ProjectNote', '21', 52, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.NoteText = PSS_TMP.NoteText
--		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectNoteSLC PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.NoteText LIKE '%{HL#%';

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNote created', 'ProjectNote created', '21', 52, @OldCount, @NewCount

--		SET @OldCount = 0

--		--Insert ProjectSegmentReferenceStandard_Staging table
--		SELECT S.SegmentRefStandardId, S.SectionId, S.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
--				,@New_ProjectID AS ProjectId, S.CustomerId, S.RefStdCode, S.IsDeleted
--		INTO #ProjectSegmentReferenceStandard_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentReferenceStandard] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


--		--Move ProjectSegmentReferenceStandard table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentReferenceStandard]
--		(SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, mSegmentId, ProjectId, CustomerId
--			,RefStdCode, IsDeleted)
--		SELECT S2.SectionId, S3.SegmentId, S.RefStandardId, S.RefStandardSource, S.mRefStandardId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.mSegmentId
--				,S.ProjectId, S.CustomerId, S.RefStdCode, S.IsDeleted
--		FROM #ProjectSegmentReferenceStandard_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentId = S3.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentReferenceStandard_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentReferenceStandard created', 'ProjectSegmentReferenceStandard created', '22', 55, @OldCount, @NewCount

--		--Insert ProjectSegmentTab_Staging table
--		SELECT S.SegmentTabId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy
--				,S.ModifiedDate, S.ModifiedBy
--		INTO #ProjectSegmentTab_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentTab] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentTab table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTab]
--		(CustomerId, ProjectId, SectionId, SegmentStatusId, TabTypeId, TabPosition, CreateDate, CreatedBy, ModifiedDate, ModifiedBy)
--		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.TabTypeId, S.TabPosition, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy
--		FROM #ProjectSegmentTab_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentStatusId = S3.A_SegmentStatusId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentTab_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTab created', 'ProjectSegmentTab created', '23', 57, @OldCount, @NewCount

--		--Move ProjectSegmentRequirementTag_Staging table
--		SELECT S.SegmentRequirementTagId, S.SectionId, S.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId
--				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
--		INTO #ProjectSegmentRequirementTag_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentRequirementTag] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentRequirementTag table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentRequirementTag]
--		(SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy
--			,mSegmentRequirementTagId, IsDeleted)
--		SELECT S2.SectionId, S3.SegmentStatusId, S.RequirementTagId, S.CreateDate, S.ModifiedDate, S.ProjectId, S.CustomerId
--				,S.CreatedBy, S.ModifiedBy, S.mSegmentRequirementTagId, S.IsDeleted
--		FROM #ProjectSegmentRequirementTag_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentStatusId = S3.A_SegmentStatusId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentRequirementTag_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentRequirementTag created', 'ProjectSegmentRequirementTag created', '24', 60, @OldCount, @NewCount

--		--Insert ProjectSegmentUserTag_Staging table
--		SELECT S.SegmentUserTagId, S.CustomerId, @New_ProjectID AS ProjectId, S.SectionId, S.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy
--				,S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		INTO #ProjectSegmentUserTag_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentUserTag] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentUserTag table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentUserTag]
--		(CustomerId, ProjectId, SectionId, SegmentStatusId, UserTagId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsDeleted)
--		SELECT S.CustomerId, S.ProjectId, S2.SectionId, S3.SegmentStatusId, S.UserTagId, S.CreateDate, S.CreatedBy, S.ModifiedDate, S.ModifiedBy, S.IsDeleted
--		FROM #ProjectSegmentUserTag_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectSegmentStatusSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentStatusId = S3.A_SegmentStatusId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentUserTag_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentUserTag created', 'ProjectSegmentUserTag created', '25', 62, @OldCount, @NewCount

--		--Insert ProjectSegmentImage_Staging table
--		SELECT S.SegmentImageId, S.SegmentId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
--		INTO #ProjectSegmentImage_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectSegmentImage table
--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentImage]
--		(SegmentId, SectionId, ImageId, ProjectId, CustomerId, ImageStyle)
--		SELECT CASE WHEN S3.SegmentId IS NULL THEN 0 ELSE S3.SegmentId END AS SegmentId, S2.SectionId, S4.ImageId, @New_ProjectID AS ProjectId, S.CustomerId, S.ImageStyle
--		FROM #ProjectSegmentImage_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectImageSLC S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
--		LEFT JOIN #tmpProjectSegmentSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.SegmentId = S3.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT S.SegmentImageId, S.ProjectId, S.CustomerId, S.SectionId, S.SegmentId, S.ImageId INTO #tmpProjectSegmentImage
--		FROM [SLCProject].[dbo].[ProjectSegmentImage] S WITH (NOLOCK) WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Update Image plaholders with new ImageId in ProjectSegment table
--		UPDATE A
--			SET A.SegmentDescription = B.NewSegmentDescription
--		FROM #tmpProjectSegmentSLC A
--		INNER JOIN (
--					SELECT S5.CustomerId, S5.ProjectId, MAX(S5.SectionId) AS SectionId, MAX(S5.SegmentId) AS SegmentId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.SegmentDescription, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NewSegmentDescription
--					FROM #tmpProjectSegmentSLC PS
--					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectSegmentImage S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
--						AND PS.SegmentId = S5.SegmentId
--					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.SegmentDescription LIKE '%{IMG#%'
--					GROUP BY S5.ProjectId, S5.CustomerId, S5.SectionId, S5.SegmentId
--		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentId = B.SegmentId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.SegmentDescription = PSS_TMP.SegmentDescription
--		FROM [SLCProject].[dbo].[ProjectSegment] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectSegmentSLC PSS_TMP ON PSS.SegmentId = PSS_TMP.SegmentId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.SegmentDescription LIKE '%{IMG#%';

--		DROP TABLE IF EXISTS #ProjectSegmentImage_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentImage created', 'ProjectSegmentImage created', '26', 65, @OldCount, @NewCount

--		--Insert ProjectNoteImage_Staging table
--		SELECT S.NoteImageId, S.NoteId, S.SectionId, S.ImageId, @New_ProjectID AS ProjectId, S.CustomerId
--		INTO #ProjectNoteImage_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectNoteImage] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move ProjectNoteImage table
--		INSERT INTO [SLCProject].[dbo].[ProjectNoteImage]
--		(NoteId, SectionId, ImageId, ProjectId, CustomerId)
--		SELECT S3.NoteId, S2.SectionId, S4.ImageId, S.ProjectId, S.CustomerId
--		FROM #ProjectNoteImage_Staging S
--		INNER JOIN #tmpProjectSectionSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S.SectionId = S2.A_SectionId
--		INNER JOIN #tmpProjectNoteSLC S3 ON S.ProjectId = S3.ProjectId AND S.CustomerId = S3.CustomerId AND S2.SectionId = S3.SectionId
--			AND S.NoteId = S3.A_NoteId
--		INNER JOIN #tmpProjectImageSLC S4 ON S.CustomerId = S4.CustomerId AND S.ImageId = S4.A_ImageId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		SELECT P.NoteImageId, P.ProjectId, P.CustomerId, P.SectionId, P.NoteId, P.ImageId INTO #tmpProjectNoteImageSLC FROM [SLCProject].[dbo].[ProjectNoteImage] P WITH (NOLOCK)
--		WHERE P.ProjectId = @New_ProjectID AND P.CustomerId = @SLC_CustomerId

--		--Update Image placeholders with new ImageId in ProjectNote table
--		UPDATE A
--			SET A.NoteText = B.NoteText
--		FROM #tmpProjectNoteSLC A
--		INNER JOIN (
--					SELECT PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId
--						,[SLCProject].[dbo].[SqlRegexReplace] (PS.NoteText, '{IMG#'+CAST(ImgNEW.A_ImageId AS VARCHAR(32))+'}', '{IMG#'+CAST(ImgNEW.ImageId AS VARCHAR(32))+'}') AS NoteText
--					FROM #tmpProjectNoteSLC PS
--					INNER JOIN #tmpProjectSectionSLC S2 ON PS.ProjectId = S2.ProjectId AND PS.CustomerId = S2.CustomerId AND PS.SectionId = S2.SectionId
--					INNER JOIN #tmpProjectSegmentStatusSLC S3 ON PS.ProjectId = S3.ProjectId AND PS.CustomerId = S3.CustomerId AND PS.SectionId = S3.SectionId
--						AND PS.SegmentStatusId = S3.SegmentStatusId
--					INNER JOIN #tmpProjectNoteImageSLC S5 ON PS.ProjectId = S5.ProjectId AND PS.CustomerId = S5.CustomerId AND PS.SectionId = S5.SectionId
--						AND PS.NoteId = S5.NoteId
--					INNER JOIN #tmpProjectImageSLC ImgNEW ON PS.CustomerId = ImgNEW.CustomerId AND S5.ImageId = ImgNEW.ImageId
--					WHERE PS.ProjectID = @New_ProjectID AND PS.CustomerID = @SLC_CustomerId AND PS.NoteText LIKE '%{IMG#%'
--					GROUP BY PS.CustomerId, PS.ProjectId, PS.SectionId, PS.SegmentStatusId--, S5.NoteId, S5.ImageId
--		) B ON A.CustomerId = B.CustomerId AND A.ProjectId = B.ProjectId AND A.SectionId = B.SectionId AND A.SegmentStatusId = B.SegmentStatusId
--		WHERE A.ProjectId = @New_ProjectID AND A.CustomerId = @SLC_CustomerId AND A.NoteText LIKE '%{IMG#%'

--		--UPDATE SegmentDescription in original table
--		UPDATE PSS
--		SET PSS.NoteText = PSS_TMP.NoteText
--		FROM [SLCProject].[dbo].[ProjectNote] PSS WITH (NOLOCK)
--		INNER JOIN #tmpProjectNoteSLC PSS_TMP ON PSS.NoteId = PSS_TMP.NoteId AND PSS.SectionId = PSS_TMP.SectionId
--			AND PSS.ProjectId = PSS_TMP.ProjectId
--		WHERE PSS.ProjectId = @New_ProjectID AND PSS.CustomerId = @SLC_CustomerId AND PSS_TMP.NoteText LIKE '%{IMG#%';

--		DROP TABLE IF EXISTS #tmpProjectImageSLC;
--		DROP TABLE IF EXISTS #tmpProjectNoteSLC;
--		DROP TABLE IF EXISTS #tmpProjectNoteImageSLC;
--		DROP TABLE IF EXISTS #ProjectNoteImage_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectNoteImage created', 'ProjectNoteImage created', '27', 67, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		--Move ProjectSegmentLink table
--		SELECT ROW_NUMBER() OVER(ORDER BY S.SegmentLinkId) AS RowNumber, S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
--			,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
--			,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, @New_ProjectID AS ProjectId, S.CustomerId, S.SegmentLinkCode
--			,S.SegmentLinkSourceTypeId
--		INTO #ProjectSegmentLink_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentLink] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		SET @TableRows = @@ROWCOUNT

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentLink Staging Loaded', 'ProjectSegmentLink Staging Loaded', '28', 70, @OldCount, @NewCount

--		SET @StartTime = GETUTCDATE()

--		SET @Records = 1
--		SET @Start = 1
--		SET @End = @Start + @ProjectSegmentLink_BatchSize - 1

--		WHILE @Records <= @TableRows
--		BEGIN
--			--Move ProjectSegmentLink table
--			INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
--			(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode
--				,TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, IsDeleted
--				,CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
--			SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
--				,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
--				,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.ProjectId, S.CustomerId, S.SegmentLinkCode
--				,S.SegmentLinkSourceTypeId
--			FROM #ProjectSegmentLink_Staging S
--			WHERE S.RowNumber BETWEEN @Start AND @End

--			SET @Records += @ProjectSegmentLink_BatchSize;
--			SET @Start = @End + 1 ;
--			SET @End = @Start + @ProjectSegmentLink_BatchSize - 1;
--		END

--		--INSERT INTO [SLCProject].[dbo].[ProjectSegmentLink]
--		--(SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource, TargetSectionCode
--		--	,TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget, LinkStatusTypeId, IsDeleted
--		--	,CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId, SegmentLinkCode, SegmentLinkSourceTypeId)
--		--SELECT S.SourceSectionCode, S.SourceSegmentStatusCode, S.SourceSegmentCode, S.SourceSegmentChoiceCode, S.SourceChoiceOptionCode, S.LinkSource
--		--	,S.TargetSectionCode, S.TargetSegmentStatusCode, S.TargetSegmentCode, S.TargetSegmentChoiceCode, S.TargetChoiceOptionCode, S.LinkTarget
--		--	,S.LinkStatusTypeId, S.IsDeleted, S.CreateDate, S.CreatedBy, S.ModifiedBy, S.ModifiedDate, S.ProjectId, S.CustomerId, S.SegmentLinkCode
--		--	,S.SegmentLinkSourceTypeId
--		--FROM #ProjectSegmentLink_Staging S
--		--WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentLink_Staging;

--		SET @EndTime = GETUTCDATE()
--		SET @OldCount = DATEDIFF(SECOND, @StartTime, @EndTime)

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentLink created', 'ProjectSegmentLink created', '28', 70, @OldCount, @NewCount

--		SET @OldCount = 0

--		--Move ProjectSegmentTracking table
--		SELECT S.[SegmentId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
--		INTO #ProjectSegmentTracking_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectSegmentTracking] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[ProjectSegmentTracking]
--		([SegmentId], [ProjectId], [CustomerId], [UserId], [SegmentDescription], [CreatedBy], [CreateDate], [VersionNumber])
--		SELECT S1.[SegmentId], S.[ProjectId], S.[CustomerId], S.[UserId], S.[SegmentDescription], S.[CreatedBy], S.[CreateDate], S.[VersionNumber]
--		FROM #ProjectSegmentTracking_Staging S
--		INNER JOIN #tmpProjectSegmentSLC S1 ON S.CustomerId = S1.CustomerId AND S.SegmentId = S1.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectSegmentTracking_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectSegmentTracking created', 'ProjectSegmentTracking created', '29', 72, @OldCount, @NewCount

--		--Move ProjectDisciplineSection table
--		SELECT S.[SectionId], S.[Disciplineld], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[IsActive]
--		INTO #ProjectDisciplineSection_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectDisciplineSection] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[ProjectDisciplineSection]
--		([SectionId], [Disciplineld], [ProjectId], [CustomerId], [IsActive])
--		SELECT S1.[SectionId], S.[Disciplineld], S.[ProjectId], S.[CustomerId], S.[IsActive]
--		FROM #ProjectDisciplineSection_Staging S
--		INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #ProjectDisciplineSection_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDisciplineSection created', 'ProjectDisciplineSection created', '30', 75, @OldCount, @NewCount

--		--Move ProjectDateFormat table
--		INSERT INTO [SLCProject].[dbo].[ProjectDateFormat]
--		([MasterDataTypeId], [ProjectId], [CustomerId], [UserId], [ClockFormat], [DateFormat], [CreateDate])
--		SELECT S.[MasterDataTypeId], @New_ProjectID AS [ProjectId], S.[CustomerId], S.[UserId], S.[ClockFormat], S.[DateFormat], S.[CreateDate]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectDateFormat] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectDateFormat created', 'ProjectDateFormat created', '31', 77, @OldCount, @NewCount

--		--Move MaterialSection table
--		SELECT @New_ProjectID AS [ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId]
--		INTO #MaterialSection_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[MaterialSection] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[MaterialSection]
--		([ProjectId], [VimId], [MaterialId], [SectionId], [CustomerId])
--		SELECT S.[ProjectId], S.[VimId], S.[MaterialId], S.[SectionId], S.[CustomerId]
--		FROM #MaterialSection_Staging S
--		--INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #MaterialSection_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'MaterialSection created', 'MaterialSection created', '32', 80, @OldCount, @NewCount

--		--Move LinkedSections table
--		SELECT @New_ProjectID AS [ProjectId], S.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
--		INTO #LinkedSections_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[LinkedSections] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[LinkedSections]
--		([ProjectId], [SectionId], [VimId], [MaterialId], [Linkedby], [LinkedDate], [customerId])
--		SELECT S.[ProjectId], S1.[SectionId], S.[VimId], S.[MaterialId], S.[Linkedby], S.[LinkedDate], S.[customerId]
--		FROM #LinkedSections_Staging S
--		INNER JOIN #tmpProjectSectionSLC S1 ON S.CustomerId = S1.CustomerId AND S.ProjectId = S1.ProjectId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #LinkedSections_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'LinkedSections created', 'LinkedSections created', '33', 82, @OldCount, @NewCount

--		--Move ApplyMasterUpdateLog table
--		INSERT INTO [SLCProject].[dbo].[ApplyMasterUpdateLog]
--		([ProjectId], [LastUpdateDate])
--		SELECT @New_ProjectID AS [ProjectId], S.[LastUpdateDate]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ApplyMasterUpdateLog] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ApplyMasterUpdateLog created', 'ApplyMasterUpdateLog created', '34', 85, @OldCount, @NewCount

--		--Move ProjectExport table
--		INSERT INTO [SLCProject].[dbo].[ProjectExport]
--		([FileName],[ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate],[IsDeleted],[CreatedDate],[CreatedBy],[CreatedByFullName]
--			,[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],[CustomerId],[ProjectName],[FileStatus])
--		SELECT [FileName], @New_ProjectID AS [ProjectId],[FilePath],[FileFormatType],[ProjectExportTypeId],[ExprityDate],[IsDeleted],[CreatedDate],[CreatedBy]
--			,[CreatedByFullName],[ModifiedDate],[ModifiedBy],[ModifiedByFullName],[FileExportTypeId],[CustomerId],[ProjectName],[FileStatus]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectExport] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectExport created', 'ProjectExport created', '35', 87, @OldCount, @NewCount

--		--Move SegmentComment table
--		SELECT @New_ProjectID AS [ProjectId],[SectionId],[SegmentStatusId],[ParentCommentId]
--			,[CommentDescription],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[CommentStatusId],[IsDeleted],[userFullName]
--			,[SegmentCommentId] AS [A_SegmentCommentId]
--		INTO #SegmentComment_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SegmentComment] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Insert SegmentComment table
--		INSERT INTO [SLCProject].[dbo].[SegmentComment]
--		(ProjectId,[SectionId],[SegmentStatusId],[ParentCommentId],[CommentDescription],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy]
--			,[ModifiedDate],[CommentStatusId],[IsDeleted],[userFullName],A_SegmentCommentId)
--		SELECT S.ProjectId,S1.[SectionId],S2.[SegmentStatusId],S.[ParentCommentId],S.[CommentDescription],S.[CustomerId],S.[CreatedBy],S.[CreateDate]
--			,S.[ModifiedBy],S.[ModifiedDate],S.[CommentStatusId],S.[IsDeleted],S.[userFullName],S.A_SegmentCommentId
--		FROM #SegmentComment_Staging S
--		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
--		INNER JOIN #tmpProjectSegmentStatusSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
--			AND S.SegmentStatusId = S2.A_SegmentStatusId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId


--		--Update ParentCommentId
--		UPDATE CST
--			SET CST.ParentCommentId = PST.SegmentCommentId
--		FROM [SLCProject].[dbo].[SegmentComment] CST WITH (NOLOCK)
--		INNER JOIN [SLCProject].[dbo].[SegmentComment] PST WITH (NOLOCK) ON CST.ProjectId = PST.ProjectId AND CST.CustomerId = PST.CustomerId
--			AND CST.SectionId = PST.SectionId AND PST.A_SegmentCommentId = CST.ParentCommentId AND CST.ParentCommentId <> 0
--		WHERE CST.ProjectId = @New_ProjectID AND CST.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #SegmentComment_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SegmentComment created', 'SegmentComment created', '36', 90, @OldCount, @NewCount

--		--Move TrackAcceptRejectProjectSegmentHistory table
--		SELECT [SectionId],[SegmentId], @New_ProjectID AS [ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note]
--		INTO #TrackAcceptRejectProjectSegmentHistory_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectProjectSegmentHistory]
--		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[TrackActionId],[Note])
--		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[TrackActionId],S.[Note]
--		FROM #TrackAcceptRejectProjectSegmentHistory_Staging S
--		INNER JOIN #tmpProjectSectionSLC S1 ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
--		LEFT JOIN #tmpProjectSegmentSLC S2 ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
--			AND S.SegmentId = S2.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #TrackAcceptRejectProjectSegmentHistory_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'TrackAcceptRejectProjectSegmentHistory created', 'TrackAcceptRejectProjectSegmentHistory created', '37', 92, @OldCount, @NewCount

--		--Insert TrackProjectSegment_Staging table
--		SELECT [SectionId],[SegmentId],@New_ProjectID AS [ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[CreateDate]
--			,[ChangedDate],[ChangedById],[IsDeleted]
--		INTO #TrackProjectSegment_Staging
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[TrackProjectSegment] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Move TrackProjectSegment table
--		INSERT INTO [SLCProject].[dbo].[TrackProjectSegment]
--		([SectionId],[SegmentId],[ProjectId],[CustomerId],[BeforEdit],[AfterEdit],[CreateDate],[ChangedDate],[ChangedById],[IsDeleted])
--		SELECT S1.[SectionId],S2.[SegmentId],S.[ProjectId],S.[CustomerId],S.[BeforEdit],S.[AfterEdit],S.[CreateDate],S.[ChangedDate],S.[ChangedById]
--			,S.[IsDeleted]
--		FROM #TrackProjectSegment_Staging S
--		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
--		LEFT JOIN #tmpProjectSegmentSLC S2 WITH (NOLOCK) ON S.ProjectId = S2.ProjectId AND S.CustomerId = S2.CustomerId AND S1.SectionId = S2.SectionId
--			AND S.SegmentId = S2.A_SegmentId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		DROP TABLE IF EXISTS #TrackProjectSegment_Staging;

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'TrackProjectSegment created', 'TrackProjectSegment created', '38', 93, @OldCount, @NewCount

--		--Move UserProjectAccessMapping table
--		INSERT INTO [SLCProject].[dbo].[UserProjectAccessMapping]
--		([ProjectId],[UserId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsActive])
--		SELECT @New_ProjectID AS [ProjectId],[UserId],[CustomerId],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[IsActive]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[UserProjectAccessMapping] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'UserProjectAccessMapping created', 'UserProjectAccessMapping created', '39', 94, @OldCount, @NewCount


--		--Move ProjectActivity table
--		INSERT INTO [SLCProject].[dbo].[ProjectActivity]
--		([ProjectId],[UserId],[CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate])
--		SELECT @New_ProjectID AS [ProjectId],[UserId],[CustomerId],[ProjectName],[UserEmail],[ProjectActivityTypeId],[CreatedDate]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectActivity] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectActivity created', 'ProjectActivity created', '40', 95, @OldCount, @NewCount


--		--Move ProjectLevelTrackChangesLogging table
--		INSERT INTO [SLCProject].[dbo].[ProjectLevelTrackChangesLogging]
--		([UserId],[ProjectId],[CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate])
--		SELECT [UserId],@New_ProjectID AS [ProjectId],[CustomerId],[UserEmail],[PriviousTrackChangeModeId],[CurrentTrackChangeModeId],[CreatedDate]
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[ProjectLevelTrackChangesLogging] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'ProjectLevelTrackChangesLogging created', 'ProjectLevelTrackChangesLogging created', '41', 96, @OldCount, @NewCount


--		--Insert 
--		SELECT [UserId],@New_ProjectID AS [ProjectId],[SectionId],[CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate]
--		INTO #tmpSectionLevelTrackChangesLoggingSLC
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[SectionLevelTrackChangesLogging] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


--		--Move SectionLevelTrackChangesLogging table
--		INSERT INTO [SLCProject].[dbo].[SectionLevelTrackChangesLogging]
--		([UserId],[ProjectId],[SectionId],[CustomerId],[UserEmail],[IsTrackChanges],[IsTrackChangeLock],[CreatedDate])
--		SELECT S.[UserId],S.[ProjectId],S1.[SectionId],S.[CustomerId],S.[UserEmail],S.[IsTrackChanges],S.[IsTrackChangeLock],S.[CreatedDate]
--		FROM #tmpSectionLevelTrackChangesLoggingSLC S WITH (NOLOCK)
--		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Update data for BIM files --Replace Old Production ProjectId with newly unarchived ProjectId

--		--Update VimDb..VimFileInfo
--		UPDATE S SET S.ProjectId = @New_ProjectID
--		FROM [VimDb].[dbo].[VimFileInfo] S WITH (NOLOCK)
--		WHERE S.ProjectId = @OldSLC_ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Update VimDb..RevitExportJobs
--		UPDATE S SET S.ProjectId = @New_ProjectID
--		FROM [VimDb].[dbo].[RevitExportJobs] S WITH (NOLOCK)
--		WHERE S.ProjectId = @OldSLC_ProjectID AND S.CustomerId = @SLC_CustomerId

--		--Update VimDb..VimProjectMapping
--		UPDATE S SET S.ProjectId = @New_ProjectID
--		FROM [VimDb].[dbo].[VimProjectMapping] S WITH (NOLOCK)
--		WHERE S.ProjectId = @OldSLC_ProjectID

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'SectionLevelTrackChangesLogging created', 'SectionLevelTrackChangesLogging created', '42', 97, @OldCount, @NewCount


--		--Insert 
--		SELECT [SectionId],@New_ProjectID AS [ProjectId],[CustomerId],[UserId],[TrackActionId],[CreateDate]
--		INTO #tmpTrackAcceptRejectHistorySLC
--		FROM [ARCHIVESERVER01].[SLCProject].[dbo].[TrackAcceptRejectHistory] S WITH (NOLOCK)
--		WHERE S.ProjectId = @ProjectID AND S.CustomerId = @SLC_CustomerId


--		--Move TrackAcceptRejectHistory table
--		INSERT INTO [SLCProject].[dbo].[TrackAcceptRejectHistory]
--		([SectionId],[ProjectId],[CustomerId],[UserId],[TrackActionId],[CreateDate])
--		SELECT S1.[SectionId],S.[ProjectId],S.[CustomerId],S.[UserId],S.[TrackActionId],S.[CreateDate]
--		FROM #tmpTrackAcceptRejectHistorySLC S WITH (NOLOCK)
--		INNER JOIN #tmpProjectSectionSLC S1 WITH (NOLOCK) ON S.ProjectId = S1.ProjectId AND S.CustomerId = S1.CustomerId AND S.SectionId = S1.A_SectionId
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'TrackAcceptRejectHistory created', 'TrackAcceptRejectHistory created', '43', 98, @OldCount, @NewCount

--		--Load Project Migration Exception table
--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Choice' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegmentSLC S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\ch\#%'

--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'ReferenceStandard' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegmentSLC S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\rs\#%'

--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'HyperLink' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegmentSLC S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\hl\#%'

--		INSERT INTO [SLCProject].[dbo].[ProjectMigrationException]
--		SELECT CustomerId, ProjectId, SectionId, SegmentId, SegmentStatusId, SegmentSource, SegmentCode, SegmentDescription, 0 AS CycleID, 0 AS IsClientNotified, 'Image' AS BrokenPlaceHolderType
--			,0 AS IsResolved, NULL AS [ModifiedBy], NULL AS [ModifiedDate]
--		FROM #tmpProjectSegmentSLC S
--		WHERE S.ProjectId = @New_ProjectID AND S.CustomerId = @SLC_CustomerId AND SegmentDescription LIKE '%\img\#%'

--		DROP TABLE IF EXISTS #tmpProjectSegmentSLC;

--		--Restore Deleted global data
--		EXECUTE [SLCProject].[dbo].[sp_RestoreDeletedGlobalData] @SLC_CustomerId, @New_ProjectID, @IsRestoreDeleteFailed OUTPUT

--		IF @IsRestoreDeleteFailed = 1
--		BEGIN
--			SET @IsProjectMigrationFailed = 1

--			--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
--			UPDATE P
--			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID;

--			--Update Project details in Archive server for the project that has been UnArchived successfully
--			UPDATE A
--			SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
--				,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
--				,A.DisplayTabId = 2 --ArchivedTab
--			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

--			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Failed with Restore Delete', 'Failed with Restore Delete', '45', NULL, 0, 0

--		END
--		ELSE
--		BEGIN
--			--Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
--			UPDATE P 
--			SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0, P.ModifiedDate = GETUTCDATE()
--			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID

--			--Mark Old ProjectID as Deleted in SLCProject..Project table
--			UPDATE P
--			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--			FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @OldSLC_ProjectID;

--			--Update Project details in Archive server for the project that has been UnArchived successfully
--			UPDATE A
--			SET A.SLC_ProdProjectId = @New_ProjectID, A.IsArchived = 0, A.UnArchiveTimeStamp = GETUTCDATE()
--				,A.InProgressStatusId = 4 --UnArchiveCompleted --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveCompleted')
--				,A.DisplayTabId = 3 --ActiveProjectsTab
--				,A.ProcessInitiatedById = 3 --SLC
--			FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--			WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

--			--Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
--			UPDATE P
--			SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedDate = GETUTCDATE()
--			FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
--			WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @ProjectID;

--			EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '44', 100, 0, 0

--			UPDATE U
--			SET U.SLCProd_ProjectId = @New_ProjectID
--			FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
--			WHERE U.RequestId = @RequestId;
--		END

--		----Update IsProjectMoved field to True and also Mark it is IsDeleted to false that means project is unarchived successfully to production server
--		--UPDATE P 
--		--SET P.IsProjectMoved = 1, P.IsDeleted = 0, P.IsArchived = 0, P.ModifiedDate = GETUTCDATE()
--		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		--WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID

--		----Mark Old ProjectID as Deleted in SLCProject..Project table
--		--UPDATE P
--		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--		--FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		--WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @OldSLC_ProjectID;

--		----Update Project details in Archive server for the project that has been UnArchived successfully
--		--UPDATE A
--		--SET A.SLC_ProdProjectId = @New_ProjectID, A.IsArchived = 0, A.UnArchiveTimeStamp = GETUTCDATE()
--		--	,A.InProgressStatusId = 4 --UnArchiveCompleted --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveCompleted')
--		--	,A.DisplayTabId = 3 --ActiveProjectsTab
--		--	,A.ProcessInitiatedById = 3 --SLC
--		--FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--		--WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

--		----Update Project Deleted and Permanent Deleted to True for the project from Archive Server as we have unarchived the project already
--		--UPDATE P
--		--SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedDate = GETUTCDATE()
--		--FROM [ARCHIVESERVER01].[SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		--WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @ProjectID;

--		--EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived', 'Project UnArchived', '40', 100, 0, 0

--		--UPDATE U
--		--SET U.SLCProd_ProjectId = @New_ProjectID
--		--FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U WITH (NOLOCK)
--		--WHERE U.RequestId = @RequestId;

--	END TRY

--	BEGIN CATCH
--		/*************************************
--		*  Get the Error Message for @@Error
--		*************************************/
--		--Set IsProjectMigrationFailed to 1
--		SET @IsProjectMigrationFailed = 1

--		--Mark New ProjectID as Permanently Deleted in SLCProject..Project table
--		UPDATE P
--		SET P.IsDeleted = 1, P.IsPermanentDeleted = 1, P.ModifiedBy = @SLC_UserId, P.ModifiedDate = GETUTCDATE()
--		FROM [SLCProject].[dbo].[Project] P WITH (NOLOCK)
--		WHERE P.CustomerId = @SLC_CustomerId AND P.ProjectId = @New_ProjectID;

--		--Update Project details in Archive server for the project that has been UnArchived successfully
--		UPDATE A
--		SET A.SLC_ProdProjectId = @OldSLC_ProjectID, A.IsArchived = 1
--			,A.InProgressStatusId = 7 --UnArchiveFailed --(SELECT [InProgressStatusId] FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[LuInProgressStatus] WHERE [Description] = 'UnArchiveFailed')
--			,A.DisplayTabId = 2 --ArchivedTab
--		FROM [ARCHIVESERVER01].[DE_Projects_Staging].[dbo].[ArchiveProject] A WITH (NOLOCK)
--		WHERE A.SLC_CustomerId = @SLC_CustomerId AND A.SLC_ArchiveProjectId = @ProjectID AND A.Archive_ServerId = @Archive_ServerId

--		EXECUTE [SLCProject].[dbo].[spb_UnArchiveStepProgress] @RequestId, 'Project UnArchived Failed', 'Project UnArchived Failed', '45', NULL, 0, 0

--		SET @ErrorStep = 'UnArchiveProject'

--		SELECT @ErrorCode = ERROR_NUMBER()
--			, @Return_Message = @ErrorStep + ' '
--			+ cast(ERROR_NUMBER() as varchar(20)) + ' line: '
--			+ cast(ERROR_LINE() as varchar(20)) + ' ' 
--			+ ERROR_MESSAGE() + ' > ' 
--			+ ERROR_PROCEDURE()

--		EXEC [SLCProject].[dbo].[spb_LogErrors] @ProjectID, @ErrorCode, @ErrorStep, @Return_Message

    
--	END CATCH
		

--END
--GO
--PRINT N'Altering [dbo].[spb_LogErrors]...';


--GO
--ALTER PROCEDURE [dbo].[spb_LogErrors]
--(
--	@CycleID			BIGINT
--	,@ErrorCode			INT
--	,@ErrorStep			VARCHAR(50)
--	,@Return_Message	VARCHAR(1024)
--)
--AS
--BEGIN
--	INSERT INTO [dbo].[Logging](ErrorCode, ErrorStep, ErrorMessage, Created, CycleID)
--	VALUES(@ErrorCode, @ErrorStep, @Return_Message, GETDATE(), @CycleID)
--END
--GO
--PRINT N'Altering [dbo].[spb_UnArchiveStepProgress]...';


--GO
--ALTER PROCEDURE [dbo].[spb_UnArchiveStepProgress]
--(
--	@RequestId						INT
--	,@StepName						NVARCHAR(100)
--	,@Description					NVARCHAR(500)
--	,@Step							NVARCHAR(100)
--	,@ProgressInPercent				INT
--	,@OldCount						INT
--	,@NewCount						INT
--)
--AS
--BEGIN
--	INSERT INTO [dbo].[UnArchiveStepProgress]
--	([RequestId],[StepName],[Description],[IsCompleted],[Step],[OldCount],[NewCount],[CreatedDate])
--	VALUES (@RequestId, @StepName, @Description, 1, @Step, @OldCount, @NewCount, GETUTCDATE())

--	IF @ProgressInPercent IS NULL
--	BEGIN
--		UPDATE U
--			SET U.IsNotify = 0
--				,U.StatusId = 4
--				,U.ModifiedDate = GETUTCDATE()
--		FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U with(nolock)
--		WHERE U.[RequestId] = @RequestId;
--	END
--	ELSE
--	BEGIN
--		UPDATE U
--			SET U.[ProgressInPercentage] = @ProgressInPercent
--				,U.IsNotify = 0
--				,U.StatusId = IIF(@ProgressInPercent = 100, 3, 2)
--				,U.ModifiedDate = GETUTCDATE()
--				,U.StartTime = IIF(@ProgressInPercent = 100, GETUTCDATE(), StartTime)
--				,U.EndTime = IIF(@ProgressInPercent = 100, GETUTCDATE(), EndTime)
--		FROM [SLCProject].[dbo].[UnArchiveProjectRequest] U  with(nolock)
--		WHERE U.[RequestId] = @RequestId;
--	END

--END
--GO
--PRINT N'Altering [dbo].[usp_ApplyProjectDefaultSetting]...';


GO
ALTER PROCEDURE [dbo].[usp_ApplyProjectDefaultSetting] (      
@IsOfficeMaster BIT,        
@ProjectId INT,    
@UserId INT,        
@CustomerId INT ,   
@ProjectOriginTypeId INT=1--Projects that are created or copied in SLC    
)      
AS        
BEGIN      
DECLARE @PIsOfficeMaster BIT = @IsOfficeMaster;      
DECLARE @PUserId INT = @UserId;      
DECLARE @PCustomerId INT = @CustomerId;     
DECLARE @PProjectOriginTypeId INT = @ProjectOriginTypeId;      
   
--Insert add user into the Project Team Member list       
INSERT INTO UserProjectAccessMapping      
SELECT       
 @ProjectId AS ProjectId      
   ,@PUserId AS UserId      
   ,PDPS.CustomerId      
   ,PDPS.CreatedBy      
   ,GETUTCDATE() AS CreateDate      
   ,PDPS.ModifiedBy      
   ,GETUTCDATE() AS ModifiedDate      
   ,CAST(1 AS BIT) AS IsActive FROM ProjectDefaultPrivacySetting PDPS WITH(NOLOCK)      
WHERE PDPS.CustomerId=@CustomerId       
AND PDPS.ProjectAccessTypeId IN (2,3)  --Private,Hidden      
AND ProjectOriginTypeId=@PProjectOriginTypeId   
AND ProjectOwnerTypeId=1 --Not Assigned    
AND PDPS.IsOfficeMaster=@IsOfficeMaster      
      
END
GO
PRINT N'Altering [dbo].[usp_deleteUserSegment]...';


GO
ALTER PROCEDURE [dbo].[usp_deleteUserSegment]                    
(                    
 @SegmentStatusId NVARCHAR(MAX)                  
)          
AS                    
BEGIN  
 BEGIN TRY      
  DECLARE @PSegmentStatusId NVARCHAR(MAX) =  @SegmentStatusId;  
  DROP TABLE IF EXISTS #SegStsTemp  
  CREATE TABLE #SegStsTemp(      
    SegmentStatusId INT,      
    ProjectId INT,      
    SectionId INT,      
    SegmentId INT,      
    mSegmentId INT,      
    CustomerId INT,      
    RowId INT      
  )  
  
  INSERT INTO #SegStsTemp (SegmentStatusId, RowId)  
  SELECT Id,ROW_NUMBER() OVER (ORDER BY Id) AS RowId  
  FROM dbo.udf_GetSplittedIds(@PSegmentStatusId, ',');  
  
  UPDATE T  
  SET T.SectionId=pss.SectionId,  
   T.ProjectId=pss.ProjectId,  
   T.CustomerId=pss.CustomerId,  
   T.SegmentId=pss.SegmentId,  
   T.mSegmentId=pss.mSegmentId  
  FROM #SegStsTemp T INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)  
  ON T.SegmentStatusId=pss.SegmentStatusId  
  
  --EXEC [dbo].[usp_DeleteSegmentsGTMapping] @PSegmentStatusId  
  UPDATE PSGT  
  SET PSGT.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectSegmentGlobalTerm PSGT WITH (NOLOCK)  
  ON PSGT.SectionId = T.SectionId   
  AND (PSGT.SegmentId = T.SegmentId  
  OR PSGT.mSegmentId = T.mSegmentId  
  OR PSGT.SegmentId = 0)  
  AND PSGT.ProjectId = T.ProjectId  
  AND PSGT.CustomerId=T.CustomerId  
  WHERE ISNULL(PSGT.IsDeleted,0) = 0  
  
    
  
    
  --Default variables                    
  DECLARE @Source VARCHAR(1) = 'U';  
   
  --DECLARE @ProjectId INT=0  
  --DECLARE @SectionId INT=0  
  --SELECT TOP 1  
  --   @ProjectId=ProjectId,@SectionId=SectionId  
  --  FROM ProjectSegmentStatus WITH (NOLOCK)  
  --  WHERE SegmentStatusId = @PSegmentStatusId  
  --  AND SegmentSource = @Source  
   
  --IF @ProjectId!=0 AND @ProjectId IS NOT NULL  
  --BEGIN  
  DROP TABLE IF EXISTS #PSC  
  SELECT PSC.SegmentChoiceId,PSC.SectionId,PSC.SegmentStatusId,PSC.SegmentChoiceCode  
  INTO #PSC FROM #SegStsTemp T INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)  
  ON PSC.SegmentStatusId = T.SegmentStatusId  
  AND PSC.SectionId=T.SectionId  
  --AND PSC.ProjectId=T.ProjectId  
  WHERE PSC.SegmentChoiceSource = @Source  
  
  UPDATE PSC  
  SET PSC.IsDeleted = 1  
  FROM #PSC T INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)  
  ON PSC.SegmentStatusId = T.SegmentStatusId  
  AND PSC.SegmentChoiceId=T.SegmentChoiceId  
  AND PSC.SectionId=T.SectionId  
  
  DROP TABLE IF EXISTS #PCO  
  SELECT PCO.ChoiceOptionId,PCO.SegmentChoiceId,PCO.SectionId,PCO.ProjectId,PCO.ChoiceOptionCode,T.SegmentChoiceCode  
  INTO #PCO FROM #PSC T INNER JOIN ProjectChoiceOption AS PCO WITH (NOLOCK)  
   ON PCO.SegmentChoiceId=T.SegmentChoiceId  
   AND PCO.SectionId=T.SectionId    
   
  UPDATE PCO  
  SET PCO.IsDeleted = 1  
  FROM #PCO T INNER JOIN ProjectChoiceOption AS PCO WITH (NOLOCK)  
   ON PCO.ChoiceOptionId=T.ChoiceOptionId  
   AND PCO.SegmentChoiceId = T.SegmentChoiceId  
   AND PCO.SectionId=T.SectionId    
   --AND PCO.ProjectId=T.ProjectId  
  WHERE PCO.ChoiceOptionSource = @Source  
  
  UPDATE SCP  
  SET SCP.IsDeleted = 1  
  FROM #PCO T   
   INNER JOIN SelectedChoiceOption AS SCP WITH (NOLOCK)  
   ON SCP.SectionId=T.SectionId   
   AND SCP.SegmentChoiceCode=T.SegmentChoiceCode  
   AND SCP.ChoiceOptionCode = T.ChoiceOptionCode  
   AND SCP.ProjectId=T.ProjectId  
  WHERE SCP.ChoiceOptionSource = @Source  
  
  UPDATE PS  
  SET PS.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectSegment PS WITH (NOLOCK)  
  ON PS.SegmentStatusId = T.SegmentStatusId  
  AND PS.SectionId= T.SectionId  
  --AND PS.ProjectId=T.ProjectId  
  --AND PS.CustomerId=T.CustomerId  
   
  --For Project Note Delete              
  UPDATE PN  
  SET PN.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectNote PN WITH (NOLOCK)  
  ON PN.SegmentStatusId = T.SegmentStatusId  
  AND PN.SectionId=T.SectionId  
  
  UPDATE PSRT  
  SET PSRT.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
  ON PSRT.SegmentStatusId = T.SegmentStatusId  
  AND PSRT.SectionId=T.SectionId  
   
  UPDATE PSUT  
  SET PSUT.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectSegmentUserTag PSUT WITH (NOLOCK)  
  ON PSUT.SegmentStatusId = T.SegmentStatusId  
  AND PSUT.SectionId = T.SectionId  
  --For Delete Segment Status          
  UPDATE PSS  
  SET PSS.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectSegmentStatus PSS WITH (NOLOCK)  
  ON PSS.SegmentStatusId = T.SegmentStatusId  
  AND PSS.SegmentSource = @Source  
  
  --EXEC [dbo].[usp_DeleteSegmentsRSMapping] @PSegmentStatusId  
  DROP TABLE IF EXISTS #PSRS  
  SELECT PSRS.SegmentRefStandardId,PSRS.ProjectId,PSRS.SectionId,PSRS.RefStandardId  
  INTO #PSRS FROM #SegStsTemp T INNER JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)  
  ON PSRS.SectionId = T.SectionId   
  AND (PSRS.SegmentId = T.SegmentId  
  OR PSRS.mSegmentId = T.mSegmentId  
  OR PSRS.SegmentId = 0)  
  AND PSRS.ProjectId = T.ProjectId   
  AND PSRS.CustomerId = T.CustomerId   
  WHERE ISNULL(PSRS.IsDeleted,0) = 0  
  
  UPDATE PSRS  
  SET PSRS.IsDeleted = 1  
  FROM #PSRS T INNER JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)  
  ON PSRS.SegmentRefStandardId = T.SegmentRefStandardId   
  AND PSRS.SectionId = T.SectionId   
  AND PSRS.ProjectId = T.ProjectId   
  
  UPDATE PRS  
  SET PRS.IsDeleted = 1  
  FROM #PSRS T INNER JOIN ProjectReferenceStandard PRS WITH (NOLOCK)  
   ON T.RefStandardId = PRS.RefStandardId  
   AND T.SectionId = PRS.SectionId  
   AND T.ProjectId = PRS.ProjectId  
   --AND T.RefStdCode = PRS.RefStdCode  

   --added for delating segment link when segment is deleted.
  UPDATE psl SET psl.IsDeleted=1 FROM  #SegStsTemp T  INNER JOIN  ProjectSegment ps with(nolock)
  ON T.SegmentStatusId=ps.SegmentStatusId AND T.SectionId=ps.SectionId AND T.ProjectId=ps.ProjectId
  AND T.SegmentId=ps.SegmentId AND T.CustomerId=ps.CustomerId
  INNER JOIN ProjectSegmentLink psl with(nolock)
  ON  ( psl.SourceSegmentCode=ps.SegmentCode OR psl.TargetSegmentCode=ps.SegmentCode) and 
  psl.ProjectId=ps.ProjectId and psl.CustomerId=ps.CustomerId
  WHERE  ps.SegmentStatusId=T.SegmentStatusId
  AND ISNULL(psl.IsDeleted,0)=0
 
  
 END TRY  
 BEGIN CATCH  
   insert into BsdLogging..AutoSaveLogging  
    values('usp_deleteUserSegment',  
    getdate(),  
    ERROR_MESSAGE(),  
    ERROR_NUMBER(),  
    ERROR_Severity(),  
    ERROR_LINE(),  
    ERROR_STATE(),  
    ERROR_PROCEDURE(),  
    concat('exec usp_deleteUserSegment ',@SegmentStatusId),  
    @SegmentStatusId  
   )  
 END CATCH  
END
GO
PRINT N'Altering [dbo].[usp_GetChoicesForPrint]...';


GO
ALTER PROCEDURE [dbo].[usp_GetChoicesForPrint]
( @ProjectId int
 ,@CustomerId int
 ,@SectionIds nvarchar(max)
 ,@IsActiveOnly BIT = 1 
)
as
Begin
DECLARE @SectionIdTbl TABLE (SectionId INT); 
DECLARE @PProjectId INT = @ProjectId;                    
DECLARE @PCustomerId INT = @CustomerId;
DECLARE @PIsActiveOnly BIT = @IsActiveOnly;

--CONVERT STRING INTO TABLE                                        
 INSERT INTO @SectionIdTbl (SectionId)                    
 SELECT *                    
 FROM dbo.fn_SplitString(@SectionIds, ',');                    
       
-- insert missing sco entries                        
 INSERT INTO SelectedChoiceOption                    
 SELECT psc.SegmentChoiceCode                    
  ,pco.ChoiceOptionCode   
  ,pco.ChoiceOptionSource                    
  ,slcmsco.IsSelected                    
  ,psc.SectionId                    
  ,psc.ProjectId                    
  ,pco.CustomerId                    
  ,NULL AS OptionJson                    
  ,0 AS IsDeleted                    
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl stb ON psc.SectionId = stb.SectionId                    
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                    
  AND pco.SectionId = psc.SectionId                    
  AND pco.ProjectId = psc.ProjectId                    
  AND pco.CustomerId = psc.CustomerId      
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                    
  AND pco.SectionId = sco.SectionId                    
  AND pco.ProjectId = sco.ProjectId                    
  AND pco.CustomerId = sco.CustomerId                    
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                    
 INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK) ON slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode                    
 WHERE sco.SelectedChoiceOptionId IS NULL                    
  AND pco.CustomerId = @PCustomerId                    
  AND pco.ProjectId = @PProjectId                    
  AND ISNULL(pco.IsDeleted, 0) = 0                    
  AND ISNULL(psc.IsDeleted, 0) = 0                    
 
 IF( @@rowcount > 0)
 BEGIN
  -- insert missing sco entries                        
 INSERT INTO BsdLogging..DBLogging (                    
  ArtifactName                    
  ,DBServerName                    
  ,DBServerIP                    
  ,CreatedDate                    
  ,LevelType                    
  ,InputData                    
  ,ErrorProcedure                    
  ,ErrorMessage                    
  )                    
 VALUES (                    
  'usp_GetSegmentsForPrint'                    
  ,@@SERVERNAME                    
  ,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))                    
  ,Getdate()                    
  ,'Information'                    
  ,('ProjectId: ' + convert(NVARCHAR, @PProjectId) +  ' CustomerId: ' + convert(NVARCHAR, @PCustomerId) + ' SectionIdsString:' + @SectionIds)        
  ,'Insert'                    
  ,('Scenario 1: SelectedChoiceOption Rows Inserted - ' + convert(NVARCHAR, @@ROWCOUNT))                    
  )                    
       
 END;                 
             
 -- Mark isdeleted =0 for SelectedChoiceOption                      
 UPDATE sco                    
 SET sco.isdeleted = 0                    
 FROM ProjectSegmentChoice psc WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl stb  ON psc.SectionId = stb.SectionId                    
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                    
  AND pco.SectionId = psc.SectionId                    
  AND pco.ProjectId = psc.ProjectId       
  AND pco.CustomerId = psc.CustomerId                    
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ChoiceOptionCode = sco.ChoiceOptionCode                    
  AND pco.SectionId = sco.SectionId                    
  AND pco.ProjectId = sco.ProjectId                    
  AND pco.CustomerId = sco.CustomerId                    
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                    
 WHERE ISNULL(sco.IsDeleted, 0) = 1                    
  AND pco.CustomerId = @PCustomerId                    
  AND pco.ProjectId = @PProjectId                    
  AND ISNULL(pco.IsDeleted, 0) = 0                    
  AND ISNULL(psc.IsDeleted, 0) = 0                    
  AND psc.SegmentChoiceSource = 'U'                    
  
  IF( @@rowcount > 0)
  BEGIN
  --                      
 INSERT INTO BsdLogging..DBLogging (                    
  ArtifactName         
  ,DBServerName                    
  ,DBServerIP                    
  ,CreatedDate                    
  ,LevelType                    
  ,InputData                    
  ,ErrorProcedure                    
  ,ErrorMessage                    
  )                    
 VALUES (                    
  'usp_GetSegmentsForPrint'                    
  ,@@SERVERNAME                    
  ,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))                    
  ,Getdate()                    
  ,'Information'                    
  ,('ProjectId: ' + convert(NVARCHAR, @PProjectId) +  ' CustomerId: ' + convert(NVARCHAR, @PCustomerId) + ' SectionIdsString:' + @SectionIds)     
  ,'Update'      
  ,('Scenario 2: SelectedChoiceOption Rows Updated - ' + convert(NVARCHAR, @@ROWCOUNT))                    
  )                    
     
  End;                  
                
 --FETCH SelectedChoiceOption INTO TEMP TABLE                                        
 SELECT DISTINCT SCHOP.SegmentChoiceCode                    
  ,SCHOP.ChoiceOptionCode                    
  ,SCHOP.ChoiceOptionSource              ,SCHOP.IsSelected                    
  ,SCHOP.ProjectId                    
  ,SCHOP.SectionId                    
  ,SCHOP.CustomerId                    
  ,0 AS SelectedChoiceOptionId                    
  ,SCHOP.OptionJson                    
 INTO #tmp_SelectedChoiceOption                    
 FROM SelectedChoiceOption SCHOP WITH (NOLOCK)                    
 INNER JOIN @SectionIdTbl SIDTBL ON SCHOP.SectionId = SIDTBL.SectionId                    
 WHERE SCHOP.ProjectId = @PProjectId                    
  AND SCHOP.CustomerId = @PCustomerId                    
  AND IsNULL(SCHOP.IsDeleted, 0) = 0                    
 
 SELECT PSST.SectionId,PSST.SegmentId, PSST.mSegmentId INTO #tempPSS FROM @SectionIdTbl STBL
 INNER JOIN  ProjectSegmentStatus PSST WITH (NOLOCK)
 ON PSST.SectionId = STBL.SectionId 
 WHERE PSST.ProjectId = @PProjectId                    
  AND PSST.CustomerId = @PCustomerId                    
  AND ISNULL(PSST.IsDeleted,0)=0
    AND (                    
   @PIsActiveOnly = 0                    
   OR (                    
    PSST.SegmentStatusTypeId > 0                    
    AND PSST.SegmentStatusTypeId < 6                    
    AND PSST.IsParentSegmentStatusActive = 1                    
    )                    
   OR (PSST.IsPageBreak = 1)                    
   )    
     
                    
 --FETCH MASTER + USER CHOICES AND THEIR OPTIONS                                          
 SELECT 0 AS SegmentId                    
  ,MCH.SegmentId AS mSegmentId                    
  ,MCH.ChoiceTypeId                    
  ,'M' AS ChoiceSource                    
  ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                  
  ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode                    
  ,PSCHOP.IsSelected                    
  ,PSCHOP.ChoiceOptionSource                    
  ,CASE                     
   WHEN PSCHOP.IsSelected = 1                    
    AND PSCHOP.OptionJson IS NOT NULL                    
    THEN PSCHOP.OptionJson                    
   ELSE MCHOP.OptionJson                    
   END AS OptionJson                    
  ,MCHOP.SortOrder                    
  ,MCH.SegmentChoiceId                    
  ,MCHOP.ChoiceOptionId                    
  ,PSCHOP.SelectedChoiceOptionId                    
  ,PSST.SectionId  INTO #DapperChoicesTbl                   
 FROM #tempPSS PSST WITH (NOLOCK)                    
 INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK) ON PSST.mSegmentId = MCH.SegmentId                    
 INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK) ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId                    
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                    
  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                    
  AND PSCHOP.ChoiceOptionSource = 'M'                    
 UNION                    
 SELECT PCH.SegmentId                    
  ,0 AS mSegmentId                    
  ,PCH.ChoiceTypeId                    
  ,PCH.SegmentChoiceSource AS ChoiceSource                    
  ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode                    
  ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode                    
  ,PSCHOP.IsSelected                    
  ,PSCHOP.ChoiceOptionSource                    
  ,PCHOP.OptionJson                    
  ,PCHOP.SortOrder                    
  ,PCH.SegmentChoiceId       
  ,PCHOP.ChoiceOptionId                    
  ,PSCHOP.SelectedChoiceOptionId                    
  ,PSST.SectionId                    
 FROM #tempPSS PSST WITH (NOLOCK)                    
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK) ON PSST.SegmentId = PCH.SegmentId                    
  AND ISNULL(PCH.IsDeleted, 0) = 0                    
 INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK) ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId                    
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                    
 INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode                    
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode                    
AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource                    
  AND PSCHOP.ChoiceOptionSource = 'U'                    
 WHERE PCH.ProjectId = @PProjectId                    
  AND PCH.CustomerId = @PCustomerId                    
  AND PCHOP.ProjectId = @PProjectId                    
  AND PCHOP.CustomerId = @PCustomerId                    
  AND ISNULL(PCH.IsDeleted, 0) = 0                    
  AND ISNULL(PCHOP.IsDeleted, 0) = 0                    
                    

SELECT SegmentId
,MSegmentId
,ChoiceTypeId
,ChoiceSource
,SegmentChoiceCode
,SegmentChoiceId
,@PProjectId AS ProjectId
,@PCustomerId as CustomerId
,SectionId
FROM #DapperChoicesTbl

SELECT ChoiceOptionCode
,IsSelected
,SegmentChoiceCode
,ChoiceOptionSource
,ChoiceOptionId
,SortOrder
,SelectedChoiceOptionId
,@PProjectId AS ProjectId
,@PCustomerId as CustomerId
,SectionId
,OptionJson
FROM #DapperChoicesTbl

End;
GO
PRINT N'Altering [dbo].[usp_GetProjectExportList]...';


GO
ALTER PROC [dbo].[usp_GetProjectExportList]            
(                  
 @CustomerId INT,  
 @UserId INT = 0         
)                  
AS                  
BEGIN          
  
DECLARE @PCustomerId INT=@CustomerId,  
     @PUserId INT =@UserId  
  
SELECT  
 PE.ProjectExportId  
   ,COALESCE(PE.FileName,'')  FileName
   ,PE.ProjectId  
   ,COALESCE(PE.FilePath ,'') FilePath
   ,COALESCE(PE.FileFormatType ,'')  FileFormatType
   ,LPET.ProjectExportTypeId   
   ,PE.ExprityDate  
   ,PE.IsDeleted  
   ,PE.CreatedDate  
   ,PE.CreatedBy  
   ,COALESCE(PE.CreatedByFullName,'') CreatedByFullName 
   ,PE.ModifiedDate  
   ,PE.ModifiedBy  
   ,COALESCE(PE.ModifiedByFullName,'')  ModifiedByFullName
   ,LFET.FileExportTypeId  
   ,COALESCE(LPET.Name,'') AS ProjectExportType  
   ,COALESCE(LFET.Name,'') AS FileExportType  
   ,PE.CustomerId  
   ,COALESCE(PE.ProjectName,'')  ProjectName
   ,COALESCE(PE.FileStatus ,'') FileStatus
  
FROM ProjectExport PE WITH (NOLOCK)  
INNER JOIN LuProjectExportType LPET WITH (NOLOCK)  
 ON PE.ProjectExportTypeId = LPET.ProjectExportTypeId  
INNER JOIN LuFileExportType LFET WITH (NOLOCK)  
 ON PE.FileExportTypeId = LFET.FileExportTypeId  
WHERE CustomerId = @PCustomerId  
AND IsDeleted = 0 AND PE.CreatedBy = @PUserId  
ORDER BY CreatedDate DESC         
          
END
GO
PRINT N'Altering [dbo].[usp_InsertUnArchiveNotification]...';


GO
ALTER PROCEDURE [dbo].[usp_InsertUnArchiveNotification]  
(  
 @ArchiveProjectId INT,  
 @ProdProjectId INT,  
 @SLC_UserId INT,  
 @SLC_CustomerId INT,  
 @ProjectName NVARCHAR(500),  
 @RequestType INT  
)  
AS  
BEGIN  
	--Check wether notification is present and status is Queued/Running
	DECLARE @RequestId INT=(SELECT TOP 1 RequestId from UnArchiveProjectRequest WITH(NOLOCK) where SLC_ArchiveProjectId=@ArchiveProjectId
				AND SLC_CustomerId=@SLC_CustomerId and IsDeleted=0 and StatusId IN(1,2))
	IF(isnull(@RequestId,0)>0)
	BEGIN
		UPDATE APR
		SET APR.StatusId=1,
			APR.ProgressInPercentage=0,
			APR.IsNotify=0,
			APR.RequestDate=GETUTCDATE()
		FROM UnArchiveProjectRequest APR WITH(NOLOCK)
		WHERE APR.RequestId=@RequestId
	END
	ELSE
	BEGIN
		INSERT INTO UnArchiveProjectRequest  
		 (SLC_ArchiveProjectId,SLCProd_ProjectId,SLC_CustomerId,SLC_UserId,  
		 RequestDate,RequestType,StatusId,IsNotify,ProgressInPercentage,  
		 EmailFlag,IsDeleted,ProjectName,ModifiedDate)  
		VALUES(@ArchiveProjectId,@ProdProjectId,@SLC_CustomerId,@SLC_UserId,  
		  GETUTCDATE(),@RequestType,1,0,0,  
		  0,0,@ProjectName,GETUTCDATE())         
	END

END
GO
PRINT N'Altering [dbo].[usp_MapGlobalTermToProject]...';


GO
ALTER PROCEDURE [dbo].[usp_MapGlobalTermToProject]        
 @ProjectID INT NULL,       
 @CustomerID INT NULL,       
 @UserID INT NULL ,    
 @ProjectName NVARCHAR(MAX) = NULL,    
 @MasterDataTypeId INT =1    
AS        
BEGIN    
---- Map All Global Term    
    
DECLARE @PProjectID INT = @ProjectID;    
DECLARE @PCustomerID INT = @CustomerID;    
DECLARE @PUserID INT = @UserID;    
DECLARE @PProjectName NVARCHAR(MAX) = @ProjectName;    
DECLARE @PMasterDataTypeId INT = @MasterDataTypeId;    
DECLARE @StateProvinceName NVARCHAR(100)='', @City NVARCHAR(100)='';    
-- SET City as per selected project    
SET @City = (SELECT TOP 1    
  IIF(LUC.City IS NULL, PADR.CityName, LUC.City) AS City    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuCity LUC WITH (NOLOCK)    
  ON LUC.CityId = PADR.CityId    
 WHERE PADR.ProjectId = @PProjectID    
 AND PADR.CustomerId = @PCustomerID);    
-- SET State as per selected project    
SET @StateProvinceName = (SELECT TOP 1    
  IIF(LUS.StateProvinceName IS NULL, PADR.StateProvinceName, LUS.StateProvinceName) AS StateProvinceName    
 FROM ProjectAddress PADR WITH (NOLOCK)    
 LEFT OUTER JOIN LuStateProvince LUS WITH (NOLOCK)    
  ON LUS.StateProvinceID = PADR.StateProvinceId    
 WHERE PADR.ProjectId = @PProjectID    
 AND PADR.CustomerId = @PCustomerID);    
    
 --Map master global term    
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted, GlobalTermFieldTypeId)    
 SELECT    
  GlobalTermId    
    ,@PProjectID AS ProjectId    
    ,@PCustomerID AS CustomerId    
    ,[Name]    
  --,Value    
    ,CASE    
   WHEN Name = 'Project Name' THEN CAST(@PProjectName AS NVARCHAR(MAX))    
   WHEN Name = 'Project ID' THEN CAST(@PProjectID AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location State' THEN CAST(@StateProvinceName AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location City' THEN CAST(@City AS NVARCHAR(MAX))    
   WHEN Name = 'Project Location Province' THEN CAST(@StateProvinceName AS NVARCHAR(MAX))    
   ELSE [Value]    
  END AS [Value]    
    ,'M'    
    ,GlobalTermCode    
    ,GETUTCDATE()    
    ,@PUserID AS CreatedBy    
    ,GETUTCDATE()    
    ,@PUserID AS ModifiedBy    
    ,NULL    
    ,0 AS IsDeleted    
    ,GlobalTermFieldTypeId    
 FROM SLCMaster..GlobalTerm WITH(NOLOCK)    
 WHERE MasterDataTypeId =    
 CASE    
  WHEN @PMasterDataTypeId = 1 OR    
   @PMasterDataTypeId = 2 OR    
   @PMasterDataTypeId = 3 THEN 1    
  ELSE @PMasterDataTypeId    
 END;    
 -- Map user global term    
 -- declare table variable  
DECLARE @GlobalTermCode TABLE (  
  MinGlobalTermCode int,  
  UserGlobalTermId int  
);  
  
INSERT @GlobalTermCode  
 SELECT MIN(GlobalTermCode) AS MinGlobalTermCode,UserGlobalTermId      
 FROM ProjectGlobalTerm WITH (NOLOCK)    
 WHERE CustomerId =@PCustomerID AND ISNULL(IsDeleted,0)=0     
 AND GlobalTermSource='U' AND  UserGlobalTermId IS NOT NULL
 GROUP BY UserGlobalTermId    
    
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value,GlobalTermCode, GlobalTermSource, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)    
 SELECT    
  NULL AS GlobalTermId    
    ,@PProjectID AS ProjectId    
    ,@PCustomerID AS CustomerId    
    ,Name    
    ,Name    
    ,MGTC.MinGlobalTermCode    
    ,'U'    
    ,GETUTCDATE()    
    ,@PUserID AS CreatedBy    
    ,GETUTCDATE()    
    ,@PUserID AS ModifiedBy    
    ,UGT.UserGlobalTermId AS UserGlobalTermId    
    ,ISNULL(IsDeleted, 0) AS IsDeleted    
 FROM UserGlobalTerm UGT WITH(NOLOCK) INNER JOIN @GlobalTermCode MGTC   
 ON UGT.UserGlobalTermId=MGTC.UserGlobalTermId    
 WHERE CustomerId = @PCustomerID    
 AND IsDeleted = 0    
END
GO
PRINT N'Altering [dbo].[usp_SaveImage]...';


GO
ALTER PROCEDURE [dbo].[usp_SaveImage]
(  
@ImagePath NVARCHAR(255),  
@LuImageSourceTypeId INT,  
@CustomerId INT
)  
AS  
BEGIN  
DECLARE @PImagePath NVARCHAR(255) = @ImagePath;  
DECLARE @PLuImageSourceTypeId INT = @LuImageSourceTypeId;  
DECLARE @PCustomerId INT = @CustomerId;  
  
INSERT INTO ProjectImage (ImagePath, LuImageSourceTypeId, CreateDate, ModifiedDate,CustomerId)  
VALUES (@PImagePath, @PLuImageSourceTypeId, GETUTCDATE(), GETUTCDATE(),@PCustomerId)  
  
SELECT  
CAST(SCOPE_IDENTITY() AS INT) AS projectImageId;  
  
END
GO
PRINT N'Creating [dbo].[usp_AcceptTransferProject]...';


GO
CREATE PROCEDURE usp_AcceptTransferProject        
(        
 @ProjectId INT,    
 @UserId INT=0,    
 @CustomerId INT,  
 @ModifiedByFullName NVARCHAR(500)    
)        
AS        
BEGIN        
         
DECLARE @PProjectId INT=@ProjectId;    
DECLARE @PUserId INT=@UserId;    
DECLARE @PModifiedByFullName NVARCHAR(500)=@ModifiedByFullName;    
    
 UPDATE P        
 SET P.IsIncomingProject = 0,    
 P.ModifiedBy=@PUserId,    
 P.ModifiedByFullName=@PModifiedByFullName,    
 P.CreateDate=GETUTCDATE()    
 FROM Project P WITH(NOLOCK)        
 WHERE P.ProjectId =  @PProjectId;        
        
 UPDATE UF       
 SET UF.LastAccessed=GETUTCDATE()  ,    
 UF.UserId=@PUserId,    
 UF.LastAccessByFullName=@PModifiedByFullName    
 FROM UserFolder UF WITH(NOLOCK)       
 where UF.ProjectId=@PProjectId      
  
 DECLARE @TransferredRequestId INT =0  
 SELECT  @TransferredRequestId=TransferRequestId  FROM CopyProjectRequest  WITH(NOLOCK) WHERE  TargetProjectId=@PProjectId  
 INSERT INTO IncomingProjectHistory VALUES (@ProjectId,'ACCEPTED',@UserId,@CustomerId,GETUTCDATE(),@TransferredRequestId)  
END
GO
PRINT N'Creating [dbo].[usp_CopyAcrossBranchLinks]...';


GO
CREATE PROCEDURE usp_CopyAcrossBranchLinks   --usp_CopyAcrossBranchLinks 82,24,''
(  
 @UserId INT,  
 @CustomerId int,
 @NewSegmentsJson NVARCHAR(MAX)  
)  
AS  
BEGIN
  
   
 DECLARE @CreatedBy INT = @UserId,@SegmentLinkSourceTypeId int=5;

SELECT
	* INTO #NewSegmentTable
FROM OPENJSON(@NewSegmentsJson) WITH (
RowId INT '$.RowId',
SrcChoiceOptionCode INT '$.SrcChoiceOptionCode',
SrcProjectId INT '$.SrcProjectId',
SrcSectionCode INT '$.SrcSectionCode',
SrcSectionId INT '$.SrcSectionId',
SrcSegmentChoiceCode INT '$.SrcSegmentChoiceCode',
SrcSegmentCode INT '$.SrcSegmentCode',
SrcSegmentId INT '$.SrcSegmentId',
SrcSegmentStatusCode INT '$.SrcSegmentStatusCode',
SrcSegmentStatusId INT '$.SrcSegmentStatusId',
TrgChoiceOptionCode INT '$.TrgChoiceOptionCode',
TrgProjectId INT '$.TrgProjectId',
TrgSectionCode INT '$.TrgSectionCode',
TrgSectionId INT '$.TrgSectionId',
TrgSegmentChoiceCode INT '$.TrgSegmentChoiceCode',
TrgSegmentCode INT '$.TrgSegmentCode',
TrgSegmentId INT '$.TrgSegmentId',
TrgSegmentStatusCode INT '$.TrgSegmentStatusCode',
TrgSegmentStatusId INT '$.TrgSegmentStatusId'
);


DECLARE @ProjectId INT = 0
	   ,@SectionCode INT = 0
	   ,@SectionId INT = 0
	   ,@SourceSegmentCode INT = 0;

SELECT TOP 1
	@ProjectId = SrcProjectId
   ,@SectionCode = SrcSectionCode
   ,@SectionId = TrgSectionId
   ,@SourceSegmentCode = TrgSegmentCode
FROM #NewSegmentTable

SELECT
	SourceSectionCode
   ,SourceSegmentStatusCode
   ,SourceSegmentCode
   ,SourceSegmentChoiceCode
   ,SourceChoiceOptionCode
   ,TargetSectionCode
   ,TargetSegmentStatusCode
   ,TargetSegmentCode
   ,TargetSegmentChoiceCode
   ,TargetChoiceOptionCode
   ,LinkTarget
   ,LinkStatusTypeId
   ,CustomerId
   ,IsDeleted
   ,ProjectId
   ,SegmentLinkId INTO #ProjectSegmentLinkTBL
FROM ProjectSegmentLink WITH (NOLOCK)
WHERE ProjectId = @ProjectId 
AND CustomerId = @CustomerId
AND SourceSectionCode = @SectionCode

----START Cross Link Logic----------------------------

SELECT DISTINCT
	CLRT.TrgSectionCode AS SourceSectionCode
   ,CLRT.TrgSegmentStatusCode AS SourceSegmentStatusCode
   ,CLRT.TrgSegmentCode AS SourceSegmentCode
   ,IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode) AS SourceSegmentChoiceCode
   ,IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode) AS SourceChoiceOptionCode
   ,'U' AS LinkSource
   ,PSL.TargetSectionCode
   ,PSL.TargetSegmentStatusCode
   ,PSL.TargetSegmentCode
   ,PSL.TargetSegmentChoiceCode
   ,PSL.TargetChoiceOptionCode
   ,PSL.LinkTarget
   ,PSL.LinkStatusTypeId
   ,0 AS IsDeleted
   ,GETUTCDATE() AS CreateDate
   ,@UserId AS CreatedBy
   ,CLRT.SrcProjectId AS ProjectId
   ,@CustomerId AS CustomerId
   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId INTO #TempProjectSegmentLinkAcrossSectionLink
FROM #ProjectSegmentLinkTBL PSL
INNER JOIN #NewSegmentTable CLRT
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND PSL.SourceSectionCode <> PSL.TargetSectionCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
AND PSL.CustomerId = @CustomerId


--Validate Data and Insert into Original Table
INSERT INTO ProjectSegmentLink (SourceSectionCode
, SourceSegmentStatusCode
, SourceSegmentCode
, SourceSegmentChoiceCode
, SourceChoiceOptionCode
, LinkSource
, TargetSectionCode
, TargetSegmentStatusCode
, TargetSegmentCode
, TargetSegmentChoiceCode
, TargetChoiceOptionCode
, LinkTarget
, LinkStatusTypeId
, IsDeleted
, CreateDate
, CreatedBy
, ProjectId
, CustomerId
, SegmentLinkSourceTypeId)

	SELECT DISTINCT
		CLRT.SourceSectionCode
	   ,CLRT.SourceSegmentStatusCode
	   ,CLRT.SourceSegmentCode
	   ,IIF(CLRT.SourceSegmentChoiceCode = 0, NULL, CLRT.SourceSegmentChoiceCode)
	   ,IIF(CLRT.SourceChoiceOptionCode = 0, NULL, CLRT.SourceChoiceOptionCode)
	   ,CLRT.LinkSource
	   ,CLRT.TargetSectionCode
	   ,CLRT.TargetSegmentStatusCode
	   ,CLRT.TargetSegmentCode
	   ,IIF(CLRT.TargetSegmentChoiceCode = 0, NULL, CLRT.TargetSegmentChoiceCode)
	   ,IIF(CLRT.TargetChoiceOptionCode = 0, NULL, CLRT.TargetChoiceOptionCode)
	   ,CLRT.LinkTarget
	   ,CLRT.LinkStatusTypeId
	   ,CLRT.IsDeleted
	   ,CLRT.CreateDate
	   ,CLRT.CreatedBy
	   ,CLRT.ProjectId
	   ,CLRT.CustomerId
	   ,CLRT.SegmentLinkSourceTypeId
	FROM #TempProjectSegmentLinkAcrossSectionLink CLRT
	LEFT OUTER JOIN #ProjectSegmentLinkTBL PSLTBL
		ON CLRT.ProjectId = PSLTBL.ProjectId
			AND CLRT.SourceSectionCode = PSLTBL.SourceSectionCode
			AND CLRT.SourceSegmentStatusCode = PSLTBL.SourceSegmentStatusCode
			AND CLRT.SourceSegmentCode = PSLTBL.SourceSegmentCode
			AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSLTBL.SourceChoiceOptionCode, 0)
			AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSLTBL.SourceSegmentChoiceCode, 0)
			AND PSLTBL.CustomerId = @CustomerId
			AND PSLTBL.IsDeleted = 0
	WHERE PSLTBL.SegmentLinkId IS NULL

----END Cross Link Logic----------------------------

----START Within Branch Link Logic----------------------------

---Get all links which Target and Source have same sectionCode .
SELECT DISTINCT
	CLRT.TrgSectionCode AS SourceSectionCode
   ,CLRT.TrgSegmentStatusCode AS SourceSegmentStatusCode
   ,CLRT.TrgSegmentCode AS SourceSegmentCode
   ,IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode) AS SourceSegmentChoiceCode
   ,IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode) AS SourceChoiceOptionCode
   ,'U' AS LinkSource
   ,PSL.TargetSectionCode
   ,PSL.TargetSegmentStatusCode
   ,PSL.TargetSegmentCode
   ,PSL.TargetSegmentChoiceCode
   ,PSL.TargetChoiceOptionCode
   ,PSL.LinkTarget
   ,PSL.LinkStatusTypeId
   ,0 AS IsDeleted
   ,GETUTCDATE() AS CreateDate
   ,@UserId AS CreatedBy
   ,CLRT.SrcProjectId AS ProjectId
   ,@CustomerId AS CustomerId
   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId INTO #TempProjectSegmentLink
FROM #ProjectSegmentLinkTBL PSL
INNER JOIN #NewSegmentTable CLRT
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND PSL.SourceSectionCode = PSL.TargetSectionCode
		AND PSL.SourceSectionCode=PSL.TargetSectionCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
AND PSL.CustomerId = @CustomerId

---Validate the Data ---
SELECT DISTINCT
	CLRT.SourceSectionCode
   ,CLRT.SourceSegmentStatusCode
   ,CLRT.SourceSegmentCode
   ,CLRT.SourceSegmentChoiceCode
   ,CLRT.SourceChoiceOptionCode
   ,CLRT.LinkSource
   ,CLRT.TargetSectionCode
   ,CLRT.TargetSegmentStatusCode
   ,CLRT.TargetSegmentCode
   ,CLRT.TargetSegmentChoiceCode
   ,CLRT.TargetChoiceOptionCode
   ,CLRT.LinkTarget
   ,CLRT.LinkStatusTypeId
   ,CLRT.IsDeleted
   ,CLRT.CreateDate
   ,CLRT.CreatedBy
   ,CLRT.ProjectId
   ,CLRT.CustomerId
   ,CLRT.SegmentLinkSourceTypeId INTO #TempBranchLinkTable
FROM #TempProjectSegmentLink CLRT
LEFT OUTER JOIN #ProjectSegmentLinkTBL psl
	ON CLRT.ProjectId = PSL.ProjectId
		AND CLRT.SourceSectionCode = PSL.SourceSectionCode
		AND CLRT.SourceSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SourceSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
		AND psl.CustomerId = @CustomerId
		AND psl.IsDeleted = 0
WHERE psl.SegmentLinkId IS NULL

---Update Newly Created Segment details in temp table
UPDATE PSL
SET PSL.TargetSectionCode = CLRT.TrgSectionCode
   ,PSL.TargetSegmentStatusCode = CLRT.TrgSegmentStatusCode
   ,PSL.TargetSegmentCode = CLRT.TrgSegmentCode
   ,PSL.TargetSegmentChoiceCode = IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode)
   ,PSL.TargetChoiceOptionCode = IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode)
   ,PSL.LinkTarget = 'U'
FROM #TempBranchLinkTable PSL 
INNER JOIN #NewSegmentTable CLRT
	ON CLRT.SrcProjectId = PSL.ProjectId
	AND CLRT.SrcSectionCode = PSL.TargetSectionCode
	AND ISNULL(PSL.IsDeleted, 0) = 0
	AND CLRT.SrcSegmentStatusCode = PSL.TargetSegmentStatusCode
	AND CLRT.SrcSegmentCode = PSL.TargetSegmentCode
	AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.TargetChoiceOptionCode, 0)
	AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.TargetSegmentChoiceCode, 0)
INNER JOIN #TempProjectSegmentLink SRCPSL
	ON PSL.ProjectId = SRCPSL.ProjectId
	AND PSL.SourceSectionCode = SRCPSL.SourceSectionCode
	AND PSL.SourceSegmentStatusCode = SRCPSL.SourceSegmentStatusCode
	AND PSL.SourceSegmentCode = SRCPSL.SourceSegmentCode
	AND ISNULL(PSL.SourceChoiceOptionCode, 0) = ISNULL(SRCPSL.SourceChoiceOptionCode, 0)
	AND ISNULL(PSL.SourceSegmentChoiceCode, 0) = ISNULL(SRCPSL.SourceSegmentChoiceCode, 0)
AND PSL.CustomerId = @CustomerId
WHERE PSL.LinkSource = 'U'

--- Insert final result into Original Table 
INSERT INTO ProjectSegmentLink (SourceSectionCode
, SourceSegmentStatusCode
, SourceSegmentCode
, SourceSegmentChoiceCode
, SourceChoiceOptionCode
, LinkSource
, TargetSectionCode
, TargetSegmentStatusCode
, TargetSegmentCode
, TargetSegmentChoiceCode
, TargetChoiceOptionCode
, LinkTarget
, LinkStatusTypeId
, IsDeleted
, CreateDate
, CreatedBy
, ProjectId
, CustomerId
, SegmentLinkSourceTypeId)

	SELECT
	DISTINCT
		SourceSectionCode
	   ,SourceSegmentStatusCode
	   ,SourceSegmentCode
	   ,SourceSegmentChoiceCode
	   ,SourceChoiceOptionCode
	   ,LinkSource
	   ,TargetSectionCode
	   ,TargetSegmentStatusCode
	   ,TargetSegmentCode
	   ,TargetSegmentChoiceCode
	   ,TargetChoiceOptionCode
	   ,LinkTarget
	   ,LinkStatusTypeId
	   ,IsDeleted
	   ,CreateDate
	   ,CreatedBy
	   ,ProjectId
	   ,CustomerId
	   ,SegmentLinkSourceTypeId
	FROM #TempBranchLinkTable
	WHERE LinkTarget = 'U'

----END Within Branch Link Logic----------------------------

END
GO
PRINT N'Creating [dbo].[usp_CopyBranchLinks]...';


GO
CREATE PROCEDURE usp_CopyBranchLinks   
(  
 @UserId INT,  
 @CustomerId int,
 @NewSegmentsJson NVARCHAR(MAX)  
)  
AS  
BEGIN
  
   
 DECLARE @CreatedBy INT = @UserId,@SegmentLinkSourceTypeId int=5;

SELECT
	* INTO #NewSegmentTable
FROM OPENJSON(@NewSegmentsJson) WITH (
RowId INT '$.RowId',
SrcChoiceOptionCode INT '$.SrcChoiceOptionCode',
SrcProjectId INT '$.SrcProjectId',
SrcSectionCode INT '$.SrcSectionCode',
SrcSectionId INT '$.SrcSectionId',
SrcSegmentChoiceCode INT '$.SrcSegmentChoiceCode',
SrcSegmentCode INT '$.SrcSegmentCode',
SrcSegmentId INT '$.SrcSegmentId',
SrcSegmentStatusCode INT '$.SrcSegmentStatusCode',
SrcSegmentStatusId INT '$.SrcSegmentStatusId',
TrgChoiceOptionCode INT '$.TrgChoiceOptionCode',
TrgProjectId INT '$.TrgProjectId',
TrgSectionCode INT '$.TrgSectionCode',
TrgSectionId INT '$.TrgSectionId',
TrgSegmentChoiceCode INT '$.TrgSegmentChoiceCode',
TrgSegmentCode INT '$.TrgSegmentCode',
TrgSegmentId INT '$.TrgSegmentId',
TrgSegmentStatusCode INT '$.TrgSegmentStatusCode',
TrgSegmentStatusId INT '$.TrgSegmentStatusId'
);


DECLARE @ProjectId INT = 0
	   ,@SectionCode INT = 0
	   ,@SectionId INT = 0
	   ,@SourceSegmentCode INT = 0;

SELECT TOP 1
	@ProjectId = SrcProjectId
   ,@SectionCode = SrcSectionCode
   ,@SectionId = TrgSectionId
   ,@SourceSegmentCode = TrgSegmentCode
FROM #NewSegmentTable

SELECT
	SourceSectionCode
   ,SourceSegmentStatusCode
   ,SourceSegmentCode
   ,SourceSegmentChoiceCode
   ,SourceChoiceOptionCode
   ,TargetSectionCode
   ,TargetSegmentStatusCode
   ,TargetSegmentCode
   ,TargetSegmentChoiceCode
   ,TargetChoiceOptionCode
   ,LinkTarget
   ,LinkStatusTypeId
   ,CustomerId
   ,IsDeleted
   ,ProjectId
   ,SegmentLinkId INTO #ProjectSegmentLinkTBL
FROM ProjectSegmentLink WITH (NOLOCK)
WHERE ProjectId = @ProjectId
AND  CustomerId = @CustomerId
AND SourceSectionCode = @SectionCode

---Get all Links
SELECT DISTINCT
	CLRT.TrgSectionCode AS SourceSectionCode
   ,CLRT.TrgSegmentStatusCode AS SourceSegmentStatusCode
   ,CLRT.TrgSegmentCode AS SourceSegmentCode
   ,IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode) AS SourceSegmentChoiceCode
   ,IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode) AS SourceChoiceOptionCode
   ,'U' AS LinkSource
   ,PSL.TargetSectionCode
   ,PSL.TargetSegmentStatusCode
   ,PSL.TargetSegmentCode
   ,PSL.TargetSegmentChoiceCode
   ,PSL.TargetChoiceOptionCode
   ,PSL.LinkTarget
   ,PSL.LinkStatusTypeId
   ,0 AS IsDeleted
   ,GETUTCDATE() AS CreateDate
   ,@UserId AS CreatedBy
   ,CLRT.SrcProjectId AS ProjectId
   ,@CustomerId AS CustomerId
   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId INTO #TempProjectSegmentLink
FROM #ProjectSegmentLinkTBL PSL 
INNER JOIN #NewSegmentTable CLRT
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
AND PSL.CustomerId = @CustomerId 

---Validate and insert data into ProjectSegmentLink Table

INSERT INTO ProjectSegmentLink (SourceSectionCode
, SourceSegmentStatusCode
, SourceSegmentCode
, SourceSegmentChoiceCode
, SourceChoiceOptionCode
, LinkSource
, TargetSectionCode
, TargetSegmentStatusCode
, TargetSegmentCode
, TargetSegmentChoiceCode
, TargetChoiceOptionCode
, LinkTarget
, LinkStatusTypeId
, IsDeleted
, CreateDate
, CreatedBy
, ProjectId
, CustomerId
, SegmentLinkSourceTypeId)

	SELECT DISTINCT
		CLRT.SourceSectionCode
	   ,CLRT.SourceSegmentStatusCode
	   ,CLRT.SourceSegmentCode
	   ,IIF(CLRT.SourceSegmentChoiceCode = 0, NULL, CLRT.SourceSegmentChoiceCode)
	   ,IIF(CLRT.SourceChoiceOptionCode = 0, NULL, CLRT.SourceChoiceOptionCode)
	   ,CLRT.LinkSource
	   ,CLRT.TargetSectionCode
	   ,CLRT.TargetSegmentStatusCode
	   ,CLRT.TargetSegmentCode
	   ,IIF(CLRT.TargetSegmentChoiceCode = 0, NULL, CLRT.TargetSegmentChoiceCode)
	   ,IIF(CLRT.TargetChoiceOptionCode = 0, NULL, CLRT.TargetChoiceOptionCode)
	   ,CLRT.LinkTarget
	   ,CLRT.LinkStatusTypeId
	   ,CLRT.IsDeleted
	   ,CLRT.CreateDate
	   ,CLRT.CreatedBy
	   ,CLRT.ProjectId
	   ,CLRT.CustomerId
	   ,CLRT.SegmentLinkSourceTypeId
	FROM #TempProjectSegmentLink CLRT
	LEFT OUTER JOIN #ProjectSegmentLinkTBL PSLTBL
		ON CLRT.ProjectId = PSLTBL.ProjectId
			AND CLRT.SourceSectionCode = PSLTBL.SourceSectionCode
			AND CLRT.SourceSegmentStatusCode = PSLTBL.SourceSegmentStatusCode
			AND CLRT.SourceSegmentCode = PSLTBL.SourceSegmentCode
			AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSLTBL.SourceChoiceOptionCode, 0)
			AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSLTBL.SourceSegmentChoiceCode, 0)
			AND PSLTBL.CustomerId = @CustomerId
			AND PSLTBL.IsDeleted = 0
	WHERE PSLTBL.SegmentLinkId IS NULL

---Update Within branch newly created segment details.
UPDATE PSL
SET PSL.TargetSectionCode = CLRT.TrgSectionCode
   ,PSL.TargetSegmentStatusCode = CLRT.TrgSegmentStatusCode
   ,PSL.TargetSegmentCode = CLRT.TrgSegmentCode
   ,PSL.TargetSegmentChoiceCode = IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode)
   ,PSL.TargetChoiceOptionCode = IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode)
   ,PSL.LinkTarget = 'U'
FROM ProjectSegmentLink PSL WITH (NOLOCK)
INNER JOIN #NewSegmentTable CLRT
	ON CLRT.SrcProjectId = PSL.ProjectId
	AND CLRT.SrcSectionCode = PSL.TargetSectionCode
	AND ISNULL(PSL.IsDeleted, 0) = 0
	AND CLRT.SrcSegmentStatusCode = PSL.TargetSegmentStatusCode
	AND CLRT.SrcSegmentCode = PSL.TargetSegmentCode
	AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.TargetChoiceOptionCode, 0)
	AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.TargetSegmentChoiceCode, 0)
INNER JOIN #TempProjectSegmentLink SRCPSL
	ON PSL.ProjectId = SRCPSL.ProjectId
	AND PSL.SourceSectionCode = SRCPSL.SourceSectionCode
	AND PSL.SourceSegmentStatusCode = SRCPSL.SourceSegmentStatusCode
	AND PSL.SourceSegmentCode = SRCPSL.SourceSegmentCode
	AND ISNULL(PSL.SourceChoiceOptionCode, 0) = ISNULL(SRCPSL.SourceChoiceOptionCode, 0)
	AND ISNULL(PSL.SourceSegmentChoiceCode, 0) = ISNULL(SRCPSL.SourceSegmentChoiceCode, 0)
WHERE PSL.LinkSource = 'U' AND PSL.CustomerId = @CustomerId

END
GO
PRINT N'Creating [dbo].[usp_CreateCopiedLinks]...';


GO
CREATE PROCEDURE [dbo].[usp_CreateCopiedLinks]  
(    
     
 @UserId int ,    
 @CustomerId int    ,
 @IsCopyLinkUndoRedo BIT,
 @IsCopyCrossLinks BIT,
 @CopyLinkRequestJson NVARCHAR(MAX)

)    
AS    
BEGIN
    
    
 DECLARE @SegmentLinkSourceTypeId INT = 5;
 -- User created link  

	SELECT
		SrcChoiceOptionCode
	   ,SrcProjectId
	   ,SrcSectionCode
	   ,SrcSectionId
	   ,SrcSegmentChoiceCode
	   ,SrcSegmentCode
	   ,SrcSegmentId
	   ,SrcSegmentStatusCode
	   ,SrcSegmentStatusId
	   ,TrgChoiceOptionCode
	   ,TrgProjectId
	   ,TrgSectionCode
	   ,TrgSectionId
	   ,TrgSegmentChoiceCode
	   ,TrgSegmentCode
	   ,TrgSegmentId
	   ,TrgSegmentStatusCode
	   ,TrgSegmentStatusId  INTO #CopyLinkRequestTable
	FROM OPENJSON(@CopyLinkRequestJson) WITH (
	--LinkType INT '$.LinkType',  
	SrcChoiceOptionCode INT '$.SrcChoiceOptionCode',
	SrcProjectId INT '$.SrcProjectId',
	SrcSectionCode INT '$.SrcSectionCode',
	SrcSectionId INT '$.SrcSectionId',
	SrcSegmentChoiceCode INT '$.SrcSegmentChoiceCode',
	SrcSegmentCode INT '$.SrcSegmentCode',
	SrcSegmentId INT '$.SrcSegmentId',
	SrcSegmentStatusCode INT '$.SrcSegmentStatusCode',
	SrcSegmentStatusId INT '$.SrcSegmentStatusId',
	TrgChoiceOptionCode INT '$.TrgChoiceOptionCode',
	TrgProjectId INT '$.TrgProjectId',
	TrgSectionCode INT '$.TrgSectionCode',
	TrgSectionId INT '$.TrgSectionId',
	TrgSegmentChoiceCode INT '$.TrgSegmentChoiceCode',
	TrgSegmentCode INT '$.TrgSegmentCode',
	TrgSegmentId INT '$.TrgSegmentId',
	TrgSegmentStatusCode INT '$.TrgSegmentStatusCode',
	TrgSegmentStatusId INT '$.TrgSegmentStatusId'
	);

DROP TABLE IF EXISTS #TempProjectSegmentLink, #ProjectSegmentLinkTBL

DECLARE @ProjectId INT = 0
	   ,@SectionCode INT = 0
	   ,@SectionId INT = 0
	   ,@SourceSegmentCode INT = 0;

SELECT TOP 1
	@ProjectId = SrcProjectId
   ,@SectionCode = SrcSectionCode
   ,@SectionId = TrgSectionId
   ,@SourceSegmentCode = TrgSegmentCode
FROM #CopyLinkRequestTable

SELECT
	SourceSectionCode
   ,SourceSegmentStatusCode
   ,SourceSegmentCode
   ,SourceSegmentChoiceCode
   ,SourceChoiceOptionCode
   ,TargetSectionCode
   ,TargetSegmentStatusCode
   ,TargetSegmentCode
   ,TargetSegmentChoiceCode
   ,TargetChoiceOptionCode
   ,LinkTarget
   ,LinkStatusTypeId
   ,CustomerId
   ,IsDeleted
   ,ProjectId
   ,SegmentLinkId INTO #ProjectSegmentLinkTBL
FROM ProjectSegmentLink WITH (NOLOCK)
WHERE ProjectId = @ProjectId 
AND CustomerId = @CustomerId
AND SourceSectionCode = @SectionCode

IF (@IsCopyCrossLinks = 0)
BEGIN

SELECT DISTINCT
	CLRT.TrgSectionCode AS SourceSectionCode
   ,CLRT.TrgSegmentStatusCode AS SourceSegmentStatusCode
   ,CLRT.TrgSegmentCode AS SourceSegmentCode
   ,IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode) AS SourceSegmentChoiceCode
   ,IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode) AS SourceChoiceOptionCode
   ,'U' AS LinkSource
   ,PSL.TargetSectionCode
   ,PSL.TargetSegmentStatusCode
   ,PSL.TargetSegmentCode
   ,PSL.TargetSegmentChoiceCode
   ,PSL.TargetChoiceOptionCode
   ,PSL.LinkTarget
   ,PSL.LinkStatusTypeId
   ,0 AS IsDeleted
   ,GETUTCDATE() AS CreateDate
   ,@UserId AS CreatedBy
   ,CLRT.SrcProjectId AS ProjectId
   ,@CustomerId AS CustomerId
   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId INTO #TempProjectSegmentLink
FROM #CopyLinkRequestTable CLRT  
INNER JOIN #ProjectSegmentLinkTBL PSL 
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND ISNULL(PSL.IsDeleted, 0) =0
		--CASE
		--	WHEN @IsCopyLinkUndoRedo = 0 THEN 0
		--	WHEN @IsCopyLinkUndoRedo = 1 THEN 1
		--	ELSE 0
		--END
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
WHERE PSL.CustomerId = @CustomerId


INSERT INTO ProjectSegmentLink (SourceSectionCode
, SourceSegmentStatusCode
, SourceSegmentCode
, SourceSegmentChoiceCode
, SourceChoiceOptionCode
, LinkSource
, TargetSectionCode
, TargetSegmentStatusCode
, TargetSegmentCode
, TargetSegmentChoiceCode
, TargetChoiceOptionCode
, LinkTarget
, LinkStatusTypeId
, IsDeleted
, CreateDate
, CreatedBy
, ProjectId
, CustomerId
, SegmentLinkSourceTypeId)

	SELECT DISTINCT
		CLRT.SourceSectionCode
	   ,CLRT.SourceSegmentStatusCode
	   ,CLRT.SourceSegmentCode
	   ,CLRT.SourceSegmentChoiceCode
	   ,CLRT.SourceChoiceOptionCode
	   ,CLRT.LinkSource
	   ,CLRT.TargetSectionCode
	   ,CLRT.TargetSegmentStatusCode
	   ,CLRT.TargetSegmentCode
	   ,CLRT.TargetSegmentChoiceCode
	   ,CLRT.TargetChoiceOptionCode
	   ,CLRT.LinkTarget
	   ,CLRT.LinkStatusTypeId
	   ,CLRT.IsDeleted
	   ,CLRT.CreateDate
	   ,CLRT.CreatedBy
	   ,CLRT.ProjectId
	   ,CLRT.CustomerId
	   ,CLRT.SegmentLinkSourceTypeId
	FROM #TempProjectSegmentLink CLRT
	LEFT OUTER JOIN #ProjectSegmentLinkTBL psl
		ON CLRT.ProjectId = PSL.ProjectId
			AND CLRT.SourceSectionCode = PSL.SourceSectionCode
			AND CLRT.SourceSegmentStatusCode = PSL.SourceSegmentStatusCode
			AND CLRT.SourceSegmentCode = PSL.SourceSegmentCode
			AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
			AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
			AND psl.CustomerId = @CustomerId
			AND psl.IsDeleted = 0
	WHERE psl.SegmentLinkId IS NULL



END
ELSE
BEGIN

SELECT DISTINCT
	CLRT.TrgSectionCode AS SourceSectionCode
   ,CLRT.TrgSegmentStatusCode AS SourceSegmentStatusCode
   ,CLRT.TrgSegmentCode AS SourceSegmentCode
   ,IIF(CLRT.TrgSegmentChoiceCode = 0, NULL, CLRT.TrgSegmentChoiceCode) AS SourceSegmentChoiceCode
   ,IIF(CLRT.TrgChoiceOptionCode = 0, NULL, CLRT.TrgChoiceOptionCode) AS SourceChoiceOptionCode
   ,'U' AS LinkSource
   ,PSL.TargetSectionCode
   ,PSL.TargetSegmentStatusCode
   ,PSL.TargetSegmentCode
   ,PSL.TargetSegmentChoiceCode
   ,PSL.TargetChoiceOptionCode
   ,PSL.LinkTarget
   ,PSL.LinkStatusTypeId
   ,0 AS IsDeleted
   ,GETUTCDATE() AS CreateDate
   ,@UserId AS CreatedBy
   ,CLRT.SrcProjectId AS ProjectId
   ,@CustomerId AS CustomerId
   ,@SegmentLinkSourceTypeId AS SegmentLinkSourceTypeId INTO #TempProjectSegmentLinkCrossSection
FROM #CopyLinkRequestTable CLRT 
INNER JOIN #ProjectSegmentLinkTBL PSL
	ON CLRT.SrcProjectId = PSL.ProjectId
		AND CLRT.SrcSectionCode = PSL.SourceSectionCode
		AND PSL.SourceSectionCode <> PSL.TargetSectionCode
		AND CLRT.SrcSegmentStatusCode = PSL.SourceSegmentStatusCode
		AND CLRT.SrcSegmentCode = PSL.SourceSegmentCode
		AND ISNULL(CLRT.SrcChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
		AND ISNULL(CLRT.SrcSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
		AND ISNULL(PSL.IsDeleted, 0) =0
		--CASE
		--	WHEN @IsCopyLinkUndoRedo  = 0 THEN 0
		--	WHEN @IsCopyLinkUndoRedo = 1 THEN 1
		--	ELSE 0
		--END
WHERE PSL.CustomerId = @CustomerId

INSERT INTO ProjectSegmentLink (SourceSectionCode
, SourceSegmentStatusCode
, SourceSegmentCode
, SourceSegmentChoiceCode
, SourceChoiceOptionCode
, LinkSource
, TargetSectionCode
, TargetSegmentStatusCode
, TargetSegmentCode
, TargetSegmentChoiceCode
, TargetChoiceOptionCode
, LinkTarget
, LinkStatusTypeId
, IsDeleted
, CreateDate
, CreatedBy
, ProjectId
, CustomerId
, SegmentLinkSourceTypeId)

	SELECT DISTINCT
		CLRT.SourceSectionCode
	   ,CLRT.SourceSegmentStatusCode
	   ,CLRT.SourceSegmentCode
	   ,CLRT.SourceSegmentChoiceCode
	   ,CLRT.SourceChoiceOptionCode
	   ,CLRT.LinkSource
	   ,CLRT.TargetSectionCode
	   ,CLRT.TargetSegmentStatusCode
	   ,CLRT.TargetSegmentCode
	   ,CLRT.TargetSegmentChoiceCode
	   ,CLRT.TargetChoiceOptionCode
	   ,CLRT.LinkTarget
	   ,CLRT.LinkStatusTypeId
	   ,CLRT.IsDeleted
	   ,CLRT.CreateDate
	   ,CLRT.CreatedBy
	   ,CLRT.ProjectId
	   ,CLRT.CustomerId
	   ,CLRT.SegmentLinkSourceTypeId
	FROM #TempProjectSegmentLinkCrossSection CLRT
	LEFT OUTER JOIN #ProjectSegmentLinkTBL psl
		ON CLRT.ProjectId = PSL.ProjectId
			AND CLRT.SourceSectionCode = PSL.SourceSectionCode
			AND CLRT.SourceSegmentStatusCode = PSL.SourceSegmentStatusCode
			AND CLRT.SourceSegmentCode = PSL.SourceSegmentCode
			AND ISNULL(CLRT.SourceChoiceOptionCode, 0) = ISNULL(PSL.SourceChoiceOptionCode, 0)
			AND ISNULL(CLRT.SourceSegmentChoiceCode, 0) = ISNULL(PSL.SourceSegmentChoiceCode, 0)
			AND psl.CustomerId = @CustomerId
			AND psl.IsDeleted = 0
	WHERE psl.SegmentLinkId IS NULL


END

END
GO
PRINT N'Creating [dbo].[usp_CreateMultipleSegments]...';


GO
CREATE PROCEDURE usp_CreateMultipleSegments  
(  
@UserId int,
 @NewSegmentsJson NVARCHAR(MAX)  
)  
AS  
BEGIN  
   
 -- TODO -- Need to pass from api  
 DECLARE @CreatedBy INT = @UserId;  
   
 SELECT *   
 INTO #NewSegmentTable  
 FROM OPENJSON(@NewSegmentsJson) WITH (  
  RowId int '$.RowId',  
  SectionId int '$.SectionId',  
  ParentSegmentStatusId int '$.ParentSegmentStatusId',  
  IndentLevel int '$.IndentLevel',  
  SpecTypeTagId int '$.SpecTypeTagId',  
  SegmentStatusTypeId int '$.SegmentStatusTypeId',  
  IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive',  
  ProjectId int '$.ProjectId',  
  CustomerId int '$.CustomerId',  
  CreatedBy int '$.CreatedBy',  
  SegmentDescription NVARCHAR(MAX) '$.SegmentDescription',  
  SequenceNumber DECIMAL(18,4) '$.SequenceNumber',  
  IsRefStdParagraph BIT '$.IsRefStdParagraph',  
    
  OriginalSegmentStatusId int '$.OriginalSegmentStatusId',  
  OriginalParentSegmentStatusId int '$.OriginalParentSegmentStatusId',  
  SegmentId int '$.SegmentId',  
  SegmentStatusCode int '$.SegmentStatusCode',  
  SegmentCode int '$.SegmentCode',  
    
  SrcSectionId int '$.SrcSectionId',  
  SrcProjectId int '$.SrcProjectId',  
  SrcSectionCode int '$.SrcSectionCode',  
  SrcSegmentStatusCode int '$.SrcSegmentStatusCode',  
  SrcSegmentCode int '$.SrcSegmentCode'  
  );  
  
 --SELECT * FROM #NewSegmentTable;  
  
 DECLARE @RowNumber INT = 1;  
 DECLARE @TotalRows INT = 0;  
 SELECT @TotalRows = COUNT(1) FROM #NewSegmentTable;  
  
 WHILE @RowNumber <= @TotalRows  
 BEGIN  
  
  INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, 
  CustomerId, IsShowAutoNumber, FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsRefStdParagraph)  
  SELECT   
   NST.SectionId  
  ,NST.ParentSegmentStatusId  
  ,0 AS mSegmentStatusId  
     ,0 AS mSegmentId  
     ,0 AS SegmentId  
     ,'U' AS SegmentSource  
     ,'U' AS SegmentOrigin  
     ,NST.IndentLevel  
  ,NST.SequenceNumber,  
  (CASE  
   WHEN NST.SpecTypeTagId = 0 THEN NULL  
   ELSE NST.SpecTypeTagId  
  END) AS SpecTypeTagId,   
  NST.SegmentStatusTypeId,   
  NST.IsParentSegmentStatusActive,   
  NST.ProjectId,   
  NST.CustomerId  
  ,1 AS IsShowAutoNumber  
    ,NULL AS FormattingJson  
    ,GETUTCDATE() AS CreateDate  
    ,@CreatedBy AS CreatedBy  
    ,NULL AS ModifiedDate  
    ,NULL AS ModifiedBy  
    ,NST.IsRefStdParagraph     
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
  
  DECLARE @SegmentStatusId AS INT = SCOPE_IDENTITY();  
  
  INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)  
  SELECT  
   @SegmentStatusId AS SegmentStatusId  
     ,NST.SectionId  
     ,NST.ProjectId  
     ,NST.CustomerId  
     ,NST.SegmentDescription  
     ,'U' AS SegmentSource  
     ,@CreatedBy AS CreatedBy  
     ,GETUTCDATE() AS CreateDate  
     ,NULL AS ModifiedBy  
     ,NULL AS ModifiedDate  
	 
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
  
  DECLARE @SegmentId AS INT = SCOPE_IDENTITY();  
  
  UPDATE PSS  
  SET PSS.SegmentId = @SegmentId  
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)  
  WHERE PSS.SegmentStatusId = @SegmentStatusId;  
  
  DECLARE @SegmentStatusCode INT, @SegmentCode INT;  
  SELECT @SegmentStatusCode = PSS.SegmentStatusCode FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SegmentStatusId = @SegmentStatusId;  
  SELECT @SegmentCode = PS.SegmentCode FROM ProjectSegment PS WITH (NOLOCK) WHERE PS.SegmentId = @SegmentId  
  
  UPDATE NST  
  SET NST.OriginalSegmentStatusId = @SegmentStatusId  
     ,NST.OriginalParentSegmentStatusId = NST.ParentSegmentStatusId  
     ,NST.SegmentId = @SegmentId  
     ,NST.SegmentStatusCode = @SegmentStatusCode  
     ,NST.SegmentCode = @SegmentCode  
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
  
  DECLARE @IsRefStdParagraph BIT = 0, @PProjectId INT, @PSectionId INT, @PCustomerId INT, @SegmentDescription NVARCHAR(MAX) = '';  
  SELECT @IsRefStdParagraph =  NST.IsRefStdParagraph,   
      @SegmentDescription =  NST.SegmentDescription,  
      @PProjectId =  NST.ProjectId,  
      @PSectionId =  NST.SectionId,  
      @PCustomerId =  NST.CustomerId  
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
    
  ----NOW CREATE SEGMENT REQUIREMENT TAG IF SEGMENT IS OF RS TYPE  
  IF ISNULL(@IsRefStdParagraph, 0) = 1  
   BEGIN  
    EXEC usp_CreateSegmentRequirementTag @PCustomerId  
             ,@PProjectId  
             ,@PSectionId  
             ,@SegmentStatusId  
             ,'RS'  
             ,@CreatedBy  
    EXEC usp_CreateSpecialLinkForRsReTaggedSegment @PCustomerId  
                 ,@PProjectId  
                 ,@PSectionId  
                 ,@SegmentStatusId  
                 ,@CreatedBy  
  --START- Added Block for Regression Bug 40872  
  DECLARE @RSCode INT = 0 , @RsSegmentDescription nvarchar(max)= @SegmentDescription,@PRefStandardId INT = 0 , @PRefStdCode INT = 0;      
      
      SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)       
      FROM (SELECT SUBSTRING(@RsSegmentDescription, PATINDEX('%[0-9]%', @RsSegmentDescription), LEN(@RsSegmentDescription)) Val) RSCode  
  
  SELECT TOP 1   
  @PRefStandardId = RefStdId,  
  @PRefStdCode = RefStdCode  
  FROM ReferenceStandard WITH (NOLOCK) WHERE RefStdCode=@RSCode AND CustomerId= @PCustomerId  
  
  INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode)  
   VALUES (@PSectionId, @SegmentId, @PRefStandardId, 'U', 0, GETUTCDATE(), @CreatedBy, GETUTCDATE(), NULL, @PCustomerId, @PProjectId, null, @PRefStdCode)  
  
  ----END Block  
  
  END  
  
  SET @RowNumber = @RowNumber + 1;  
  
 END  
  
 SELECT NST.RowId  
    ,NST.OriginalSegmentStatusId  
    ,NST.OriginalParentSegmentStatusId  
    ,NST.SegmentId  
    ,NST.SegmentStatusCode  
    ,NST.SegmentCode  
 FROM #NewSegmentTable NST WITH(NOLOCK);  
  
END
GO
PRINT N'Creating [dbo].[usp_GetBIM360Credentials]...';


GO

CREATE PROCEDURE [dbo].[usp_GetBIM360Credentials]   
(    
@customerId INT    
)    
AS    
BEGIN



SELECT
	CustomerId ,iif(IsActive =1,ClientId,'') As ClientId ,iif(IsActive =1,ClientSecret,'') As ClientSecret ,IsActive ,ModifiedDate ,ModifiedBy ,CreatedBy ,CreatedDate
FROM BIM360AccessKey  WITH (NOLOCK)
where customerId =@customerId


END
GO
PRINT N'Creating [dbo].[usp_GetIncomingTransferProjects]...';


GO
CREATE PROCEDURE usp_GetIncomingTransferProjects (            
   @UserId INT,            
   @IsSystemManager BIT,            
   @CustomerId INT,            
   @IsOfficeMaster BIT            
)             
AS            
BEGIN             
            
 DECLARE @PCustomerId INT = @CustomerId;            
 DECLARE @PUserId INT = @UserId;            
 DECLARE @PIsOfficeMasterTab BIT = @IsOfficeMaster;            
 DECLARE @PIsSystemManager BIT = @IsSystemManager;            
 DECLARE @StatusCompleted INT =3          
 DROP TABLE IF EXISTS #IncomingProjectList;            
 DECLARE @DateBefore30Days DATETIME=DATEADD(DAY,-30,GETUTCDATE())             
 CREATE TABLE #IncomingProjectList  (            
  ProjectId INT,            
  ProjectName NVARCHAR(255),            
  ProjectAccessTypeId INT,            
  IsProjectAccessible BIT,            
  ProjectAccessTypeName NVARCHAR(100)            
 );            
             
 IF(@PIsSystemManager = 1)             
 BEGIN            
  INSERT INTO #IncomingProjectList            
  SELECT            
     P.ProjectId,            
     P.[Name] AS ProjectName,            
     PS.ProjectAccessTypeId,            
     1 as IsProjectAccessible,            
     '' as ProjectAccessTypeName            
  FROM Project AS P WITH (NOLOCK)            
     INNER JOIN [dbo].[ProjectSummary] PS WITH (NOLOCK) ON PS.ProjectId = P.ProjectId            
     LEFT JOIN UserFolder UF WITH (NOLOCK) ON UF.ProjectId = P.ProjectId            
     AND UF.customerId = P.CustomerId            
  WHERE ISNULL(p.IsDeleted, 0) = 0      
     AND ISNULL(p.IsPermanentDeleted, 0) = 0         
     AND ISNULL(p.IsArchived, 0) = 0            
     AND P.IsOfficeMaster = @PIsOfficeMasterTab            
     AND P.CustomerId = @PCustomerId            
     AND ISNULL(P.IsIncomingProject, 0) = 1      
  AND P.TransferredDate > @DateBefore30Days;     
 END            
 ELSE             
 BEGIN             
  DROP TABLE IF EXISTS #AccessibleProjectIds;            
            
  CREATE TABLE #AccessibleProjectIds(            
   ProjectId INT,            
   ProjectAccessTypeId INT,            
   IsProjectAccessible bit,            
   ProjectAccessTypeName NVARCHAR(100),            
   IsProjectOwner BIT            
  );            
              
  ---Get all public,private and owned projects            
  INSERT INTO #AccessibleProjectIds(ProjectId,ProjectAccessTypeId,IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)            
  SELECT PS.ProjectId, PS.ProjectAccessTypeId, 0, '', IIF(PS.OwnerId = @PUserId, 1, 0)            
  FROM ProjectSummary PS WITH(NOLOCK)            
  WHERE (PS.ProjectAccessTypeId IN(1, 2) OR PS.OwnerId = @PUserId)AND ps.CustomerId = @PCustomerId;            
                 
  -- Update all public Projects as accessible            
  UPDATE AP            
  SET AP.IsProjectAccessible = 1            
  FROM #AccessibleProjectIds AP            
  WHERE AP.ProjectAccessTypeId = 1;            
              
  -- Update all private Projects if they are accessible            
  UPDATE AP            
  SET AP.IsProjectAccessible = 1            
  FROM #AccessibleProjectIds AP            
  INNER JOIN UserProjectAccessMapping UPAM  WITH(NOLOCK) ON AP.ProjectId = UPAM.ProjectId            
  WHERE UPAM.IsActive = 1            
     AND UPAM.UserId = @PUserId            
     AND AP.ProjectAccessTypeId = 2            
     AND UPAM.CustomerId = @PCustomerId;            
                 
  --Get all accessible projects            
  INSERT INTO #AccessibleProjectIds (ProjectId,ProjectAccessTypeId,IsProjectAccessible,ProjectAccessTypeName,IsProjectOwner)            
  SELECT PS.ProjectId, PS.ProjectAccessTypeId, 1, '', IIF(PS.OwnerId = @PUserId, 1, 0)            
  FROM ProjectSummary PS WITH(NOLOCK)            
     INNER JOIN UserProjectAccessMapping UPAM WITH(NOLOCK) ON UPAM.ProjectId = PS.ProjectId            
     LEFT OUTER JOIN #AccessibleProjectIds AP            
     ON AP.ProjectId = ps.ProjectId            
  WHERE PS.ProjectAccessTypeId = 3            
AND UPAM.UserId = @PUserId            
     AND AP.ProjectId IS NULL            
     AND PS.CustomerId = @PCustomerId            
     AND(UPAM.IsActive = 1 OR PS.OwnerId = @PUserId);            
            
  UPDATE AP            
  SET AP.IsProjectAccessible = AP.IsProjectOwner            
  FROM #AccessibleProjectIds AP            
  WHERE AP.IsProjectOwner = 1;            
            
  INSERT INTO #IncomingProjectList            
  SELECT            
     P.ProjectId,            
     P.[Name] AS ProjectName,            
     PS.ProjectAccessTypeId,            
     AP.IsProjectAccessible,            
     AP.ProjectAccessTypeName            
  FROM Project P WITH (NOLOCK)            
     INNER JOIN [dbo].[ProjectSummary] PS WITH (NOLOCK) ON PS.ProjectId = P.ProjectId            
     INNER JOIN #AccessibleProjectIds AP ON AP.ProjectId = P.ProjectId            
     LEFT JOIN UserFolder UF WITH (NOLOCK) ON UF.ProjectId = P.ProjectId AND UF.CustomerId = P.CustomerId            
  WHERE ISNULL(p.IsDeleted, 0) = 0      
     AND ISNULL(p.IsPermanentDeleted, 0) = 0           
     AND ISNULL(P.IsArchived, 0) = 0            
     AND P.IsOfficeMaster = @PIsOfficeMasterTab            
     AND P.CustomerId = @PCustomerId            
     AND ISNULL(P.IsIncomingProject, 0) = 1    
  AND P.TransferredDate > @DateBefore30Days;         
 END            
            
 UPDATE IPL            
 SET IPL.ProjectAccessTypeName = PT.[Name]            
 FROM #IncomingProjectList IPL WITH (NOLOCK)            
 INNER JOIN LuProjectAccessType PT WITH (NOLOCK) ON IPL.ProjectAccessTypeId = PT.ProjectAccessTypeId;            
          
 SELECT   DISTINCT          
 IPL.ProjectId,             
 IPL.ProjectName,             
 IPL.ProjectAccessTypeId,             
 IPL.IsProjectAccessible,             
 IPL.ProjectAccessTypeName AS ProjectType            
 FROM #IncomingProjectList IPL           
    
END             
            
-- EXEC sp_helptext usp_GetIncomingTransferProjects_new 82, 1, 24, 0 
GO
PRINT N'Creating [dbo].[usp_GetTransferProjectDefaultPrivacySetting]...';


GO
CREATE PROCEDURE usp_GetTransferProjectDefaultPrivacySetting     
(    
   @CustomerId int,    
   @UserId int,    
   @IsOfficeMaster bit,    
   @ProjectAccessTypeId int OUTPUT,    
   @ProjectOwnerId int OUTPUT    
)     
AS     
BEGIN     
    
 DECLARE @PCustomerId int = @CustomerId;    
 DECLARE @PIsOfficeMaster bit = @IsOfficeMaster;    
 DECLARE @ProjectOrigineType int = 3; -- Transferred Project    
 DECLARE @ProjectOwnerTypeId int = null;    
    
 SELECT    
    PPS.CustomerId,    
    PPS.ProjectAccessTypeId,    
    PPS.ProjectOwnerTypeId,    
    PPS.ProjectOriginTypeId,    
    PPS.IsOfficeMaster     
 INTO #ProjDefaultPrivacySetting    
 FROM ProjectDefaultPrivacySetting PPS WITH(NOLOCK)    
 WHERE PPS.CustomerId = 0    
    AND PPS.ProjectOriginTypeId = @ProjectOrigineType    
    AND PPS.IsOfficeMaster = @PIsOfficeMaster;    
    
 UPDATE PPS    
 SET PPS.ProjectAccessTypeId = PDPS.ProjectAccessTypeId,    
     PPS.ProjectOwnerTypeId = PDPS.ProjectOwnerTypeId    
 FROM #ProjDefaultPrivacySetting PPS WITH(NOLOCK)    
 JOIN ProjectDefaultPrivacySetting PDPS WITH(NOLOCK) ON PPS.IsOfficeMaster = PDPS.IsOfficeMaster    
             AND PPS.ProjectOriginTypeId = PDPS.ProjectOriginTypeId    
             AND PDPS.CustomerId = @PCustomerId;    
    
 SELECT TOP 1 @ProjectAccessTypeId = ProjectAccessTypeId, @ProjectOwnerTypeId = ProjectOwnerTypeId    
 FROM #ProjDefaultPrivacySetting WITH(NOLOCK);    
     
 IF(@ProjectOwnerTypeId = 2)    
  SET @ProjectOwnerId = @UserId;    
END
GO
PRINT N'Creating [dbo].[usp_GetTransferProjectViewTypeId]...';


GO
CREATE PROCEDURE usp_GetTransferProjectViewTypeId          
(         
   @MasterDataTypeId INT =1 ,      
   @SenderProjectViewTypeId INT =1 ,     
   @SenderCustomerId INT ,   
   @RecipientCustomerId INT ,      
   @SpecViewModeId int OUTPUT          
)           
AS           
BEGIN      
      
DECLARE @SenderCatalogueType nvarchar(50)      
,@SenderFeatureValue nvarchar(max)      
,@RecipientCatalogueType nvarchar(50)      
,@RecipientFeatureValue nvarchar(max)      
,@RecipentProjectViewTypeId INT =1      
,@OLSF NVARCHAR(50)='OL/SF'      
,@FS NVARCHAR(50)='FS'      
,@EntitlementFeatureId INT=2--USA      
,@DefaultProjectTypeView INT =3--SF(Sort Form View)      
,@SLCProductId INT=4      
  
--Get entitlement for Master      
SET @EntitlementFeatureId =      
CASE      
 WHEN @MasterDataTypeId = 1 THEN 2  --USA    
 WHEN @MasterDataTypeId = 2 THEN 3  --CANADA    
 WHEN @MasterDataTypeId = 3 THEN 4  --NMS E    
 WHEN @MasterDataTypeId = 4 THEN 5  --NMS F     
 ELSE 2      
END;      
         
SELECT      
 @SenderFeatureValue = CONCAT(N'[', FeatureValue, ']')      
FROM [SLCADMIN].[Authentication].[dbo].CustomerEntitlement CE  WITH(NOLOCK)      
INNER JOIN [SLCADMIN].[Authentication].[dbo].CustomerProductLicense CPL  WITH(NOLOCK)      
 ON CE.CustomerId = CPL.CustomerId      
  AND CE.SubscriptionId = CPL.SubscriptionId      
WHERE CE.CustomerId = @SenderCustomerId      
AND CE.EntitlementFeatureId = @EntitlementFeatureId     
AND CPL.ProductId = @SLCProductId      
AND CPL.IsActive = 1      
      
SELECT      
 @SenderCatalogueType = CatalogueType      
FROM OPENJSON(@SenderFeatureValue)      
WITH (      
CatalogueType NVARCHAR(50) 'strict $.CatalogueType'      
);      
      
SELECT      
 @RecipientFeatureValue = CONCAT(N'[', FeatureValue, ']')      
FROM [SLCADMIN].[Authentication].[dbo].CustomerEntitlement CE WITH(NOLOCK)      
INNER JOIN [SLCADMIN].[Authentication].[dbo].CustomerProductLicense CPL WITH(NOLOCK)      
 ON CE.CustomerId = CPL.CustomerId      
  AND CE.SubscriptionId = CPL.SubscriptionId      
WHERE CE.CustomerId = @RecipientCustomerId       
AND CE.EntitlementFeatureId = @EntitlementFeatureId      
AND CPL.ProductId = @SLCProductId      
AND CPL.IsActive = 1      
      
SELECT      
 @RecipientCatalogueType = CatalogueType      
FROM OPENJSON(@RecipientFeatureValue)      
WITH (      
CatalogueType NVARCHAR(50) 'strict $.CatalogueType'      
);      
      
IF (@SenderCatalogueType = @FS      
 AND @RecipientCatalogueType = @OLSF      
 AND @SenderProjectViewTypeId = 1)      
SET @RecipentProjectViewTypeId = @DefaultProjectTypeView      
--Recipient dose not have Subcription      
ELSE IF (@SenderCatalogueType=@FS AND @RecipientCatalogueType IS NULL)      
SET @RecipentProjectViewTypeId = @DefaultProjectTypeView      
ELSE      
SET @RecipentProjectViewTypeId = @SenderProjectViewTypeId      
      
SET @SpecViewModeId = @RecipentProjectViewTypeId      
      
END
GO
PRINT N'Creating [dbo].[usp_RejectTransferProject]...';


GO
CREATE PROCEDURE usp_RejectTransferProject  
(  
 @ProjectId INT,  
 @UserId INT,  
 @CustomerId INT  
)  
AS  
BEGIN  
   
 UPDATE P  
 SET P.IsDeleted = 1, P.IsPermanentDeleted = 1,  
 P.ModifiedBy=@UserId,  
 P.ModifiedDate=GETUTCDATE()  
 FROM Project P WITH(NOLOCK)  
 WHERE P.ProjectId =  @ProjectId;  
  
 DECLARE @TransferredRequestId INT =0  
    SELECT  @TransferredRequestId=TransferRequestId  FROM CopyProjectRequest WITH(NOLOCK) WHERE  TargetProjectId=@ProjectId  
 INSERT INTO IncomingProjectHistory VALUES (@ProjectId,'REJECTES',@UserId,@CustomerId,GETUTCDATE(),@TransferredRequestId)  
END
GO
PRINT N'Creating [dbo].[usp_SaveBIM360Credentials]...';


GO
Create PROCEDURE [dbo].[usp_SaveBIM360Credentials] 
(  
@customerId INT,  
@clientId Nvarchar(255),
@clientSecret Nvarchar(255),
@IsActive Bit ,
@createdBy INT,
@ModifiedBy Int
)  
AS  
BEGIN
  
  Declare @count INT;
SELECT
	@count = (SELECT
			COUNT(1)
		FROM BIM360AccessKey WITH (NOLOCK)
		WHERE customerId = @customerId)
IF (@count = 0)
BEGIN
INSERT INTO BIM360AccessKey (customerId, clientId, clientSecret, IsActive, createdDate, createdBy, ModifiedDate, ModifiedBy)
	VALUES (@customerId, @clientId, @clientSecret, @IsActive, GETUTCDATE(), @createdBy, NULL, @ModifiedBy)

END
ELSE
BEGIN
UPDATE B
SET B.ClientId = @clientId
   ,B.ClientSecret = @clientSecret
    ,B.ISActive = @IsActive
FROM BIM360AccessKey B WITH (NOLOCK)
where customerId = @customerId
END

SELECT
	*
FROM BIM360AccessKey WITH (NOLOCK)
WHERE customerId = @customerId;

END
GO
PRINT N'Creating [dbo].[usp_SaveBim360ToggleInfo]...';


GO
CREATE PROCEDURE [dbo].[usp_SaveBim360ToggleInfo] 
(  
  @customerId INT ,
  @IsActive BIT
)  
AS  
BEGIN  


Update B
SET B.IsActive = @IsActive
from BIM360AccessKey B WITH (NOLOCK)
where B.customerId = @customerId


SELECT IsActive As IsToggleEnable
 from BIM360AccessKey WITH (NOLOCK)
 where customerId = @customerId
END
GO
PRINT N'Creating [dbo].[usp_TrackAcceptRejectHistory]...';


GO
CREATE PROCEDURE [dbo].[usp_TrackAcceptRejectHistory]        
  @SectionId  int=0,  
        @ProjectId  int=0,  
        @CustomerId int=0,  
        @TrackActionId  int,   
  @UserId int  
AS      
 BEGIN  
 INSERT INTO TrackAcceptRejectHistory (SectionId,ProjectId,CustomerId,TrackActionId,UserId,CreateDate)  
 VALUES(@SectionId,@ProjectId,@CustomerId,@TrackActionId,@UserId,getutcdate());
END
GO
PRINT N'Altering [dbo].[usp_CopyProject]...';


GO
ALTER PROCEDURE [dbo].[usp_CopyProject]      
(      
 @PSourceProjectId  INT      
,@PTargetProjectId INT      
,@PCustomerId INT      
,@PUserId INT      
,@PRequestId INT        
)      
AS      
BEGIN      
--Handle Parameter Sniffing      
DECLARE @SourceProjectId INT = @PSourceProjectId;      
DECLARE @TargetProjectId INT = @PTargetProjectId;      
DECLARE @CustomerId INT = @PCustomerId;      
DECLARE @UserId INT = @PUserId;      
DECLARE @RequestId INT = @PRequestId;      
        
--Progress Variables      
DECLARE @CopyStart_Description NVARCHAR(50) = 'Copy Started';      
DECLARE @CopyGlobalTems_Description NVARCHAR(50) = 'Global Terms Copied';      
DECLARE @CopySections_Description NVARCHAR(50) = 'Sections Copied';      
DECLARE @CopySegmentStatus_Description NVARCHAR(50) = 'Segment Status Copied';      
DECLARE @CopySegments_Description NVARCHAR(50) = 'Segments Copied';      
DECLARE @CopySegmentChoices_Description NVARCHAR(50) = 'Choices Copied';      
DECLARE @CopySegmentLinks_Description NVARCHAR(50) = 'Segment Links Copied';      
DECLARE @CopyNotes_Description NVARCHAR(50) = 'Notes Copied';      
DECLARE @CopyImages_Description NVARCHAR(50) = 'Images Copied';      
DECLARE @CopyRefStds_Description NVARCHAR(50) = 'Reference Standards Copied';      
DECLARE @CopyTags_Description NVARCHAR(50) = 'Segment Tags Copied';      
DECLARE @CopyHeaderFooter_Description NVARCHAR(50) = 'Header and Footer Copied';      
DECLARE @CopyProjectHyperLink_Description NVARCHAR(50) = 'Project Hyper Link Copied';      
DECLARE @CopyComplete_Description NVARCHAR(50) = 'Copy Completed';      
DECLARE @CopyFailed_Description NVARCHAR(50) = 'Copy Failed';      
DECLARE @CustomerName NVARCHAR(20) = '';      
DECLARE @UserName NVARCHAR(20) = '';      
      
DECLARE @CopyStart_Percentage FLOAT = 5;      
DECLARE @CopyGlobalTems_Percentage FLOAT = 10;      
DECLARE @CopySections_Percentage FLOAT = 15;      
DECLARE @CopySegmentStatus_Percentage FLOAT = 35;      
DECLARE @CopySegments_Percentage FLOAT = 45;      
DECLARE @CopySegmentChoices_Percentage FLOAT = 55;      
DECLARE @CopySegmentLinks_Percentage FLOAT = 70;      
DECLARE @CopyNotes_Percentage FLOAT = 75;      
DECLARE @CopyImages_Percentage FLOAT = 80;      
DECLARE @CopyRefStds_Percentage FLOAT = 85;      
DECLARE @CopyTags_Percentage FLOAT = 90;      
DECLARE @CopyHeaderFooter_Percentage FLOAT = 95;      
DECLARE @CopyProjectHyperLink_Percentage FLOAT = 97;      
DECLARE @CopyComplete_Percentage FLOAT = 100;      
DECLARE @CopyFailed_Percentage FLOAT = 100;      
DECLARE @CopyStart_Step INT = 2;      
DECLARE @CopyGlobalTems_Step INT = 3;      
DECLARE @CopySections_Step INT = 4;      
DECLARE @CopySegmentStatus_Step INT = 5;      
DECLARE @CopySegments_Step INT = 6;      
DECLARE @CopySegmentChoices_Step INT = 7;      
DECLARE @CopySegmentLinks_Step INT = 8;      
DECLARE @CopyNotes_Step INT = 9;      
DECLARE @CopyImages_Step INT = 10;      
DECLARE @CopyRefStds_Step INT = 11;      
DECLARE @CopyTags_Step INT = 12;      
DECLARE @CopyHeaderFooter_Step INT = 13;      
DECLARE @CopyProjectHyperLink_Step INT = 14;      
DECLARE @CopyComplete_Step FLOAT = 15;      
DECLARE @CopyFailed_Step FLOAT = 16;      
      
--Variables      
DECLARE @MasterDataTypeId INT = ( SELECT TOP 1      
  MasterDataTypeId      
 FROM Project WITH (NOLOCK)      
 WHERE ProjectId = @SourceProjectId      
 AND CustomerId = @CustomerId);      
      
DECLARE @StateProvinceName NVARCHAR(100) = (SELECT TOP 1      
  IIF(LUS.StateProvinceName IS NULL, PADR.StateProvinceName, LUS.StateProvinceName) AS StateProvinceName      
 FROM ProjectAddress PADR WITH (NOLOCK)      
 LEFT OUTER JOIN LuStateProvince LUS WITH (NOLOCK)      
  ON LUS.StateProvinceID = PADR.StateProvinceId      
 WHERE PADR.ProjectId = @TargetProjectId      
 AND PADR.CustomerId = @CustomerId);      
      
DECLARE @City NVARCHAR(100) = (SELECT TOP 1      
  IIF(LUC.City IS NULL, PADR.CityName, LUC.City) AS City      
 FROM ProjectAddress PADR WITH (NOLOCK)      
 LEFT OUTER JOIN LuCity LUC WITH (NOLOCK)      
  ON LUC.CityId = PADR.CityId      
 WHERE PADR.ProjectId = @TargetProjectId      
 AND PADR.CustomerId = @CustomerId);      
      
--Temp Tables          
DROP TABLE IF EXISTS #tmp_SrcSection;      
DROP TABLE IF EXISTS #tmp_TgtSection;      
DROP TABLE IF EXISTS #SrcSegmentStatusCPTMP;      
DROP TABLE IF EXISTS #tmp_TgtSegmentStatus;      
DROP TABLE IF EXISTS #tmp_SrcSegment;      
DROP TABLE IF EXISTS #tmp_TgtSegment;      
DROP TABLE IF EXISTS #tmp_SrcSegmentChoice;      
DROP TABLE IF EXISTS #tmp_SrcSelectedChoiceOption;      
DROP TABLE IF EXISTS #tmp_TgtSegmentChoice;      
DROP TABLE IF EXISTS #tmp_SrcSegmentLink;      
DROP TABLE IF EXISTS #tmp_TgtProjectNote;      
DROP TABLE IF EXISTS #tmp_SrcProjectSegmentRequirementTag;      
      
           
DECLARE @id_control INT      
DECLARE @results INT       
      
BEGIN TRY      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyStart_Description      
     ,@CopyStart_Description      
     ,1 --IsCompleted          
     ,@CopyStart_Step --Step         
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopyStart_Percentage --Percent          
   ,0 --IsInsertRecord       
   ,@CustomerName      
   ,@UserName;      
      
--UPDATE TemplateId,ModifiedDate,ModifiedByFullName in target project                      
UPDATE P            
SET P.TemplateId = P_Src.TemplateId,      
P.IsLocked = P_Src.IsLocked,      
P.LockedBy = CASE WHEN ISNULL(P_Src.IsLocked,0) = 1 THEN P_Src.LockedBy      
   ELSE NULL END,      
P.LockedDate = CASE WHEN ISNULL(P_Src.IsLocked,0) = 1 THEN P_Src.LockedDate      
   ELSE NULL END      
--,P.ModifiedBy = P_Src.ModifiedBy                      
--,P.ModifiedDate = P_Src.ModifiedDate                      
--,P.ModifiedByFullName = P_Src.ModifiedByFullName                       
FROM Project P WITH (NOLOCK)            
INNER JOIN Project P_Src WITH (NOLOCK)            
 ON P_Src.ProjectId = @SourceProjectId            
WHERE P.ProjectId = @TargetProjectId;            
            
--UPDATE LastAccessed and LastAccessByFullName in target project           
-- Resolved Bug 38772 - Removing this update statement.      
--UPDATE UF            
--SET --UF.LastAccessed = UF_Src.LastAccessed                      
--UF.LastAccessByFullName = UF_Src.LastAccessByFullName            
--FROM UserFolder UF WITH (NOLOCK)            
--INNER JOIN UserFolder UF_Src WITH (NOLOCK)            
-- ON UF_Src.ProjectId = @SourceProjectId            
--WHERE UF.ProjectId = @TargetProjectId;            
      
--INSERT ProjectGlobalTerm          
INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode,      
CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted, GlobalTermFieldTypeId)      
 SELECT      
  PGT_Src.mGlobalTermId AS mGlobalTermId      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,PGT_Src.Name AS [Name]      
    ,(CASE      
   WHEN PGT_Src.Name = 'Project Name' THEN CAST(P.Name AS NVARCHAR(300))      
   WHEN PGT_Src.Name = 'Project ID' THEN CAST(P.ProjectId AS NVARCHAR(300))      
   WHEN (PGT_Src.Name = 'Project Location State' AND      
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@StateProvinceName AS NVARCHAR(300))      
   WHEN (PGT_Src.Name = 'Project Location City' AND      
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@City AS NVARCHAR(300))      
   WHEN (PGT_Src.Name = 'Project Location Province' AND      
    PGT_Src.GlobalTermFieldTypeId = 3) THEN CAST(@StateProvinceName AS NVARCHAR(500))      
   ELSE PGT_Src.Value      
  END) AS [Value]      
    ,PGT_Src.GlobalTermSource AS GlobalTermSource      
    ,PGT_Src.GlobalTermCode AS GlobalTermCode      
    ,PGT_Src.CreatedDate AS CreatedDate      
    ,PGT_Src.CreatedBy AS CreatedBy      
    ,PGT_Src.ModifiedDate AS ModifiedDate      
    ,PGT_Src.ModifiedBy AS ModifiedBy      
    ,PGT_Src.UserGlobalTermId AS UserGlobalTermId      
    ,ISNULL(PGT_Src.IsDeleted, 0) AS IsDeleted      
    ,PGT_Src.GlobalTermFieldTypeId      
 FROM ProjectGlobalTerm PGT_Src WITH (NOLOCK)      
 INNER JOIN Project P WITH (NOLOCK)      
  ON P.ProjectId = @TargetProjectId      
 WHERE PGT_Src.ProjectId = @SourceProjectId;      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyGlobalTems_Description      
     ,@CopyGlobalTems_Description      
     ,1 --IsCompleted          
     ,@CopyGlobalTems_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopyGlobalTems_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
 ,@UserName;      
      
--Copy source sections in temp table      
SELECT      
 PS.*,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo INTO #tmp_SrcSection      
FROM ProjectSection PS WITH (NOLOCK)      
WHERE PS.ProjectId = @SourceProjectId      
AND PS.CustomerId = @CustomerId      
AND ISNULL(PS.IsDeleted, 0) = 0;      
       
SET @results = 1      
SET @id_control = 0      
       
DECLARE @ProjectSection INT      
DECLARE @ProjectSegmentStatus  INT      
DECLARE @ProjectSegment INT      
DECLARE @ProjectSegmentChoice INT      
DECLARE @ProjectChoiceOption INT      
DECLARE @SelectedChoiceOption INT      
DECLARE @ProjectSegmentLink INT      
DECLARE @ProjectHyperLink INT      
DECLARE @ProjectNote INT      
      
IF(EXISTS(SELECT TOP 1 1 FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK) WHERE Servername=@@servername))      
BEGIN      
 SELECT TOP 1 @ProjectSection=ProjectSection,      
  @ProjectSegmentStatus=ProjectSegmentStatus,      
  @ProjectSegment =ProjectSegment ,      
  @ProjectSegmentChoice =ProjectSegmentChoice ,      
  @ProjectChoiceOption =ProjectChoiceOption ,      
  @SelectedChoiceOption =SelectedChoiceOption ,      
  @ProjectSegmentLink =ProjectSegmentLink ,      
  @ProjectHyperLink =ProjectHyperLink ,      
  @ProjectNote =ProjectNote       
  FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK)       
  WHERE Servername=@@servername      
END      
ELSE      
BEGIN      
 SELECT TOP 1 @ProjectSection=ProjectSection,      
  @ProjectSegmentStatus=ProjectSegmentStatus,      
  @ProjectSegment =ProjectSegment ,      
  @ProjectSegmentChoice =ProjectSegmentChoice ,      
  @ProjectChoiceOption =ProjectChoiceOption ,      
  @SelectedChoiceOption =SelectedChoiceOption ,      
  @ProjectSegmentLink =ProjectSegmentLink ,      
  @ProjectHyperLink =ProjectHyperLink ,      
  @ProjectNote =ProjectNote       
  FROM SLCMaster..LuTableInsertBatchSize WITH(NOLOCK)       
  WHERE Servername IS NULL      
END      
 WHILE(@results>0)      
 BEGIN      
 --INSERT ProjectSection      
 INSERT INTO ProjectSection (ParentSectionId, mSectionId, ProjectId, CustomerId, UserId, DivisionId, DivisionCode,      
 Description, LevelId, IsLastLevel, SourceTag, Author, TemplateId, SectionCode, IsDeleted, CreateDate, CreatedBy,      
 ModifiedBy, ModifiedDate, FormatTypeId, SpecViewModeId, A_SectionId, IsTrackChanges, IsTrackChangeLock, TrackChangeLockedBy)      
  SELECT      
   PS_Src.ParentSectionId      
  ,PS_Src.mSectionId AS mSectionId      
  ,@TargetProjectId AS ProjectId      
  ,@CustomerId AS CustomerId      
  ,@UserId AS UserId      
  ,PS_Src.DivisionId AS DivisionId      
  ,PS_Src.DivisionCode AS DivisionCode      
  ,PS_Src.Description AS Description      
  ,PS_Src.LevelId AS LevelId      
  ,PS_Src.IsLastLevel AS IsLastLevel      
  ,PS_Src.SourceTag AS SourceTag      
  ,PS_Src.Author AS Author      
  ,PS_Src.TemplateId AS TemplateId      
  ,PS_Src.SectionCode AS SectionCode      
  ,PS_Src.IsDeleted AS IsDeleted      
  ,PS_Src.CreateDate AS CreateDate      
  ,PS_Src.CreatedBy AS CreatedBy      
  ,PS_Src.ModifiedBy AS ModifiedBy      
  ,PS_Src.ModifiedDate AS ModifiedDate      
  ,PS_Src.FormatTypeId AS FormatTypeId      
  ,PS_Src.SpecViewModeId AS SpecViewModeId      
  ,PS_Src.SectionId AS A_SectionId        
  ,IsTrackChanges        
  ,IsTrackChangeLock        
  ,COALESCE(TrackChangeLockedBy, 0) AS TrackChangeLockedBy        
  FROM #tmp_SrcSection PS_Src WITH (NOLOCK)      
  WHERE PS_Src.ProjectId = @SourceProjectId      
  AND SrNo > @id_control      
      AND SrNo <= @id_control + @ProjectSection      
 SET @results = @@ROWCOUNT      
   -- next batch      
   SET @id_control = @id_control + @ProjectSection      
       
 END      
--Copy target sections in temp table      
SELECT      
 PS.SectionId      
   ,PS.ParentSectionId      
   ,PS.ProjectId      
   ,PS.CustomerId      
  ,PS.IsLastLevel      
   ,PS.SectionCode      
   ,PS.IsDeleted      
   ,PS.A_SectionId       
   --,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo      
   INTO #tmp_TgtSection      
FROM ProjectSection PS WITH (NOLOCK)      
WHERE PS.ProjectId = @TargetProjectId      
AND ISNULL(PS.IsDeleted, 0) = 0;      
      
SELECT      
 SectionId      
   ,A_SectionId INTO #NewOldSectionIdMapping      
FROM #tmp_TgtSection      
      
--UPDATE ParentSectionId in TGT Section table      
UPDATE TGT_TMP      
SET TGT_TMP.ParentSectionId = NOSM.SectionId      
FROM #tmp_TgtSection TGT_TMP WITH (NOLOCK)      
INNER JOIN #NewOldSectionIdMapping NOSM WITH (NOLOCK)      
 ON TGT_TMP.ParentSectionId = NOSM.A_SectionId      
WHERE TGT_TMP.ProjectId = @TargetProjectId;      
      
      
--UPDATE ParentSectionId in original table      
UPDATE PS      
SET PS.ParentSectionId = PS_TMP.ParentSectionId      
FROM ProjectSection PS WITH (NOLOCK)      
INNER JOIN #tmp_TgtSection PS_TMP      
 ON PS.SectionId = PS_TMP.SectionId      
WHERE PS.ProjectId = @TargetProjectId      
AND PS.CustomerId = @CustomerId;      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopySections_Description      
     ,@CopySections_Description      
     ,1 --IsCompleted          
     ,@CopySections_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopySections_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--Copy source segment status in temp table          
SELECT      
 PSST.*
 ,ROW_NUMBER() OVER (ORDER BY PSST.SectionId) AS SrNo    
 INTO #SrcSegmentStatusCPTMP      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)
INNER JOIN #tmp_TgtSection s  
ON PSST.SectionId=s.A_SectionId       
WHERE PSST.ProjectId = @SourceProjectId
AND PSST.CustomerId = @CustomerId      
AND ISNULL(PSST.IsDeleted, 0) = 0      
      
SET @results = 1       
SET @id_control = 0       
      
WHILE(@results>0)      
BEGIN      
 --INSERT ProjectSegmentStatus          
 INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin,      
 IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,      
 SegmentStatusCode, IsShowAutoNumber, IsRefStdParagraph, FormattingJson, CreateDate, CreatedBy, ModifiedBy,      
 ModifiedDate, IsPageBreak, IsDeleted, A_SegmentStatusId)      
  SELECT      
   PS.SectionId AS SectionId      
    ,PSST_Src.ParentSegmentStatusId AS ParentSegmentStatusId      
    ,PSST_Src.mSegmentStatusId AS mSegmentStatusId      
    ,PSST_Src.mSegmentId AS mSegmentId      
    ,PSST_Src.SegmentId AS SegmentId      
    ,PSST_Src.SegmentSource AS SegmentSource      
    ,PSST_Src.SegmentOrigin AS SegmentOrigin      
    ,PSST_Src.IndentLevel AS IndentLevel      
    ,PSST_Src.SequenceNumber AS SequenceNumber      
    ,PSST_Src.SpecTypeTagId AS SpecTypeTagId      
    ,PSST_Src.SegmentStatusTypeId AS SegmentStatusTypeId      
    ,PSST_Src.IsParentSegmentStatusActive AS IsParentSegmentStatusActive      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,PSST_Src.SegmentStatusCode AS SegmentStatusCode      
    ,PSST_Src.IsShowAutoNumber AS IsShowAutoNIsPageBreakumber      
    ,PSST_Src.IsRefStdParagraph AS IsRefStdParagraph      
    ,PSST_Src.FormattingJson AS FormattingJson      
    ,PSST_Src.CreateDate AS CreateDate      
    ,PSST_Src.CreatedBy AS CreatedBy      
    ,PSST_Src.ModifiedBy AS ModifiedBy      
    ,PSST_Src.ModifiedDate AS ModifiedDate      
    ,PSST_Src.IsPageBreak AS IsPageBreak      
    ,PSST_Src.IsDeleted AS IsDeleted      
    ,PSST_Src.SegmentStatusId AS A_SegmentStatusId      
  FROM #SrcSegmentStatusCPTMP PSST_Src WITH (NOLOCK)      
  INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PSST_Src.SectionId = PS.A_SectionId      
  AND PSST_Src.SrNo > @id_control      
     AND PSST_Src.SrNo <= @id_control + @ProjectSegmentStatus      
       
 SET @results = @@ROWCOUNT      
   -- next batch      
   SET @id_control = @id_control + @ProjectSegmentStatus      
END      
--Copy target segment status in temp table          
SELECT      
 PSST.SegmentStatusId      
   ,PSST.SectionId      
   ,PSST.ParentSegmentStatusId      
   ,PSST.SegmentId      
   ,PSST.ProjectId      
   ,PSST.CustomerId      
   ,PSST.SegmentStatusCode      
   ,PSST.IsDeleted      
   ,PSST.A_SegmentStatusId INTO #tmp_TgtSegmentStatus      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)      
WHERE PSST.ProjectId = @TargetProjectId      
AND PSST.CustomerId = @CustomerId      
AND ISNULL(PSST.IsDeleted, 0) = 0      
      
SELECT      
 SegmentStatusId      
   ,A_SegmentStatusId INTO #NewOldSegmentStatusIdMapping      
FROM #tmp_TgtSegmentStatus      
      
--UPDATE ParentSegmentStatusId in temp table          
UPDATE CPSST      
SET CPSST.ParentSegmentStatusId = PPSST.SegmentStatusId      
FROM #tmp_TgtSegmentStatus CPSST WITH (NOLOCK)      
INNER JOIN #NewOldSegmentStatusIdMapping PPSST WITH (NOLOCK)      
 ON CPSST.ParentSegmentStatusId = PPSST.A_SegmentStatusId      
WHERE CPSST.ProjectId = @TargetProjectId      
AND CPSST.CustomerId = @CustomerId;      
      
--UPDATE ParentSegmentStatusId in original table      
UPDATE PSS      
SET PSS.ParentSegmentStatusId = PSS_TMP.ParentSegmentStatusId      
FROM ProjectSegmentStatus PSS WITH (NOLOCK)      
INNER JOIN #tmp_TgtSegmentStatus PSS_TMP      
 ON PSS.SegmentStatusId = PSS_TMP.SegmentStatusId      
 AND PSS.ProjectId = @TargetProjectId      
WHERE PSS.ProjectId = @TargetProjectId      
AND PSS.CustomerId = @CustomerId;      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopySegmentStatus_Description      
     ,@CopySegmentStatus_Description      
     ,1 --IsCompleted          
     ,@CopySegmentStatus_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopySegmentStatus_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--Copy source segments in temp table 
SELECT PSG.* ,ROW_NUMBER() OVER (ORDER BY PSG.SectionId) AS SrNo 
INTO #tmp_SrcSegment
FROM ProjectSegment PSG WITH (NOLOCK)
INNER JOIN #tmp_TgtSection s
ON PSG.SectionId=s.A_SectionId
WHERE PSG.ProjectId = @SourceProjectId
AND PSG.CustomerId = @CustomerId
AND ISNULL(PSG.IsDeleted, 0) = 0      

SET @results = 1       
SET @id_control = 0      
      
WHILE(@results>0)      
BEGIN      
 INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,      
 SegmentSource, SegmentCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentId, BaseSegmentDescription)      
  SELECT      
   PSST.SegmentStatusId AS SegmentStatusId      
  ,PS.SectionId AS SectionId      
  ,@TargetProjectId AS ProjectId      
  ,@CustomerId AS CustomerId      
  ,PSG_Src.SegmentDescription AS SegmentDescription      
  ,PSG_Src.SegmentSource AS SegmentSource      
  ,PSG_Src.SegmentCode AS SegmentCode      
  ,PSG_Src.CreatedBy AS CreatedBy      
  ,PSG_Src.CreateDate AS CreateDate      
  ,PSG_Src.ModifiedBy AS ModifiedBy      
  ,PSG_Src.ModifiedDate AS ModifiedDate      
  ,PSG_Src.IsDeleted AS IsDeleted      
  ,PSG_Src.SegmentId AS A_SegmentId      
  ,PSG_Src.BaseSegmentDescription AS BaseSegmentDescription      
  FROM #tmp_SrcSegment PSG_Src WITH (NOLOCK)      
  INNER JOIN #tmp_tgtSection PS WITH (NOLOCK)      
  ON PSG_Src.SectionId = PS.A_SectionId      
  INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)      
  ON PSG_Src.SegmentStatusId = PSST.A_SegmentStatusId      
  AND PSG_Src.SrNo > @id_control      
     AND PSG_Src.SrNo <= @id_control + @ProjectSegment      
        
  SET @results = @@ROWCOUNT      
  -- next batch      
  SET @id_control = @id_control + @ProjectSegment      
END      
      
--Copy target segments in temp table          
SELECT      
 PSG.SegmentId      
   ,PSG.SegmentStatusId      
   ,PSG.SectionId      
   ,PSG.ProjectId      
   ,PSG.CustomerId      
   ,PSG.SegmentCode      
   ,PSG.IsDeleted      
   ,PSG.A_SegmentId      
   ,PSG.BaseSegmentDescription INTO #tmp_TgtSegment      
FROM ProjectSegment PSG WITH (NOLOCK)      
WHERE PSG.ProjectId = @TargetProjectId      
AND PSG.CustomerId = @CustomerId      
AND ISNULL(PSG.IsDeleted, 0) = 0      
      
--UPDATE SegmentId in temp table          
UPDATE PSST      
SET PSST.SegmentId = PSG.SegmentId      
FROM #tmp_TgtSegmentStatus PSST WITH (NOLOCK)      
INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)      
ON PSST.SectionId = PSG.SectionId      
AND PSST.SegmentId = PSG.A_SegmentId      
AND PSST.SegmentId IS NOT NULL      
      
----UPDATE ParentSegmentStatusId and SegmentId in original table          
UPDATE PSST      
SET --PSST.ParentSegmentStatusId = PSST_TMP.ParentSegmentStatusId,          
PSST.SegmentId = PSST_TMP.SegmentId      
FROM ProjectSegmentStatus PSST WITH (NOLOCK)      
INNER JOIN #tmp_TgtSegmentStatus PSST_TMP WITH (NOLOCK)      
 ON PSST.SegmentStatusId = PSST_TMP.SegmentStatusId      
 AND PSST.ProjectId = PSST_TMP.ProjectId      
 AND PSST.SegmentId IS NOT NULL      
WHERE PSST.ProjectId = @TargetProjectId      
AND PSST.CustomerId = @CustomerId;      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopySegments_Description      
     ,@CopySegments_Description      
     ,1 --IsCompleted          
     ,@CopySegments_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopySegments_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--Copy source choices in temp table          
SELECT      
 PCH.*       
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo      
 INTO #tmp_SrcSegmentChoice      
FROM ProjectSegmentChoice PCH WITH (NOLOCK)      
WHERE PCH.ProjectId = @SourceProjectId      
AND PCH.CustomerId = @CustomerId      
AND ISNULL(PCH.IsDeleted, 0) = 0      
      
SET @results = 1      
SET @id_control = 0      
      
WHILE(@results>0)      
BEGIN      
 --INSERT ProjectSegmentChoice          
 INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource,      
 SegmentChoiceCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_SegmentCHoiceId)      
 SELECT PS.SectionId AS SectionId      
 ,PSG.SegmentStatusId      
 ,PSG.SegmentId AS SegmentId      
 ,PCH_Src.ChoiceTypeId AS ChoiceTypeId      
 ,@TargetProjectId AS ProjectId      
 ,@CustomerId AS CustomerId      
 ,PCH_Src.SegmentChoiceSource AS SegmentChoiceSource      
 ,PCH_Src.SegmentChoiceCode AS SegmentChoiceCode      
 ,PCH_Src.CreatedBy AS CreatedBy      
 ,PCH_Src.CreateDate AS CreateDate      
 ,PCH_Src.ModifiedBy AS ModifiedBy      
 ,PCH_Src.ModifiedDate AS ModifiedDate      
 ,PCH_Src.IsDeleted AS IsDeleted      
 ,PCH_Src.SegmentChoiceId AS A_SegmentCHoiceId      
 FROM #tmp_SrcSegmentChoice PCH_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
 ON PCH_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)      
 ON PS.SectionId = PSG.SectionId      
 AND PCH_Src.SegmentId = PSG.A_SegmentId      
 INNER JOIN #SrcSegmentStatusCPTMP SRCS      
ON PCH_Src.SegmentId = SRCS.SegmentId      
 WHERE ISNULL(SRCS.IsDeleted, 0) = 0      
 AND PCH_Src.SrNo > @id_control      
    AND PCH_Src.SrNo <= @id_control + @ProjectSegmentChoice      
        
 SET @results = @@ROWCOUNT      
 -- next batch      
 SET @id_control = @id_control + @ProjectSegmentChoice      
END      
      
--Copy target choices in temp table          
SELECT PCH.*       
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo      
 INTO #tmp_TgtSegmentChoice      
FROM ProjectSegmentChoice PCH WITH (NOLOCK)      
WHERE PCH.ProjectId = @TargetProjectId      
AND PCH.CustomerId = @CustomerId      
AND ISNULL(PCH.IsDeleted, 0) = 0      
      
SET @results = 1       
SET @id_control = 0      
      
WHILE(@results>0)      
BEGIN      
 --INSERT ProjectChoiceOption        
 INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId,      
 CustomerId, ChoiceOptionCode, CreatedBy, CreateDate, ModifiedBy, ModifiedDate, IsDeleted, A_ChoiceOptionId)      
 SELECT PCH.SegmentChoiceId AS SegmentChoiceId      
  ,PCHOP_Src.SortOrder AS SortOrder      
  ,PCHOP_Src.ChoiceOptionSource AS ChoiceOptionSource      
  ,PCHOP_Src.OptionJson AS OptionJson      
  ,@TargetProjectId AS ProjectId      
  ,PCH.SectionId AS SectionId      
  ,@CustomerId AS CustomerId      
  ,PCHOP_Src.ChoiceOptionCode AS ChoiceOptionCode      
  ,PCHOP_Src.CreatedBy AS CreatedBy      
  ,PCHOP_Src.CreateDate AS CreateDate      
  ,PCHOP_Src.ModifiedBy AS ModifiedBy      
  ,PCHOP_Src.ModifiedDate AS ModifiedDate      
  ,PCHOP_Src.IsDeleted AS IsDeleted      
  ,PCHOP_Src.ChoiceOptionId AS A_ChoiceOptionId      
  FROM ProjectChoiceOption PCHOP_Src WITH (NOLOCK)      
  INNER JOIN #tmp_TgtSegmentChoice PCH WITH (NOLOCK)      
  ON PCH.A_SegmentChoiceId = PCHOP_Src.SegmentChoiceId      
  AND ISNULL(PCH.IsDeleted, 0) = ISNULL(PCHOP_Src.IsDeleted, 0)      
  WHERE PCHOP_Src.ProjectId = @SourceProjectId      
  AND PCHOP_Src.CustomerId = @CustomerId      
  AND PCH.SrNo > @id_control      
     AND PCH.SrNo <= @id_control + @ProjectChoiceOption      
        
  SET @results = @@ROWCOUNT      
  -- next batch      
  SET @id_control = @id_control + @ProjectChoiceOption      
END      
--Copy source choices in temp table          
SELECT      
 SCO_Src.*       
 ,ROW_NUMBER() OVER (ORDER BY SectionId) AS SrNo      
 INTO #tmp_SrcSelectedChoiceOption      
FROM SelectedChoiceOption SCO_Src WITH (NOLOCK)      
WHERE SCO_Src.ProjectId = @SourceProjectId      
AND SCO_Src.CustomerId = @CustomerId      
AND ISNULL(SCO_Src.IsDeleted, 0) = 0      
      
SET @results = 1      
SET @id_control = 0      
      
WHILE(@results>0)      
BEGIN      
 --INSERT SelectedChoiceOption          
 INSERT INTO SelectedChoiceOption (SegmentChoiceCode, ChoiceOptionCode, ChoiceOptionSource, IsSelected,      
 SectionId, ProjectId, CustomerId, OptionJson, IsDeleted)      
 SELECT PSCHOP_Src.SegmentChoiceCode AS SegmentChoiceCode      
 ,PSCHOP_Src.ChoiceOptionCode AS ChoiceOptionCode      
 ,PSCHOP_Src.ChoiceOptionSource AS ChoiceOptionSource      
 ,PSCHOP_Src.IsSelected AS IsSelected      
 ,PSC.SectionId AS SectionId      
 ,@TargetProjectId AS ProjectId      
 ,@CustomerId AS CustomerId      
 ,PSCHOP_Src.OptionJson AS OptionJson      
 ,PSCHOP_Src.IsDeleted AS IsDeleted      
 FROM #tmp_SrcSelectedChoiceOption PSCHOP_Src WITH (NOLOCK)      
 INNER JOIN #NewOldSectionIdMapping PSC WITH (NOLOCK)      
 ON PSCHOP_Src.Sectionid = PSC.A_SectionId      
 AND PSCHOP_Src.ProjectId = @SourceProjectId      
 WHERE PSCHOP_Src.ProjectId = @SourceProjectId      
 AND PSCHOP_Src.CustomerId = @CustomerId      
 AND PSCHOP_Src.SrNo > @id_control      
    AND PSCHOP_Src.SrNo <= @id_control + @SelectedChoiceOption      
        
 SET @results = @@ROWCOUNT      
 -- next batch      
 SET @id_control = @id_control + @SelectedChoiceOption      
END      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopySegmentChoices_Description      
     ,@CopySegmentChoices_Description      
     ,1 --IsCompleted     
     ,@CopySegmentChoices_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopySegmentChoices_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
SELECT *      
 ,ROW_NUMBER() OVER (ORDER BY TargetSectionCode) AS SrNo      
 INTO #tmp_SrcSegmentLink      
FROM ProjectSegmentLink WITH (NOLOCK)      
WHERE ProjectId = @SourceProjectId      
AND CustomerId = @CustomerId      
AND ISNULL(IsDeleted, 0) = 0      
      
SET @results = 1       
SET @id_control = 0       
      
WHILE(@results>0)      
BEGIN      
 --INSERT ProjectSegmentLink          
 INSERT INTO ProjectSegmentLink (SourceSectionCode, SourceSegmentStatusCode, SourceSegmentCode, SourceSegmentChoiceCode, SourceChoiceOptionCode, LinkSource,      
 TargetSectionCode, TargetSegmentStatusCode, TargetSegmentCode, TargetSegmentChoiceCode, TargetChoiceOptionCode, LinkTarget,      
 LinkStatusTypeId, IsDeleted, CreateDate, CreatedBy, ModifiedBy, ModifiedDate, ProjectId, CustomerId,      
 SegmentLinkCode, SegmentLinkSourceTypeId)      
 SELECT PSL_Src.SourceSectionCode      
 ,PSL_Src.SourceSegmentStatusCode      
 ,PSL_Src.SourceSegmentCode      
 ,PSL_Src.SourceSegmentChoiceCode      
 ,PSL_Src.SourceChoiceOptionCode      
 ,PSL_Src.LinkSource      
 ,PSL_Src.TargetSectionCode      
 ,PSL_Src.TargetSegmentStatusCode      
 ,PSL_Src.TargetSegmentCode      
 ,PSL_Src.TargetSegmentChoiceCode      
 ,PSL_Src.TargetChoiceOptionCode      
 ,PSL_Src.LinkTarget      
 ,PSL_Src.LinkStatusTypeId      
 ,PSL_Src.IsDeleted      
 ,PSL_Src.CreateDate AS CreateDate      
 ,PSL_Src.CreatedBy AS CreatedBy      
 ,PSL_Src.ModifiedBy AS ModifiedBy      
 ,PSL_Src.ModifiedDate AS ModifiedDate      
 ,@TargetProjectId AS ProjectId      
 ,@CustomerId AS CustomerId      
 ,PSL_Src.SegmentLinkCode      
 ,PSL_Src.SegmentLinkSourceTypeId      
  FROM #tmp_SrcSegmentLink AS PSL_Src WITH (NOLOCK)      
  where PSL_Src.SrNo > @id_control      
 AND PSL_Src.SrNo <= @id_control + @ProjectSegmentLink      
        
 SET @results = @@ROWCOUNT      
 -- next batch      
 SET @id_control = @id_control + @ProjectSegmentLink      
END         
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopySegmentLinks_Description      
     ,@CopySegmentLinks_Description           
     ,1 --IsCompleted          
     ,@CopySegmentLinks_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopySegmentLinks_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--INSERT ProjectNote         
      
SELECT      
 PS.SectionId AS SectionId      
    ,PSST.SegmentStatusId AS SegmentStatusId      
    ,PNT_Src.NoteText AS NoteText      
    ,PNT_Src.CreateDate AS CreateDate      
    ,PNT_Src.ModifiedDate AS ModifiedDate      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
   ,PNT_Src.Title AS Title      
    ,PNT_Src.CreatedBy AS CreatedBy      
    ,PNT_Src.ModifiedBy AS ModifiedBy      
    ,PNT_Src.CreatedUserName      
    ,PNT_Src.ModifiedUserName      
    ,PNT_Src.IsDeleted AS IsDeleted      
    ,PNT_Src.NoteCode AS NoteCode      
    ,PNT_Src.NoteId AS A_NoteId      
 ,ROW_NUMBER() OVER (ORDER BY PSST.SegmentStatusId) AS SrNo      
 into #PN FROM ProjectNote PNT_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PNT_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)      
  ON PNT_Src.SegmentStatusId = PSST.A_SegmentStatusId      
 WHERE PNT_Src.ProjectId = @SourceProjectId      
 AND PNT_Src.CustomerId = @CustomerId;      
       
 SET @results = 1       
SET @id_control = 0      
      
WHILE(@results>0)      
BEGIN      
 INSERT INTO ProjectNote (SectionId, SegmentStatusId, NoteText, CreateDate, ModifiedDate, ProjectId,      
 CustomerId, Title, CreatedBy, ModifiedBy, CreatedUserName, ModifiedUserName, IsDeleted, NoteCode, A_NoteId)      
 select SectionId,SegmentStatusId,NoteText,CreateDate,ModifiedDate,ProjectId      
    ,CustomerId,Title,CreatedBy,ModifiedBy,CreatedUserName,ModifiedUserName,IsDeleted,NoteCode,A_NoteId      
 FROM #PN WHERE SrNo > @id_control      
 AND SrNo <= @id_control + @ProjectNote      
        
 SET @results = @@ROWCOUNT      
 -- next batch      
 SET @id_control = @id_control + @ProjectNote      
END      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyNotes_Description      
     ,@CopyNotes_Description      
     ,1 --IsCompleted          
     ,@CopyNotes_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopyNotes_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--Insert Target ProjectNote in Temp Table          
SELECT      
 PN.NoteId      
   ,PN.SectionId      
   ,PN.ProjectId      
   ,PN.CustomerId      
   ,PN.IsDeleted      
   ,PN.A_NoteId       
   INTO #tmp_TgtProjectNote      
FROM ProjectNote PN WITH (NOLOCK)      
WHERE PN.ProjectId = @TargetProjectId      
AND PN.CustomerId = @CustomerId      
AND ISNULL(IsDeleted, 0) = 0      
      
 --INSERT ProjectNoteImage          
 INSERT INTO ProjectNoteImage (NoteId, SectionId, ImageId, ProjectId, CustomerId)      
 SELECT PN.NoteId AS NoteId      
  ,PS.SectionId AS SectionId      
  ,PNTI_Src.ImageId AS ImageId      
  ,@TargetProjectId AS ProjectId      
  ,@CustomerId AS CustomerId      
  FROM ProjectNoteImage PNTI_Src WITH (NOLOCK)      
  INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PNTI_Src.SectionId = PS.A_SectionId      
  INNER JOIN #tmp_TgtProjectNote PN WITH (NOLOCK)      
  ON PN.SectionId=PS.SectionId      
  AND PN.ProjectId = @TargetProjectId      
  AND PNTI_Src.NoteId = PN.A_NoteId      
  WHERE PNTI_Src.ProjectId = @SourceProjectId      
  AND PNTI_Src.CustomerId = @CustomerId      
        
--INSERT ProjectSegmentImage          
INSERT INTO ProjectSegmentImage (SectionId, ImageId, ProjectId, CustomerId, SegmentId,ImageStyle)      
 SELECT      
  PS.SectionId AS SectionId      
    ,PSI_Src.ImageId AS ImageId      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,0 AS SegmentId          
 ,PSI_Src.ImageStyle          
 FROM ProjectSegmentImage PSI_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PSI_Src.SectionId = PS.A_SectionId      
 WHERE PSI_Src.ProjectId = @SourceProjectId      
 AND PSI_Src.CustomerId = @CustomerId;      
        
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyImages_Description      
     ,@CopyImages_Description      
     ,1 --IsCompleted          
     ,@CopyImages_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopyImages_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
INSERT INTO ProjectReferenceStandard (ProjectId, RefStandardId, RefStdSource, mReplaceRefStdId, RefStdEditionId,      
IsObsolete, RefStdCode, PublicationDate, SectionId, CustomerId, IsDeleted)      
 SELECT      
  @TargetProjectId AS ProjectId      
    ,PRS_Src.RefStandardId AS RefStandardId      
    ,PRS_Src.RefStdSource AS RefStdSource      
    ,PRS_Src.mReplaceRefStdId AS mReplaceRefStdId      
    ,PRS_Src.RefStdEditionId AS RefStdEditionId      
    ,PRS_Src.IsObsolete AS IsObsolete      
    ,PRS_Src.RefStdCode AS RefStdCode      
    ,PRS_Src.PublicationDate AS PublicationDate      
    ,PS.SectionId AS SectionId      
    ,@CustomerId AS CustomerId      
    ,PRS_Src.IsDeleted AS IsDeleted      
 FROM ProjectReferenceStandard PRS_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PRS_Src.SectionId = PS.A_SectionId      
 WHERE PRS_Src.ProjectId = @SourceProjectId      
 AND PRS_Src.CustomerId = @CustomerId;      
      
INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource,      
mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId,      
mSegmentId, RefStdCode, IsDeleted)      
 SELECT      
  PS.SectionId AS SectionId      
    ,PSG.SegmentId AS SegmentId      
    ,PSRS_Src.RefStandardId AS RefStandardId      
    ,PSRS_Src.RefStandardSource AS RefStandardSource      
    ,PSRS_Src.mRefStandardId AS mRefStandardId      
    ,PSRS_Src.CreateDate AS CreateDate      
    ,PSRS_Src.CreatedBy AS CreatedBy      
    ,PSRS_Src.ModifiedDate AS ModifiedDate      
    ,PSRS_Src.ModifiedBy AS ModifiedBy      
    ,@CustomerId AS CustomerId      
    ,@TargetProjectId AS ProjectId      
    ,PSRS_Src.mSegmentId AS mSegmentId      
    ,PSRS_Src.RefStdCode AS RefStdCode      
    ,PSRS_Src.IsDeleted AS IsDeleted      
 FROM ProjectSegmentReferenceStandard PSRS_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PSRS_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)      
  ON PS.SectionId = PSG.SectionId      
   AND PSRS_Src.SegmentId = PSG.A_SegmentId      
 WHERE PSRS_Src.ProjectId = @SourceProjectId      
 AND PSRS_Src.CustomerId = @CustomerId;      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyRefStds_Description      
     ,@CopyRefStds_Description      
     ,1 --IsCompleted          
     ,@CopyRefStds_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopyRefStds_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--Copy source ProjectSegmentRequirementTag in temp table          
SELECT      
 PSRT.* INTO #tmp_SrcProjectSegmentRequirementTag      
FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)      
WHERE PSRT.ProjectId = @SourceProjectId      
AND PSRT.CustomerId = @CustomerId      
AND ISNULL(PSRT.IsDeleted, 0) = 0      
      
--INSERT ProjectSegmentRequirementTag          
INSERT INTO ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate,      
ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId, IsDeleted)      
 SELECT      
  PS.SectionId      
    ,PSST.SegmentStatusId      
    ,PSRT_Src.RequirementTagId      
    ,PSRT_Src.CreateDate      
    ,PSRT_Src.ModifiedDate      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,PSRT_Src.CreatedBy      
    ,PSRT_Src.ModifiedBy      
    ,PSRT_Src.mSegmentRequirementTagId      
    ,PSRT_Src.IsDeleted      
 FROM #tmp_SrcProjectSegmentRequirementTag PSRT_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PSRT_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)      
  --ON PS.SectionId = PSST.SectionId          
  ON PSRT_Src.SegmentStatusId = PSST.A_SegmentStatusId      
 WHERE PSRT_Src.ProjectId = @SourceProjectId      
 AND PSRT_Src.CustomerId = @CustomerId;      
      
--INSERT ProjectSegmentUserTag          
INSERT INTO ProjectSegmentUserTag (SectionId, SegmentStatusId, UserTagId, CreateDate, ModifiedDate,      
ProjectId, CustomerId, CreatedBy, ModifiedBy, IsDeleted)      
 SELECT      
  PS.SectionId      
    ,PSST.SegmentStatusId      
    ,PSUT_Src.UserTagId      
    ,PSUT_Src.CreateDate      
    ,PSUT_Src.ModifiedDate      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,PSUT_Src.CreatedBy      
    ,PSUT_Src.ModifiedBy      
    ,PSUT_Src.IsDeleted      
 FROM ProjectSegmentUserTag PSUT_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PSUT_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtSegmentStatus PSST WITH (NOLOCK)      
  --ON PS.SectionId = PSST.SectionId          
  ON PSUT_Src.SegmentStatusId = PSST.A_SegmentStatusId      
 WHERE PSUT_Src.ProjectId = @SourceProjectId      
 AND PSUT_Src.CustomerId = @CustomerId;      
      
--INSERT ProjectSegmentGlobalTerm          
INSERT INTO ProjectSegmentGlobalTerm (SectionId, SegmentId, mSegmentId, UserGlobalTermId, GlobalTermCode,      
CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, IsLocked, LockedByFullName,      
UserLockedId, IsDeleted)      
 SELECT      
  PS.SectionId      
    ,PSG.SegmentId      
    ,PSGT_Src.mSegmentId      
    ,PSGT_Src.UserGlobalTermId      
    ,PSGT_Src.GlobalTermCode      
    ,PSGT_Src.CreatedDate AS CreatedDate      
    ,PSGT_Src.CreatedBy AS CreatedBy      
    ,PSGT_Src.ModifiedDate AS ModifiedDate      
    ,PSGT_Src.ModifiedBy AS ModifiedBy      
    ,@CustomerId AS CustomerId      
    ,@TargetProjectId AS ProjectId      
    ,PSGT_Src.IsLocked      
    ,PSGT_Src.LockedByFullName      
    ,PSGT_Src.UserLockedId      
    ,PSGT_Src.IsDeleted      
 FROM ProjectSegmentGlobalTerm PSGT_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON PSGT_Src.SectionId = PS.A_SectionId      
 INNER JOIN #tmp_TgtSegment PSG WITH (NOLOCK)      
  ON PSGT_Src.SegmentId = PSG.A_SegmentId      
 WHERE PSGT_Src.ProjectId = @SourceProjectId      
 AND PSGT_Src.CustomerId = @CustomerId;      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyTags_Description      
     ,@CopyTags_Description      
     ,1 --IsCompleted          
     ,@CopyTags_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopyTags_Percentage --Percent         
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--INSERT Header          
INSERT INTO Header (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltHeader, FPHeader, UseSeparateFPHeader, HeaderFooterCategoryId,      
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultHeader, FirstPageHeader, OddPageHeader, EvenPageHeader, DocumentTypeId,IsShowLineAboveHeader,IsShowLineBelowHeader)      
 SELECT      
  @TargetProjectId AS ProjectId      
    ,NULL AS SectionId      
    ,@CustomerId AS CustomerId      
    ,H_Src.Description      
    ,H_Src.IsLocked      
    ,H_Src.LockedByFullName      
    ,H_Src.LockedBy      
    ,H_Src.ShowFirstPage      
    ,H_Src.CreatedBy AS CreatedBy      
    ,H_Src.CreatedDate AS CreatedDate      
    ,H_Src.ModifiedBy AS ModifiedBy      
    ,H_Src.ModifiedDate AS ModifiedDate      
    ,H_Src.TypeId      
    ,H_Src.AltHeader      
    ,H_Src.FPHeader      
    ,H_Src.UseSeparateFPHeader      
    ,H_Src.HeaderFooterCategoryId      
    ,H_Src.[DateFormat]      
    ,H_Src.TimeFormat      
    ,H_Src.HeaderFooterDisplayTypeId      
    ,H_Src.DefaultHeader      
    ,H_Src.FirstPageHeader      
    ,H_Src.OddPageHeader      
    ,H_Src.EvenPageHeader      
    ,H_Src.DocumentTypeId      
 ,H_Src.IsShowLineAboveHeader        
 ,H_Src.IsShowLineBelowHeader        
 FROM Header H_Src WITH (NOLOCK)      
 WHERE H_Src.ProjectId = @SourceProjectId      
 AND ISNULL(H_Src.SectionId, 0) = 0      
 UNION      
 SELECT      
  @TargetProjectId AS ProjectId      
    ,PS.SectionId AS SectionId      
    ,@CustomerId AS CustomerId      
    ,H_Src.Description      
    ,H_Src.IsLocked      
    ,H_Src.LockedByFullName      
    ,H_Src.LockedBy      
    ,H_Src.ShowFirstPage      
    ,H_Src.CreatedBy AS CreatedBy      
    ,H_Src.CreatedDate AS CreatedDate      
    ,H_Src.ModifiedBy AS ModifiedBy      
    ,H_Src.ModifiedDate AS ModifiedDate      
    ,H_Src.TypeId      
    ,H_Src.AltHeader      
    ,H_Src.FPHeader      
    ,H_Src.UseSeparateFPHeader      
    ,H_Src.HeaderFooterCategoryId      
    ,H_Src.[DateFormat]      
    ,H_Src.TimeFormat      
    ,H_Src.HeaderFooterDisplayTypeId      
    ,H_Src.DefaultHeader      
    ,H_Src.FirstPageHeader      
    ,H_Src.OddPageHeader      
    ,H_Src.EvenPageHeader      
    ,H_Src.DocumentTypeId      
 ,H_Src.IsShowLineAboveHeader        
 ,H_Src.IsShowLineBelowHeader        
 FROM Header H_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON H_Src.SectionId = PS.A_SectionId      
 WHERE H_Src.ProjectId = @SourceProjectId;      
      
--INSERT Footer          
INSERT INTO Footer (ProjectId, SectionId, CustomerId, Description, IsLocked, LockedByFullName, LockedBy, ShowFirstPage, CreatedBy, CreatedDate, ModifiedBy, ModifiedDate, TypeId, AltFooter, FPFooter, UseSeparateFPFooter, HeaderFooterCategoryId,      
[DateFormat], TimeFormat, HeaderFooterDisplayTypeId, DefaultFooter, FirstPageFooter, OddPageFooter, EvenPageFooter, DocumentTypeId,IsShowLineAboveFooter,IsShowLineBelowFooter)      
 SELECT      
  @TargetProjectId AS ProjectId      
    ,NULL AS SectionId      
    ,@CustomerId AS CustomerId      
    ,F_Src.Description      
    ,F_Src.IsLocked      
    ,F_Src.LockedByFullName      
    ,F_Src.LockedBy      
    ,F_Src.ShowFirstPage      
    ,F_Src.CreatedBy AS CreatedBy      
    ,F_Src.CreatedDate AS CreatedDate      
    ,F_Src.ModifiedBy AS ModifiedBy      
    ,F_Src.ModifiedDate AS ModifiedDate      
    ,F_Src.TypeId      
    ,F_Src.AltFooter      
    ,F_Src.FPFooter      
    ,F_Src.UseSeparateFPFooter      
    ,F_Src.HeaderFooterCategoryId      
    ,F_Src.[DateFormat]      
    ,F_Src.TimeFormat      
    ,F_Src.HeaderFooterDisplayTypeId      
    ,F_Src.DefaultFooter      
    ,F_Src.FirstPageFooter      
    ,F_Src.OddPageFooter      
    ,F_Src.EvenPageFooter      
    ,F_Src.DocumentTypeId          
 ,F_Src.IsShowLineAboveFooter        
 ,F_Src.IsShowLineBelowFooter          
 FROM Footer F_Src WITH (NOLOCK)      
 WHERE F_Src.ProjectId = @SourceProjectId      
 AND ISNULL(F_Src.SectionId, 0) = 0      
 UNION      
 SELECT      
  @TargetProjectId AS ProjectId      
    ,PS.SectionId AS SectionId      
    ,@CustomerId AS CustomerId      
    ,F_Src.Description      
    ,F_Src.IsLocked      
    ,F_Src.LockedByFullName      
    ,F_Src.LockedBy      
    ,F_Src.ShowFirstPage      
    ,F_Src.CreatedBy AS CreatedBy      
    ,F_Src.CreatedDate AS CreatedDate      
    ,F_Src.ModifiedBy AS ModifiedBy      
    ,F_Src.ModifiedDate AS ModifiedDate      
    ,F_Src.TypeId      
    ,F_Src.AltFooter      
    ,F_Src.FPFooter      
    ,F_Src.UseSeparateFPFooter      
    ,F_Src.HeaderFooterCategoryId      
    ,F_Src.[DateFormat]      
    ,F_Src.TimeFormat      
    ,F_Src.HeaderFooterDisplayTypeId      
    ,F_Src.DefaultFooter      
    ,F_Src.FirstPageFooter      
    ,F_Src.OddPageFooter      
    ,F_Src.EvenPageFooter      
    ,F_Src.DocumentTypeId           
 ,F_Src.IsShowLineAboveFooter        
 ,F_Src.IsShowLineBelowFooter        
 FROM Footer F_Src WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSection PS WITH (NOLOCK)      
  ON F_Src.SectionId = PS.A_SectionId      
 WHERE F_Src.ProjectId = @SourceProjectId;      
      
--INSERT HeaderFooterGlobalTermUsage          
INSERT INTO HeaderFooterGlobalTermUsage (HeaderId, FooterId, UserGlobalTermId, CustomerId      
, ProjectId, HeaderFooterCategoryId, CreatedDate, CreatedById)      
 SELECT      
  HeaderId      
    ,FooterId      
    ,UserGlobalTermId      
    ,@CustomerId AS CustomerId      
    ,@TargetProjectId AS ProjectId      
    ,HeaderFooterCategoryId      
    ,CreatedDate      
    ,CreatedById      
 FROM HeaderFooterGlobalTermUsage WITH (NOLOCK)      
 WHERE ProjectId = @SourceProjectId;      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyHeaderFooter_Description      
     ,@CopyHeaderFooter_Description      
     ,1 --IsCompleted          
     ,@CopyHeaderFooter_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,2 --Status          
   ,@CopyHeaderFooter_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
UPDATE Psmry      
SET Psmry.SpecViewModeId = Psmry_Src.SpecViewModeId      
   ,Psmry.IsIncludeRsInSection = Psmry_Src.IsIncludeRsInSection      
   ,Psmry.IsIncludeReInSection = Psmry_Src.IsIncludeReInSection      
   ,Psmry.BudgetedCostId = Psmry_Src.BudgetedCostId      
   ,Psmry.BudgetedCost = Psmry_Src.BudgetedCost      
   ,Psmry.ActualCost = Psmry_Src.ActualCost      
   ,Psmry.EstimatedArea = Psmry_Src.EstimatedArea      
   ,Psmry.SourceTagFormat = Psmry_Src.SourceTagFormat      
   ,Psmry.IsPrintReferenceEditionDate = Psmry_Src.IsPrintReferenceEditionDate      
   ,Psmry.IsActivateRsCitation = Psmry_Src.IsActivateRsCitation      
   ,Psmry.EstimatedSizeId = Psmry_Src.EstimatedSizeId      
   ,Psmry.EstimatedSizeUoM = Psmry_Src.EstimatedSizeUoM      
   ,Psmry.UnitOfMeasureValueTypeId = Psmry_Src.UnitOfMeasureValueTypeId      
   ,Psmry.TrackChangesModeId = Psmry_Src.TrackChangesModeId      
FROM ProjectSummary Psmry WITH (NOLOCK)      
INNER JOIN ProjectSummary Psmry_Src WITH (NOLOCK)      
 ON Psmry_Src.ProjectId = @SourceProjectId      
WHERE Psmry.ProjectId = @TargetProjectId;      
      
--Insert LuProjectSectionIdSeparator          
INSERT INTO LuProjectSectionIdSeparator (ProjectId, CustomerId, UserId, separator)      
 SELECT      
  @TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,UserId      
    ,LPSIS_Src.separator      
 FROM LuProjectSectionIdSeparator LPSIS_Src WITH (NOLOCK)      
 WHERE ProjectId = @SourceProjectId;      
      
--Insert ProjectPageSetting          
INSERT INTO ProjectPageSetting (MarginTop, MarginBottom, MarginLeft, MarginRight, EdgeHeader, EdgeFooter, IsMirrorMargin, ProjectId, CustomerId)      
 SELECT      
  MarginTop      
    ,MarginBottom      
    ,MarginLeft      
    ,MarginRight      
    ,EdgeHeader      
    ,EdgeFooter      
    ,IsMirrorMargin      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
 FROM ProjectPageSetting WITH (NOLOCK)      
 WHERE ProjectId = @SourceProjectId;      
      
--Insert ProjectPaperSetting          
INSERT INTO ProjectPaperSetting (PaperName, PaperWidth, PaperHeight, PaperOrientation, PaperSource, ProjectId, CustomerId)      
 SELECT      
  PaperName      
    ,PaperWidth      
    ,PaperHeight      
    ,PaperOrientation      
    ,PaperSource      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
 FROM ProjectPaperSetting WITH (NOLOCK)      
 WHERE ProjectId = @SourceProjectId;      
      
--Insert ProjectPrintSetting        
INSERT INTO ProjectPrintSetting (ProjectId, CustomerId, CreatedBy, CreateDate, ModifiedBy,      
ModifiedDate, IsExportInMultipleFiles, IsBeginSectionOnOddPage, IsIncludeAuthorInFileName, TCPrintModeId, IsIncludePageCount, IsIncludeHyperLink        
,KeepWithNext, IsPrintMasterNote, IsPrintProjectNote, IsPrintNoteImage, IsPrintIHSLogo)      
 SELECT      
  @TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,CreatedBy AS CreatedBy      
    ,CreateDate AS CreateDate      
    ,ModifiedBy AS ModifiedBy      
    ,ModifiedDate AS ModifiedDate      
    ,IsExportInMultipleFiles      
    ,IsBeginSectionOnOddPage      
    ,IsIncludeAuthorInFileName      
    ,TCPrintModeId      
    ,IsIncludePageCount      
    ,IsIncludeHyperLink        
 ,KeepWithNext        
 ,IsPrintMasterNote          
 ,IsPrintProjectNote          
 ,IsPrintNoteImage          
 ,IsPrintIHSLogo           
 FROM ProjectPrintSetting WITH (NOLOCK)      
 WHERE ProjectId = @SourceProjectId      
 AND CustomerId = @CustomerId;      
      
INSERT INTO ProjectDateFormat (MasterDataTypeId, ProjectId, CustomerId, UserId,      
ClockFormat, DateFormat, CreateDate)      
 SELECT      
  @MasterDataTypeId AS MasterDataTypeId      
    ,@TargetProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,UserId      
    ,ClockFormat      
    ,DateFormat      
    ,CreateDate      
 FROM ProjectDateFormat WITH (NOLOCK)      
 WHERE ProjectId = @SourceProjectId;      
      
--Make project available to user          
UPDATE P      
SET P.IsDeleted = 0      
   ,P.IsPermanentDeleted = 0      
FROM Project P WITH (NOLOCK)      
WHERE P.ProjectId = @TargetProjectId;      
      
--- INSERT ProjectHyperLink      
SELECT      
  PSS_Target.sectionId      
    ,PSS_Target.SegmentId      
    ,PSS_Target.SegmentStatusId      
    ,PSS_Target.ProjectId      
    ,PSS_Target.CustomerId      
    ,LinkTarget      
    ,LinkText      
    ,LuHyperLinkSourceTypeId      
    ,GETUTCDATE() as CreateDate      
    ,@UserId AS CreatedBy      
    ,PHL.HyperLinkId      
 ,ROW_NUMBER() OVER (ORDER BY PSS_Target.SegmentStatusId) AS SrNo      
 INTO #HL FROM ProjectHyperLink PHL WITH (NOLOCK)      
 INNER JOIN #tmp_TgtSegmentStatus PSS_Target      
  ON PHL.SegmentStatusId = PSS_Target.A_SegmentStatusId      
 WHERE PHL.ProjectId = @PSourceProjectId      
      
SET @results = 1       
SET @id_control = 0      
      
WHILE(@results>0)      
BEGIN      
 INSERT INTO ProjectHyperLink (SectionId, SegmentId, SegmentStatusId, ProjectId,      
 CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy      
 , A_HyperLinkId)      
 SELECT SectionId, SegmentId, SegmentStatusId, ProjectId,      
 CustomerId, LinkTarget, LinkText, LuHyperLinkSourceTypeId, CreateDate, CreatedBy      
 , HyperLinkId      
 FROM #HL      
 WHERE SrNo > @id_control      
 AND SrNo <= @id_control + @ProjectHyperLink      
        
 SET @results = @@ROWCOUNT      
 -- next batch      
 SET @id_control = @id_control + @ProjectHyperLink      
END      
---UPDATE NEW HyperLinkId in SegmentDescription      
DECLARE @MultipleHyperlinkCount INT = 0;      
SELECT      
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl      
FROM ProjectHyperLink WITH (NOLOCK)      
WHERE ProjectId = @TargetProjectId      
GROUP BY SegmentStatusId      
SELECT      
 @MultipleHyperlinkCount = MAX(TotalCountSegmentStatusId)      
FROM #TotalCountSegmentStatusIdTbl      
WHILE (@MultipleHyperlinkCount > 0)      
BEGIN      
UPDATE PS      
SET PS.SegmentDescription = REPLACE(PS.SegmentDescription, '{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}', '{HL#' + CAST(PHL.HyperLinkId AS NVARCHAR(20)) + '}')      
FROM ProjectHyperLink PHL WITH (NOLOCK)      
INNER JOIN ProjectSegment PS WITH (NOLOCK)      
 ON PS.SegmentStatusId = PHL.SegmentStatusId      
 AND PS.SegmentId = PHL.SegmentId      
 AND PS.SectionId = PHL.SectionId      
 AND PS.ProjectId = PHL.ProjectId      
 AND PS.CustomerId = PHL.CustomerId      
WHERE PHL.ProjectId = @TargetProjectId      
AND  PS.SegmentDescription LIKE '%{HL#' + CAST(PHL.A_HyperLinkId AS NVARCHAR(20)) + '}%'      
AND PS.SegmentDescription LIKE '%{HL#%'      
SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;      
END      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyProjectHyperLink_Description      
     ,@CopyProjectHyperLink_Description      
     ,1 --IsCompleted          
     ,@CopyProjectHyperLink_Step  --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,3 --Status          
   ,@CopyProjectHyperLink_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyComplete_Description      
     ,@CopyComplete_Description      
     ,1 --IsCompleted          
     ,@CopyComplete_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,3 --Status          
   ,@CopyComplete_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
END TRY      
BEGIN CATCH      
      
DECLARE @ResultMessage NVARCHAR(MAX);      
SET @ResultMessage = 'Rollback Transaction. Error Number: ' + CONVERT(VARCHAR(MAX), ERROR_NUMBER()) +      
'. Error Message: ' + CONVERT(VARCHAR(MAX), ERROR_MESSAGE()) +      
'. Procedure Name: ' + CONVERT(VARCHAR(MAX), ERROR_PROCEDURE()) +      
'. Error Severity: ' + CONVERT(VARCHAR(5), ERROR_SEVERITY()) +      
'. Line Number: ' + CONVERT(VARCHAR(5), ERROR_LINE());      
      
--Make unavailable this project from user          
UPDATE P      
SET P.IsDeleted = 1      
   ,P.IsPermanentDeleted = 1      
FROM Project P WITH (NOLOCK)      
WHERE P.ProjectId = @TargetProjectId;      
      
      
EXEC usp_MaintainCopyProjectHistory @TargetProjectId      
     ,@CopyFailed_Description      
     ,@ResultMessage      
     ,1 --IsCompleted          
     ,@CopyFailed_Step --Step          
     ,@RequestId      
      
EXEC usp_MaintainCopyProjectProgress @SourceProjectId      
   ,@TargetProjectId      
   ,@UserId      
   ,@CustomerId      
   ,4 --Status          
   ,@CopyFailed_Percentage --Percent          
   ,0 --IsInsertRecord          
   ,@CustomerName      
   ,@UserName;      
      
--Insert add user into the Project Team Member list       
DECLARE @IsOfficeMaster bit=0;      
SELECT TOP 1 @IsOfficeMaster=IsOfficeMaster FROM Project WHERE ProjectId=@TargetProjectId      
EXEC usp_ApplyProjectDefaultSetting @IsOfficeMaster,@TargetProjectId,@PUserId,@CustomerId     
      
EXEC usp_SendEmailCopyProjectFailedJob      
END CATCH      
END
GO
PRINT N'Altering [dbo].[usp_GetProjectDivisionAndSections]...';


GO
ALTER PROCEDURE [dbo].[usp_GetProjectDivisionAndSections]    
(              
 @ProjectId INT NULL,               
 @CustomerId INT NULL,               
 @UserId INT NULL=NULL,               
 @DisciplineId NVARCHAR (1024) NULL='',               
 @CatalogueType NVARCHAR (1024) NULL='FS',               
 @DivisionId NVARCHAR (1024) NULL='',              
 @UserAccessDivisionId NVARCHAR (1024) = ''                  
)              
AS                  
BEGIN          
  DECLARE @PprojectId INT = @ProjectId;          
  DECLARE @PcustomerId INT = @CustomerId;          
  DECLARE @PuserId INT = @UserId;          
  DECLARE @PDisciplineId NVARCHAR (1024) = @DisciplineId;          
  DECLARE @PCatalogueType NVARCHAR (1024) = @CatalogueType;         
  DECLARE @PDivisionId NVARCHAR (1024) = @DivisionId;          
  DECLARE @PUserAccessDivisionId NVARCHAR (1024) = @UserAccessDivisionId;      
          
 --IMP: Apply master updates to project for some types of actions          
 EXEC usp_ApplyMasterUpdatesToProject @PprojectId, @PcustomerId;      
      
 --DECLARE Variables          
 DECLARE @MasterDataTypeId INT = 0;      
 DECLARE @SourceTagFormat VARCHAR(10);      
      
 --Set data into variables              
 SELECT top 1 @MasterDataTypeId=MasterDataTypeId FROM Project WITH(NOLOCK) WHERE ProjectId = @PprojectId option(fast 1) --fast N    
    
SELECT TOP 1 @SourceTagFormat=PS.SourceTagFormat FROM ProjectSummary PS WITH(NOLOCK) WHERE PS.ProjectId = @PprojectId option(fast 1) --fast N    
     
 -- Fetch level 0 segments for status        
 DROP TABLE IF EXISTS #LevelZeroSegments        
 SELECT DISTINCT PSS.SectionId, PSS.SegmentStatusId, PSS.SegmentSource, PSS.SegmentOrigin, PSS.SegmentStatusTypeId      
  INTO #LevelZeroSegments            
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)            
  WHERE PSS.CustomerId = @PCustomerId      
  AND PSS.ProjectId = @PProjectId       
  AND PSS.SequenceNumber = 0      
  AND PSS.IndentLevel = 0      
  AND PSS.ParentSegmentStatusId = 0      
  AND ISNULL(PSS.IsDeleted,0) = 0;    
    
  -- Insert Project Sections into Temp table    
  SELECT      
   PS.SectionId    
  ,PS.mSectionId    
  ,PS.ParentSectionId   
  ,0 AS ParentDivisionId   
  ,PS.ProjectId    
  ,PS.CustomerId    
  ,PS.TemplateId    
  ,PS.DivisionId    
  ,PS.DivisionCode    
  ,PS.[Description]    
  ,PS.LevelId    
  ,PS.IsLastLevel    
  ,PS.SourceTag    
  ,PS.Author    
  ,PS.CreatedBy    
  ,PS.CreateDate    
  ,PS.ModifiedBy    
  ,PS.ModifiedDate    
  ,PS.SectionCode    
  ,PS.IsLocked    
  ,PS.LockedBy    
  ,PS.LockedByFullName    
  ,PS.FormatTypeId    
  INTO #ProjectSectionTemp    
  FROM ProjectSection PS WITH(NOLOCK)    
  WHERE PS.ProjectId = @projectId AND PS.CustomerId = @PcustomerId AND ISNULL(PS.IsDeleted,0) = 0    
    
  update t set ParentDivisionId = PS.ParentSectionId from #ProjectSectionTemp t JOIN ProjectSection PS WITH(NOLOCK) ON   
   t.ParentSectionId = PS.SectionId  
   where t.IsLastLevel = 1;  
  
  -- Insert Deleted Master Sections into Temp table    
  SELECT MS.SectionId, MS.IsDeleted    
  INTO #DeletedMasterSectionTemp    
  FROM SLCMaster..Section MS WITH(NOLOCK) WHERE ISNULL(MS.IsDeleted, 0) = 1    
         
 ;WITH SectionTableCTE as (SELECT DISTINCT          
   PS.SectionId AS SectionId          
  ,ISNULL(PS.mSectionId, 0) AS mSectionId          
  ,ISNULL(PS.ParentSectionId, 0) AS ParentSectionId          
  ,PS.ProjectId AS ProjectId          
  ,PS.CustomerId AS CustomerId          
  ,@PuserId AS UserId          
  ,ISNULL(PS.TemplateId, 0) AS TemplateId          
  ,ISNULL(PS.DivisionId, 0) AS DivisionId     
  ,ISNULL(PS.ParentDivisionId, 0) AS ParentDivisionId  
  ,ISNULL(PS.DivisionCode, '') AS DivisionCode          
  ,ISNULL(PS.Description, '') AS [Description]    
  ,CAST(1 as bit) AS IsDisciplineEnabled          
  ,PS.LevelId AS LevelId          
  ,PS.IsLastLevel AS IsLastLevel          
  ,PS.SourceTag AS SourceTag          
  ,ISNULL(PS.Author, '') AS Author          
  ,ISNULL(PS.CreatedBy, 0) AS CreatedBy          
  ,ISNULL(PS.CreateDate, GETDATE()) AS CreateDate          
  ,ISNULL(PS.ModifiedBy, 0) AS ModifiedBy          
  ,ISNULL(PS.ModifiedDate, GETDATE()) AS ModifiedDate          
  ,(CASE          
    WHEN PSS.SegmentStatusId IS NULL AND          
  PS.mSectionId IS NOT NULL THEN 'M'          
    WHEN PSS.SegmentStatusId IS NULL AND          
  PS.mSectionId IS NULL THEN 'U'          
    WHEN PSS.SegmentStatusId IS NOT NULL AND          
  PSS.SegmentSource = 'M' AND          
  PSS.SegmentOrigin = 'M' THEN 'M'          
    WHEN PSS.SegmentStatusId IS NOT NULL AND          
  PSS.SegmentSource = 'U' AND          
  PSS.SegmentOrigin = 'U' THEN 'U'          
    WHEN PSS.SegmentStatusId IS NOT NULL AND          
  PSS.SegmentSource = 'M' AND          
  PSS.SegmentOrigin = 'U' THEN 'M*'          
   END) AS SegmentOrigin          
  ,COALESCE(PSS.SegmentStatusTypeId, -1) AS SegmentStatusTypeId          
  ,ISNULL(PS.SectionCode, 0) AS SectionCode          
  ,ISNULL(PS.IsLocked, 0) AS IsLocked          
  ,ISNULL(PS.LockedBy, 0) AS LockedBy          
  ,ISNULL(PS.LockedByFullName, '') AS LockedByFullName          
  ,PS.FormatTypeId AS FormatTypeId          
  ,@SourceTagFormat AS SourceTagFormat              
  ,(CASE WHEN (MS.SectionId IS NOT NULL AND MS.IsDeleted = 1) THEN CAST(1 AS BIT) ELSE CAST(0 AS BIT) END) AS IsMasterDeleted      
  ,(CASE          
    WHEN PS.IsLastLevel = 1 AND          
  (PS.mSectionId IS NULL OR          
  PS.mSectionId = 0) THEN 1          
    ELSE 0          
   END) AS IsUserSection          
  FROM #ProjectSectionTemp PS WITH (NOLOCK)          
  LEFT JOIN #DeletedMasterSectionTemp MS WITH (NOLOCK)          
   ON PS.mSectionId = MS.SectionId          
  LEFT OUTER JOIN #LevelZeroSegments AS PSS WITH (NOLOCK) ON PS.SectionId = PSS.SectionId    
 )      
         
 SELECT * FROM SectionTableCTE ORDER BY SourceTag ASC, Author ASC      
      
END
GO
PRINT N'Altering [dbo].[usp_ApplyTemplateStyle]...';


GO
ALTER PROCEDURE [dbo].[usp_ApplyTemplateStyle]        
@CustomerId INT,      
@TitleFormatId INT,       
@TemplateStyleDtoListJson nvarchar(MAX),      
@templateId INT NULL      
AS    
        
BEGIN    
DECLARE @PCustomerId INT = @CustomerId;    
DECLARE @PTitleFormatId INT = @TitleFormatId;    
DECLARE @PTemplateStyleDtoListJson nvarchar(MAX) = @TemplateStyleDtoListJson;    
DECLARE @PtemplateId INT = @templateId;    
      
DECLARE @oldStyleId INT = NULL;    
      
DECLARE @newStyleId INT = NULL;    
      
DECLARE @counter INT = 1;    
    
--Set Nocount On      
SET NOCOUNT ON;    
      
      
--DECLARE TABLES      
 DECLARE @TemplateStyletbl TABLE(      
 RowId INT,      
 TemplateStyleId INT NULL,          
 TemplateId INT NULL,       
 StyleId   INT NULL,      
 Level INT NULL      
 );    
      
      
 --CONVERT STRING JSONS INTO TABLES      
IF @PTemplateStyleDtoListJson != ''        
BEGIN    
INSERT INTO @TemplateStyletbl (RowId, TemplateStyleId, TemplateId, StyleId, Level)    
 SELECT    
  ROW_NUMBER() OVER (ORDER BY Level ASC) AS RowId    
    ,TemplateStyleId    
    ,TemplateId    
    ,StyleId    
    ,Level    
 FROM OPENJSON(@PTemplateStyleDtoListJson)    
 WITH (    
 TemplateStyleId INT '$.TemplateStyleId',    
 TemplateId INT '$.TemplateId',    
 StyleId INT '$.StyleId',    
 Level INT '$.Level'    
 );    
END    
    
    
UPDATE t    
SET t.TitleFormatId = @PTitleFormatId    
FROM Template t WITH (NOLOCK)    
WHERE t.TemplateId = @PtemplateId;    
    
    
DECLARE @TemplateStyletblRowCount INT = (SELECT    
  COUNT(1)    
 FROM @TemplateStyletbl)    
    
WHILE @counter <= @TemplateStyletblRowCount    
BEGIN    
    
(SELECT    
 @newStyleId = tt.StyleId    
   ,@oldStyleId = T.StyleId    
FROM TemplateStyle T WITH (NOLOCK)    
INNER JOIN @TemplateStyletbl tt    
 ON T.Level = tt.Level    
WHERE T.TemplateId = @PtemplateId    
AND CustomerId = @PCustomerId    
AND T.Level = tt.Level    
AND TT.RowId = @counter    
);    
    
IF (@oldStyleId != @newStyleId    
 AND @oldStyleId IS NOT NULL)    
BEGIN    
DECLARE @isNewStyleAllocated AS INT = (SELECT    
  COUNT(1)    
 FROM TemplateStyle WITH (NOLOCK)    
 WHERE StyleId = @newStyleId);    
IF (@isNewStyleAllocated > 0)    
BEGIN    
    
    
--ALTER TABLE #TEMP DROP COLUMN StyleId;    
    
INSERT INTO Style    
 SELECT    
  Alignment    
    ,IsBold    
    ,CharAfterNumber    
    ,CharBeforeNumber    
    ,FontName    
    ,FontSize    
    ,HangingIndent    
    ,IncludePrevious    
    ,IsItalic    
    ,LeftIndent    
    ,NumberFormat    
    ,NumberPosition    
    ,PrintUpperCase    
    ,ShowNumber    
    ,StartAt    
    ,Strikeout    
    ,Name    
    ,TopDistance    
    ,Underline    
    ,SpaceBelowParagraph    
    ,IsSystem    
    ,CustomerId    
    ,IsDeleted    
    ,CreatedBy    
    ,CreateDate    
    ,ModifiedBy    
    ,ModifiedDate    
    ,Level    
    ,MasterDataTypeId    
    ,A_StyleId    
 ,IsTransferred  
 FROM Style WITH (NOLOCK)    
 WHERE StyleId = @newStyleId;    
    
SET @newStyleId = @@identity;    
        
 END    
    
UPDATE ts    
SET ts.StyleId = @newStyleId    
FROM TemplateStyle ts WITH (NOLOCK)    
WHERE ts.TemplateId = @PtemplateId    
AND ts.StyleId = @oldStyleId;    
    
UPDATE s    
SET s.Level = (SELECT    
  Level    
 FROM TemplateStyle WITH (NOLOCK)    
 WHERE StyleId = @newStyleId)    
FROM Style s WITH (NOLOCK)    
WHERE StyleId = @oldStyleId    
    
UPDATE S    
SET S.IsSystem = 0    
FROM Style S WITH (NOLOCK)    
INNER JOIN TemplateStyle TS WITH (NOLOCK)    
 ON TS.StyleId = S.StyleId    
INNER JOIN Template T WITH (NOLOCK)    
 ON T.TemplateId = TS.TemplateId    
WHERE TS.StyleId = @newStyleId    
AND T.IsSystem = 0    
    
END;    
    
SET @counter = @counter + 1;    
      
END;    
    
    
--call sp to get applied styles      
EXEC usp_GetAppliedStyles @PtemplateId    
    
END
GO
PRINT N'Altering [dbo].[CopyAndUnArchiveProjectJob]...';


GO
ALTER PROCEDURE [dbo].[CopyAndUnArchiveProjectJob]  
AS  
BEGIN  
   
    --find and mark as failed copy project requests which running loner(more than 30 mins)  
    EXEC [dbo].[usp_UpdateCopyProjectStepProgress]  
  
 EXEC [dbo].[usp_SendEmailCopyProjectFailedJob]  
  
 IF(NOT EXISTS(SELECT TOP 1 1 FROM [dbo].CopyProjectRequest WITH(nolock) WHERE StatusId=2 AND CopyProjectTypeId=1))  
 BEGIN  
  DECLARE @SourceProjectId INT;  
  DECLARE @TargetProjectId INT;  
  DECLARE @CustomerId INT;  
  DECLARE @UserId INT;  
  DECLARe @RequestId INt;  
   
  SELECT TOP 1  
   @SourceProjectId = SourceProjectId  
     ,@TargetProjectId = TargetProjectId  
     ,@CustomerId = CustomerId  
     ,@UserId = CreatedById  
     ,@RequestId = RequestId  
  FROM [dbo].[CopyProjectRequest] WITH(nolock)   
  WHERE StatusId=1 AND ISNULL(IsDeleted,0)=0  
   AND CopyProjectTypeId=1
  ORDER BY CreatedDate ASC  
  
  IF(@TargetProjectId>0)  
  BEGIN  
   EXEC [dbo].[usp_CopyProject] @SourceProjectId  
       ,@TargetProjectId  
       ,@CustomerId  
       ,@UserId  
       ,@RequestId  
  END  
 END  
  
 IF(NOT EXISTS(SELECT TOP 1 1 FROM [dbo].CopyProjectRequest WITH(nolock) WHERE StatusId=2  AND CopyProjectTypeId=1))  
 BEGIN  
  EXECUTE [dbo].[sp_UnArchiveProject]  
 END  
  
END
GO
PRINT N'Refreshing [dbo].[usp_DeleteProjectForJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProjectForJob]';


GO
PRINT N'Refreshing [dbo].[usp_MapSectionToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapSectionToProject]';


GO
PRINT N'Refreshing [dbo].[usp_RemoveNotification]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_RemoveNotification]';


GO
PRINT N'Refreshing [dbo].[GetSubmittals]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[GetSubmittals]';


GO
PRINT N'Refreshing [dbo].[getProjectDetailsById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[getProjectDetailsById]';


GO
PRINT N'Refreshing [dbo].[getProjectListById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[getProjectListById]';


GO
PRINT N'Refreshing [dbo].[sp_LoadUnMappedMasterSectionsToExistingProjectUpdates]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[sp_LoadUnMappedMasterSectionsToExistingProjectUpdates]';


GO
PRINT N'Refreshing [dbo].[usp_ArchivedProjectsList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ArchivedProjectsList]';


GO
PRINT N'Refreshing [dbo].[usp_ArchiveMigratedProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ArchiveMigratedProject]';


GO
PRINT N'Refreshing [dbo].[usp_ArchiveProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ArchiveProject]';


GO
PRINT N'Refreshing [dbo].[usp_CalculateDivisionIdForUserSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CalculateDivisionIdForUserSection]';


GO
PRINT N'Refreshing [dbo].[usp_CheckDivisionIsAccessForImportWord]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CheckDivisionIsAccessForImportWord]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSpecDataSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSpecDataSections]';


GO
PRINT N'Refreshing [dbo].[usp_DataLoadMaterialSectionMapping]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DataLoadMaterialSectionMapping]';


GO
PRINT N'Refreshing [dbo].[usp_deletedMasterSectionsFromProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deletedMasterSectionsFromProject]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteMasterSection_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteMasterSection_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProject]';


GO
PRINT N'Refreshing [dbo].[usp_deleteProjectById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteProjectById]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProjectID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProjectID]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteProjectPermanent]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteProjectPermanent]';


GO
PRINT N'Refreshing [dbo].[usp_DeleteUserTemplate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DeleteUserTemplate]';


GO
PRINT N'Refreshing [dbo].[usp_GetArchievedProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetArchievedProjects]';


GO
PRINT N'Refreshing [dbo].[usp_getDeletedMasterSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getDeletedMasterSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetDeletedProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetDeletedProjects]';


GO
PRINT N'Refreshing [dbo].[usp_getDisciplineSectionId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getDisciplineSectionId]';


GO
PRINT N'Refreshing [dbo].[usp_GetDivisionsAndSectionsForPrint]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetDivisionsAndSectionsForPrint]';


GO
PRINT N'Refreshing [dbo].[usp_GetExistingProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetExistingProjects]';


GO
PRINT N'Refreshing [dbo].[usp_getGTDateFormat]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getGTDateFormat]';


GO
PRINT N'Refreshing [dbo].[usp_getLastActivityDateOfUser]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getLastActivityDateOfUser]';


GO
PRINT N'Refreshing [dbo].[usp_GetLimitAccessProjectList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetLimitAccessProjectList]';


GO
PRINT N'Refreshing [dbo].[usp_GetOfficeMaster]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetOfficeMaster]';


GO
PRINT N'Refreshing [dbo].[usp_GetParentSectionIdForImportedSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetParentSectionIdForImportedSection]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectAndSectionData]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectAndSectionData]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectById]';


GO
PRINT N'Refreshing [dbo].[usp_getProjectCountByCustomerId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getProjectCountByCustomerId]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectCountDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectCountDetails]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectForImportSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectForImportSection]';


GO
PRINT N'Refreshing [dbo].[usp_getProjectNameById]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getProjectNameById]';


GO
PRINT N'Refreshing [dbo].[usp_getProjectsByID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getProjectsByID]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectSegmentReferenceStandards]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectSegmentReferenceStandards]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectSummary]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectSummary]';


GO
PRINT N'Refreshing [dbo].[usp_GetProjectTemplateStyle]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetProjectTemplateStyle]';


GO
PRINT N'Refreshing [dbo].[usp_GetRecentProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetRecentProjects]';


GO
PRINT N'Refreshing [dbo].[usp_GetSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSections]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegments_Work]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegments_Work]';


GO
PRINT N'Refreshing [dbo].[usp_GetSourceTargetLinksOfSegmentOrChoice]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSourceTargetLinksOfSegmentOrChoice]';


GO
PRINT N'Refreshing [dbo].[usp_GetSpecDataSectionList]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSpecDataSectionList]';


GO
PRINT N'Refreshing [dbo].[usp_GetSpecDataSectionListPDF]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSpecDataSectionListPDF]';


GO
PRINT N'Refreshing [dbo].[usp_GetStandardProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetStandardProjects]';


GO
PRINT N'Refreshing [dbo].[usp_GetSummaryInfo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSummaryInfo]';


GO
PRINT N'Refreshing [dbo].[usp_GetUpdates]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetUpdates]';


GO
PRINT N'Refreshing [dbo].[usp_InsertNewProjectSummary]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_InsertNewProjectSummary]';


GO
PRINT N'Refreshing [dbo].[usp_InsertNewSection_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_InsertNewSection_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_IsProjectNameExist]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_IsProjectNameExist]';


GO
PRINT N'Refreshing [dbo].[usp_IsProjectOwner]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_IsProjectOwner]';


GO
PRINT N'Refreshing [dbo].[usp_RestoreProjectID]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_RestoreProjectID]';


GO
PRINT N'Refreshing [dbo].[usp_SaveAndUpdateRvtFileDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SaveAndUpdateRvtFileDetails]';


GO
PRINT N'Refreshing [dbo].[usp_SaveAppliedTemplateId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SaveAppliedTemplateId]';


GO
PRINT N'Refreshing [dbo].[usp_SaveProjectDefaultPrivacySetting]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SaveProjectDefaultPrivacySetting]';


GO
PRINT N'Refreshing [dbo].[usp_SetDivisionIdForUserSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SetDivisionIdForUserSection]';


GO
PRINT N'Refreshing [dbo].[usp_SetLockUnlockProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SetLockUnlockProject]';


GO
PRINT N'Refreshing [dbo].[usp_UnArchiveProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UnArchiveProject]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateProjectLastModifiedDate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateProjectLastModifiedDate]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateProjectSummaryInfo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateProjectSummaryInfo]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSection_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSection_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_updateSectionLinkStatus]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_updateSectionLinkStatus]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSegmentStatus_ApplyMasterUpdate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSegmentStatus_ApplyMasterUpdate]';


GO
PRINT N'Refreshing [dbo].[usp_updateTemplateId]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_updateTemplateId]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateUserTrackChangesSegment]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateUserTrackChangesSegment]';


GO
PRINT N'Refreshing [dbo].[usp_ApplyMasterUpdateToProjects]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ApplyMasterUpdateToProjects]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateProjectGlobalTerm]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateProjectGlobalTerm]';


GO
PRINT N'Refreshing [dbo].[usp_ImportSectionFromProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ImportSectionFromProject]';


GO
PRINT N'Refreshing [dbo].[usp_UpdateSectionsIdName]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_UpdateSectionsIdName]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSectionFromMasterTemplate_Job]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSectionFromMasterTemplate_Job]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSegmentsForImportedSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSegmentsForImportedSection]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSegmentsForImportedSectionForImportProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSegmentsForImportedSectionForImportProject]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSegmentsForImportedSectionPOC]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSegmentsForImportedSectionPOC]';


GO
PRINT N'Refreshing [dbo].[usp_CreateTargetSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateTargetSection]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSpecDataSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSpecDataSegments]';


GO
PRINT N'Refreshing [dbo].[usp_MapMasterDataToProjectForSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapMasterDataToProjectForSection]';


GO
PRINT N'Refreshing [dbo].[usp_SpecDataCreateSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SpecDataCreateSegments]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSectionJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSectionJob]';


GO
PRINT N'Refreshing [dbo].[usp_GetSectionsdemo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSectionsdemo]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentLinkDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentLinkDetails]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentLinkDetailsForJob]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentLinkDetailsForJob]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentLinkDetailsNew]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentLinkDetailsNew]';


GO
PRINT N'Refreshing [dbo].[usp_GetSpecViewMode]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSpecViewMode]';


GO
PRINT N'Refreshing [dbo].[usp_GetTrackChangeDetails]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTrackChangeDetails]';


GO
PRINT N'Refreshing [dbo].[usp_GetTrackChangesModeInfo]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTrackChangesModeInfo]';


GO
PRINT N'Refreshing [dbo].[usp_SetProjectView]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SetProjectView]';


GO
PRINT N'Refreshing [dbo].[usp_SpecDataMapSectionToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_SpecDataMapSectionToProject]';


GO
PRINT N'Refreshing [dbo].[usp_CreateTemplate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateTemplate]';


GO
PRINT N'Refreshing [dbo].[usp_DuplicatestyleParagraphLineSpace]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DuplicatestyleParagraphLineSpace]';


GO
PRINT N'Refreshing [dbo].[usp_DuplicateTemplates]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_DuplicateTemplates]';


GO
PRINT N'Refreshing [dbo].[usp_GetAppliedStyles]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetAppliedStyles]';


GO
PRINT N'Refreshing [dbo].[usp_GetCustomerDataForPDFExport]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetCustomerDataForPDFExport]';


GO
PRINT N'Refreshing [dbo].[usp_getTemplateStyles]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_getTemplateStyles]';


GO
PRINT N'Refreshing [dbo].[usp_GetTemplateStylesWithLevels]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetTemplateStylesWithLevels]';


GO
PRINT N'Refreshing [dbo].[usp_ModifyTemplate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ModifyTemplate]';


GO
PRINT N'Refreshing [dbo].[usp_RemoveIsDeletedRecords]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_RemoveIsDeletedRecords]';


GO
PRINT N'Refreshing [dbo].[usp_deleteUserSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_deleteUserSegments]';


GO
PRINT N'Refreshing [dbo].[usp_MapSectionToProject_Work]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_MapSectionToProject_Work]';


GO
PRINT N'Refreshing [dbo].[usp_ApplyMasterUpdatesToProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_ApplyMasterUpdatesToProject]';


GO
PRINT N'Refreshing [dbo].[usp_CreateNewProject]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateNewProject]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSectionFromMasterTemplate]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSectionFromMasterTemplate]';


GO
PRINT N'Refreshing [dbo].[usp_CreateSectionFromTemplateRequest]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CreateSectionFromTemplateRequest]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegments]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegments]';


GO
PRINT N'Refreshing [dbo].[usp_GetAllSections]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetAllSections]';


GO
PRINT N'Refreshing [dbo].[usp_CopyProjectSection]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_CopyProjectSection]';


GO
PRINT N'Refreshing [dbo].[usp_GetSegmentMappingData]...';


GO
EXECUTE sp_refreshsqlmodule N'[dbo].[usp_GetSegmentMappingData]';


GO
