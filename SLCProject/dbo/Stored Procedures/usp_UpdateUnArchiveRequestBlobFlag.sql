CREATE PROCEDURE [dbo].[usp_UpdateUnArchiveRequestBlobFlag]  
(  
 @NotificationDetailsListJson NVARCHAR(MAX)  
)  
As   
BEGIN  
 DROP TABLE IF EXISTS #UnArchiveRequestBlob  
  
  CREATE TABLE #UnArchiveRequestBlob (  
   DestinationProjectId INT NULL  
  ,DestinationCustomerId INT NULL  
  );  
  
 INSERT INTO #UnArchiveRequestBlob (DestinationProjectId, DestinationCustomerId)  
  SELECT  
  *  
  FROM OPENJSON(@NotificationDetailsListJson)  
  WITH (  
   DestinationProjectId INT '$.DestinationProjectId',  
   DestinationCustomerId INT '$.DestinationCustomerId'
  )  
  
 Update UAPR SET UAPR.IsBlobCopied = 1  
 FROM UnArchiveProjectRequest   UAPR WITH(NOLOCK)  
 INNER JOIN #UnArchiveRequestBlob t  
 ON t.DestinationProjectId = UAPR.SLCProd_ProjectId  
 Where UAPR.StatusId = 3   
 AND UAPR.IsBlobCopied = 0  
  
END