CREATE PROCEDURE [dbo].[usp_GetCopyProjectProgress]    
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