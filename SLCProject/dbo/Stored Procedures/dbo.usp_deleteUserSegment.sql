
CREATE PROCEDURE [dbo].[usp_deleteUserSegment]                    
(                    
 @SegmentStatusId NVARCHAR(MAX)                  
)          
AS                    
BEGIN  
 BEGIN TRY      
  DECLARE @PSegmentStatusId NVARCHAR(MAX) =  @SegmentStatusId;  
  DROP TABLE IF EXISTS #SegStsTemp  
  CREATE TABLE #SegStsTemp(      
    SegmentStatusId BIGINT,      
    ProjectId INT,      
    SectionId INT,      
    SegmentId BIGINT,      
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
  ON PSGT.ProjectId = T.ProjectId AND PSGT.SectionId = T.SectionId   
  AND (PSGT.SegmentId = T.SegmentId  
  OR PSGT.mSegmentId = T.mSegmentId  
  OR PSGT.SegmentId = 0)  
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
  SELECT PSC.SegmentChoiceId,PSC.SectionId,PSC.SegmentStatusId,PSC.SegmentChoiceCode,PSC.CustomerId
  INTO #PSC FROM #SegStsTemp T INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)  
  ON T.ProjectId = PSC.ProjectId AND T.CustomerId = PSC.CustomerId
  AND PSC.SectionId=T.SectionId AND PSC.SegmentStatusId = T.SegmentStatusId
  --AND PSC.ProjectId=T.ProjectId  
  WHERE PSC.SegmentChoiceSource = @Source  
  
  UPDATE PSC  
  SET PSC.IsDeleted = 1  
  FROM #PSC T INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)  
  ON PSC.SegmentChoiceId=T.SegmentChoiceId  
  AND PSC.SectionId=T.SectionId AND PSC.SegmentStatusId = T.SegmentStatusId
  
  DROP TABLE IF EXISTS #PCO  
  SELECT PCO.ChoiceOptionId,PCO.SegmentChoiceId,PCO.SectionId,PCO.ProjectId,PCO.ChoiceOptionCode,T.SegmentChoiceCode,T.CustomerId
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
   ON SCP.ProjectId=T.ProjectId AND SCP.CustomerId = T.CustomerId AND SCP.SectionId=T.SectionId   
   AND SCP.SegmentChoiceCode=T.SegmentChoiceCode  
   AND SCP.ChoiceOptionCode = T.ChoiceOptionCode  
  WHERE SCP.ChoiceOptionSource = @Source  
  
  UPDATE PS  
  SET PS.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectSegment PS WITH (NOLOCK)  
  ON T.ProjectId = PS.ProjectId AND T.SectionId = PS.SectionId AND T.SegmentStatusId = PS.SegmentStatusId
  --PS.SegmentStatusId = T.SegmentStatusId  
  --AND PS.SectionId= T.SectionId  
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
  ON T.ProjectId = PSRT.ProjectId AND T.SectionId = PSRT.SectionId AND T.SegmentStatusId = PSRT.SegmentStatusId
  --PSRT.SegmentStatusId = T.SegmentStatusId  
  --AND PSRT.SectionId=T.SectionId  
   
  UPDATE PSUT  
  SET PSUT.IsDeleted = 1  
  FROM #SegStsTemp T INNER JOIN ProjectSegmentUserTag PSUT WITH (NOLOCK)  
  ON T.CustomerId = PSUT.CustomerId AND T.ProjectId = PSUT.ProjectId AND T.SectionId = PSUT.SectionId AND PSUT.SegmentStatusId = T.SegmentStatusId  
  
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

   DECLARE @AutoSaveLoggingId INT =  (SELECT @@IDENTITY AS [@@IDENTITY]);
   THROW 50010, @AutoSaveLoggingId, 1;
 END CATCH  
END
GO


