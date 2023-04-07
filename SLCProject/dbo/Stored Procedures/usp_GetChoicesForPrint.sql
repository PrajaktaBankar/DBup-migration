
CREATE PROCEDURE [dbo].[usp_GetChoicesForPrint]
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
 INNER JOIN @SectionIdTbl stb ON psc.SectionId = stb.SectionId AND PSC.ProjectId = @PProjectId AND PSC.CustomerId = @PCustomerId
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId                        
  AND pco.SectionId = psc.SectionId                        
  AND pco.ProjectId = psc.ProjectId                        
  AND pco.CustomerId = psc.CustomerId          
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ProjectId = sco.ProjectId                        
  AND psc.CustomerId = sco.CustomerId AND psc.SectionId = sco.SectionId AND psc.SegmentChoiceCode = sco.SegmentChoiceCode
  AND pco.ChoiceOptionCode = sco.ChoiceOptionCode
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource
 INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK) ON slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode                        
 WHERE PSC.ProjectId = @PProjectId AND PSC.CustomerId = @PCustomerId AND sco.SelectedChoiceOptionId IS NULL                        
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
 LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK) ON pco.ProjectId = sco.ProjectId                        
  AND pco.CustomerId = sco.CustomerId AND pco.SectionId = sco.SectionId AND psc.SegmentChoiceCode = sco.SegmentChoiceCode AND pco.ChoiceOptionCode = sco.ChoiceOptionCode                        
  AND sco.ChoiceOptionSource = pco.ChoiceOptionSource                        
 WHERE psc.ProjectId = @PProjectId AND psc.CustomerId = @PCustomerId AND ISNULL(sco.IsDeleted, 0) = 1                        
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
     
 SELECT PSST.SectionId,PSST.SegmentId, PSST.mSegmentId
	,PSST.ProjectId, PSST.CustomerId, PSST.SegmentStatusId INTO #tempPSS FROM @SectionIdTbl STBL    
 INNER JOIN  ProjectSegmentStatus PSST WITH (NOLOCK)    
 ON PSST.ProjectId = @PProjectId AND PSST.SectionId = STBL.SectionId AND PSST.CustomerId = @PCustomerId
 LEFT OUTER JOIN TrackSegmentStatusType TSST WITH(NOLOCK) ON PSST.SegmentStatusId=TSST.SegmentStatusId AND PSST.SectionId=TSST.SectionId
 AND PSST.ProjectId = TSST.ProjectId
 --AND TSST.SegmentStatusTypeId <> ISNULL(TSST.InitialStatusSegmentStatusTypeId,0)   
 --AND PSST.SegmentStatusTypeId <> ISNULL(TSST.InitialStatusSegmentStatusTypeId,0)   
 AND isnull(TSST.IsAccepted,0)=0      
 WHERE PSST.ProjectId = @PProjectId                        
  AND PSST.CustomerId = @PCustomerId                        
  AND ISNULL(PSST.IsDeleted,0)=0    
    AND (                        
   @PIsActiveOnly = 0                        
   OR (                        
    PSST.SegmentStatusTypeId > 0 AND PSST.SegmentStatusTypeId < 6 AND PSST.IsParentSegmentStatusActive = 1                    
    OR TSST.SegmentStatusTypeId IS NOT NULL AND ISNULL(TSST.IsAccepted, 0) = 0                       
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
	WHERE PSST.ProjectId = @PProjectId AND PSST.CustomerId = @PCustomerId
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
 INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK) 
 ON PSST.SegmentId = PCH.SegmentId                        
 --ON PSST.SectionId = PCH.SectionId AND PSST.SegmentStatusId = PCH.SegmentStatusId AND PSST.SegmentId = PCH.SegmentId
  AND ISNULL(PCH.IsDeleted, 0) = 0                        
 INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK) ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId AND ISNULL(PCHOP.IsDeleted, 0) = 0
  INNER JOIN #tmp_SelectedChoiceOption PSCHOP WITH (NOLOCK) ON PCH.ProjectId = PSCHOP.ProjectId AND PCH.CustomerId = PSCHOP.CustomerId
	AND PCH.SectionId = PSCHOP.SectionId
  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode
  AND PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode  
	AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource
  AND PSCHOP.ChoiceOptionSource = 'U'
 WHERE PCH.ProjectId = @PProjectId AND PCH.CustomerId = @PCustomerId
  AND PCHOP.ProjectId = @PProjectId AND PCHOP.CustomerId = @PCustomerId
  AND PSST.ProjectId = @PProjectId AND PSST.CustomerId = @PCustomerId
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


