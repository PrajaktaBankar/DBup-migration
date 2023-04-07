
CREATE PROCEDURE [dbo].[usp_deleteUserModifications]    
(            
 @SegmentStatusId BIGINT            
)            
AS            
BEGIN
BEGIN TRY

 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;

--EXEC [dbo].[usp_DeleteSegmentsGTMapping] @PSegmentStatusId
--EXEC [dbo].[usp_DeleteSegmentsRSMapping] @PSegmentStatusId

--Default variables  
DECLARE @Source VARCHAR(1) = 'U';
   DECLARE @CustomerId INT;      
   DECLARE @ProjectId  INT;      
   DECLARE @SectionId  INT;      
   DECLARE @SegmentId  BIGINT;      
   DECLARE @MSegmentId INT;      
   DECLARE @UserId INT;

SELECT
	@ProjectId = ProjectId
   ,@SectionId = SectionId
   ,@CustomerId = CustomerId
   ,@UserId = 0
   ,@SegmentId = SegmentId
   ,@MSegmentId = MSegmentId
FROM ProjectSegmentStatus WITH (NOLOCK)
WHERE SegmentStatusId = @PSegmentStatusId

UPDATE PSGT
SET PSGT.IsDeleted = 1
FROM ProjectSegmentGlobalTerm PSGT WITH (NOLOCK)
WHERE PSGT.SectionId = @SectionId
AND (PSGT.SegmentId = @SegmentId
OR PSGT.mSegmentId = @MSegmentId
OR PSGT.SegmentId = 0)
AND ISNULL(PSGT.IsDeleted,0) = 0
AND PSGT.ProjectId = @ProjectId

UPDATE PSRS
SET PSRS.IsDeleted = 1
FROM ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)
WHERE PSRS.SectionId = @SectionId
AND (PSRS.SegmentId = @SegmentId
OR PSRS.mSegmentId = @MSegmentId
OR PSRS.SegmentId = 0)
AND PSRS.ProjectId = @ProjectId

UPDATE PRS
SET PRS.IsDeleted = 1
FROM ProjectReferenceStandard PRS WITH (NOLOCK)
LEFT JOIN ProjectSegmentReferenceStandard PSRS WITH (NOLOCK)
	ON PSRS.SectionId = PRS.SectionId
	AND PSRS.RefStdCode = PRS.RefStdCode
	AND ISNULL(PSRS.IsDeleted,0)=0
WHERE PRS.SectionId = @SectionId
AND PRS.ProjectId = @ProjectId
AND PRS.CustomerId = @CustomerId
AND PSRS.RefStdCode IS NULL

UPDATE PS
SET PS.IsDeleted = 1
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.ProjectId = @ProjectId AND PS.SectionId = @SectionId AND PS.SegmentStatusId = @PSegmentStatusId
	AND PS.SegmentSource = @Source

--For Delete Segment Status    
UPDATE PSS
SET PSS.SegmentOrigin = 'M'
   ,PSS.SegmentId = NULL
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.SegmentStatusId = @PSegmentStatusId

DROP TABLE IF EXISTS #ProjectSegmentTemp
select SegmentChoiceId,SegmentChoiceCode,SectionId, ProjectId, CustomerId INTO #ProjectSegmentTemp
FROM ProjectSegmentChoice PSC WITH (NOLOCK)
WHERE PSC.ProjectId = @ProjectId AND PSC.CustomerId = @CustomerId AND PSC.SectionId = @SectionId AND SegmentStatusId = @PSegmentStatusId
AND SegmentChoiceSource = @Source

UPDATE PSC
SET PSC.IsDeleted = 1
FROM #ProjectSegmentTemp T INNER JOIN ProjectSegmentChoice PSC WITH (NOLOCK)
ON PSC.SegmentChoiceId=T.SegmentChoiceId
AND PSC.SectionId=T.SectionId
WHERE PSC.ProjectId = @ProjectId AND PSC.CustomerId = @CustomerId AND PSC.SectionId=@SectionId
AND PSC.SegmentStatusId = @PSegmentStatusId
AND SegmentChoiceSource = @Source

DROP TABLE IF EXISTS #ProjectChoiceOptionTemp
Select PCO.ChoiceOptionId,PCO.ChoiceOptionCode,T.SegmentChoiceCode,T.SectionId, T.ProjectId, T.CustomerId 
INTO #ProjectChoiceOptionTemp from ProjectChoiceOption PCO WITH (NOLOCK)
INNER JOIN #ProjectSegmentTemp T
ON PCO.SectionId=T.SectionId
AND PCO.SegmentChoiceId=T.SegmentChoiceId
WHERE PCO.ProjectId = @ProjectId AND PCO.SectionId=@SectionId AND PCO.CustomerId = @CustomerId and ChoiceOptionSource='U'

UPDATE PCO
SET PCO.IsDeleted = 1
FROM #ProjectChoiceOptionTemp T INNER JOIN ProjectChoiceOption AS PCO WITH (NOLOCK)
	ON PCO.ChoiceOptionId = T.ChoiceOptionId
	AND PCO.SectionId=T.SectionId
WHERE PCO.ProjectId = @ProjectId AND PCO.SectionId=@SectionId AND PCO.CustomerId = @CustomerId
AND PCO.ChoiceOptionSource = 'U'

UPDATE SCP
SET SCP.IsDeleted = 1
FROM #ProjectChoiceOptionTemp T INNER JOIN SelectedChoiceOption AS SCP WITH (NOLOCK)
	ON SCP.ProjectId = T.ProjectId AND SCP.CustomerId = T.CustomerId AND SCP.SectionId=T.SectionId
	AND SCP.SegmentChoiceCode=T.SegmentChoiceCode
	AND SCP.ChoiceOptionCode = T.ChoiceOptionCode
WHERE SCP.ProjectId = @ProjectId AND SCP.CustomerId = @CustomerId AND SCP.SectionId = @SectionId
AND SCP.ChoiceOptionSource = 'U'

END TRY  
 BEGIN CATCH  
   insert into BsdLogging..AutoSaveLogging  
    values('usp_deleteUserModifications',  
    getdate(),  
    ERROR_MESSAGE(),  
    ERROR_NUMBER(),  
    ERROR_Severity(),  
    ERROR_LINE(),  
    ERROR_STATE(),  
    ERROR_PROCEDURE(),  
    concat('exec usp_deleteUserModifications ',@SegmentStatusId),  
    @SegmentStatusId  
   )  

   DECLARE @AutoSaveLoggingId INT =  (SELECT @@IDENTITY AS [@@IDENTITY]);
   THROW 50010, @AutoSaveLoggingId, 1;
 END CATCH
END
GO


