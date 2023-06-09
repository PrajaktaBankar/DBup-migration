CREATE PROCEDURE usp_GetImportSectionProgress       
@UserId INT              
AS              
BEGIN  
       
  -- Select Import Progress into #ImportProgress  
  SELECT  
 CPR.RequestId     
   ,CPR.TargetProjectId AS ProjectId  
   ,CPR.TargetSectionId AS SectionId  
   ,PS.[Description] AS [TaskName]  
   ,CPR.CreatedById AS UserId  
   ,CPR.CustomerId  
   ,CPR.CompletedPercentage  
   ,CPR.StatusId  
   ,CPR.CreatedDate AS RequestDateTime  
   ,LCS.StatusDescription  
   ,CPR.IsNotify  
   ,CPR.ModifiedDate  
   ,CPR.source
  ,FORMAT(CPR.CreatedDate,'yyyy-MM-ddTHH:mm:ss') as RequestDateTimeStr  
   ,DATEADD(DAY, 30, CPR.CreatedDate) AS RequestExpiryDateTime          
 INTO #ImportProgress  
 FROM ImportProjectRequest CPR WITH (NOLOCK)         
 INNER JOIN LuCopyStatus LCS WITH (NOLOCK)          
  ON LCS.CopyStatusId = CPR.StatusId          
   INNER JOIN ProjectSection PS WITH(NOLOCK)    
    ON PS.SectionId=CPR.TargetSectionId    
 WHERE CPR.CreatedById = @UserId  
 AND Source IN('SpecAPI','Import from Template')  
 AND ISNULL(CPR.IsDeleted, 0) = 0  
 AND (CPR.IsNotify = 0 OR DATEADD(SECOND, 7, CPR.ModifiedDate) > GETUTCDATE())  
  
   -- Update Fetched records as Notified  
   UPDATE IPR    
   SET IPR.IsNotify = 1    
   FROM ImportProjectRequest IPR WITH (NOLOCK)      
   INNER JOIN #ImportProgress ImPrg  
   ON IPR.RequestId = ImPrg.RequestId    
     
   -- Fetch Imprort Progress notifications       
   SELECT * FROM #ImportProgress  
          
          
END