CREATE PROCEDURE [dbo].[usp_CreateSegmentsForImportedSectionForImportProject]  
@IsAutoSelectParagraph BIT ,  
@InpSegmentJson NVARCHAR(MAX)  
AS    
      
BEGIN  
    
DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;  
--Set Nocount On    
SET NOCOUNT ON;  
    
DECLARE @ProjectId INT;  
    
DECLARE @SectionId INT;  
    
DECLARE @CustomerId INT;  
    
DECLARE @UserId INT;  
    
    
 --DECLARE INP SEGMENT TABLE     
 CREATE TABLE #InpSegmentTableVar(      
 RowId INT NULL ,      
 SectionId INT,      
 ParentSegmentStatusId BIGINT,    
 IndentLevel TINYINT,    
 SegmentStatusTypeId INT DEFAULT 2,    
 IsParentSegmentStatusActive BIT,    
 SpecTypeTagId INT NULL,    
 ProjectId INT,    
 CustomerId INT DEFAULT 0,    
 CreatedBy INT DEFAULT 0,    
 IsRefStdParagraph BIT DEFAULT 0,    
 SequenceNumber DECIMAL(18,4) DEFAULT 2,    
 TempSegmentStatusId BIGINT NULL,    
 SegmentStatusId BIGINT NULL 
 );  
    
    
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE     
IF @PInpSegmentJson != ''    
BEGIN  
INSERT INTO #InpSegmentTableVar  
 SELECT  
  *  
 FROM OPENJSON(@PInpSegmentJson)  
 WITH (  
 RowId INT '$.RowId',  
 SectionId INT '$.SectionId',  
 ParentSegmentStatusId BIGINT '$.ParentSegmentStatusId',  
 IndentLevel TINYINT '$.IndentLevel',  
 SegmentStatusTypeId INT '$.SegmentStatusTypeId',  
 IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive',  
 SpecTypeTagId INT '$.SpecTypeTagId',  
 ProjectId INT '$.ProjectId',  
 CustomerId NVARCHAR(MAX) '$.CustomerId',  
 CreatedBy INT '$.CreatedBy',  
 IsRefStdParagraph BIT '$.IsRefStdParagraph',  
 SequenceNumber DECIMAL(18, 4) '$.SequenceNumber',  
 TempSegmentStatusId BIT '$.TempSegmentStatusId',  
 SegmentStatusId BIGINT '$.SegmentStatusId' 
 );  
END  
  
SELECT TOP 1  
 @ProjectId = ProjectId  
   ,@SectionId = SectionId  
   ,@CustomerId = CustomerId  
   ,@UserId = CreatedBy  
FROM #InpSegmentTableVar  
  
--SET PROPER DIVISION ID FOR IMPORTED SECTION  
EXEC usp_SetDivisionIdForUserSection @ProjectId  
         ,@SectionId  
         ,@CustomerId  
  
   
--UPDATE SOME VALUES IN TABLE TO DEFAULT    
UPDATE INPTBL  
SET INPTBL.SegmentStatusTypeId = (CASE  
  WHEN @IsAutoSelectParagraph = 1 THEN 2  
  ELSE 6  
 END)  
   ,INPTBL.TempSegmentStatusId = INPTBL.SegmentStatusId  
   ,INPTBL.IsParentSegmentStatusActive = (  
 CASE  
  WHEN @IsAutoSelectParagraph = 1 THEN 1  
  WHEN INPTBL.SequenceNumber = 0 THEN 1  
  ELSE 0  
 END)  
FROM #InpSegmentTableVar INPTBL  
  
----INSERT DATA IN SegmentStatus    
----NOTE -- HERE Saving TempSegmentStatusId in ParentSegmentStatusId for join purpose    
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId,  
SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId,  
SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,  
IsShowAutoNumber, CreateDate, CreatedBy, IsRefStdParagraph,  
mSegmentStatusId, mSegmentId)  
 SELECT  
  INPTBL.SectionId  
    ,INPTBL.TempSegmentStatusId AS ParentSegmentStatusId  
    ,NULL AS SegmentId  
    ,'U' AS SegmentSource  
    ,'U' AS SegmentOrigin  
    ,INPTBL.IndentLevel  
    ,INPTBL.SequenceNumber  
    ,CASE  
   WHEN INPTBL.SpecTypeTagId = 0 THEN NULL  
   ELSE INPTBL.SpecTypeTagId  
  END AS SpecTypeTagId  
    ,INPTBL.SegmentStatusTypeId  
    ,INPTBL.IsParentSegmentStatusActive  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,1 AS IsShowAutoNumber  
    ,GETUTCDATE() AS CreateDate  
    ,INPTBL.CreatedBy  
    ,INPTBL.IsRefStdParagraph 
    ,0 AS mSegmentStatusId  
    ,0 AS mSegmentId  
 FROM #InpSegmentTableVar INPTBL  
 ORDER BY INPTBL.RowId ASC  
  
----UPDATE Corrected SegmentStatusId IN INP TBL    
UPDATE INPTBL  
SET INPTBL.SegmentStatusId = PSST.SegmentStatusId  
FROM #InpSegmentTableVar INPTBL  
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
 ON INPTBL.ProjectId = @ProjectId  
 AND INPTBL.CustomerId = @CustomerId  
 AND INPTBL.SectionId = @SectionId  
 AND INPTBL.TempSegmentStatusId = PSST.ParentSegmentStatusId  
 AND PSST.SectionId = @SectionId  
 AND psst.ProjectId = @ProjectId  
 AND PSST.CustomerId = @CustomerId  
  
----NOW UPDATE PARENT SEGMENT STATUS ID TO -1 WHICH WILL GET UPDATED LATER FROM API    
UPDATE PSST  
SET PSST.ParentSegmentStatusId = -1  
FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
WHERE PSST.ProjectId = @ProjectId  
AND PSST.SectionId = @SectionId  
AND PSST.CustomerId = @CustomerId  
  
----INSERT INTO PROJECT SEGMENT    
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,  
SegmentSource, CreatedBy, CreateDate)  
 SELECT  
  INPTBL.SegmentStatusId  
    ,INPTBL.SectionId  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,'' AS SegmentDescription  
    ,'U' AS SegmentSource  
    ,INPTBL.CreatedBy  
    ,GETUTCDATE() AS CreateDate 
 FROM #InpSegmentTableVar INPTBL  
  
----UPDATE SEGMENT ID IN SEGMENT STATUS    
UPDATE PSST  
SET PSST.SegmentId = PSG.SegmentId  
FROM ProjectSegmentStatus PSST WITH (NOLOCK)  
INNER JOIN ProjectSegment PSG WITH (NOLOCK)  
 ON PSST.SegmentStatusId = PSG.SegmentStatusId  
WHERE PSST.ProjectId = @ProjectId  
AND PSST.CustomerId = @CustomerId  
AND PSST.SectionId = @SectionId  
  
----SELECT RESULT GRID    
SELECT  
 INPTBL.SegmentStatusId  
   ,INPTBL.TempSegmentStatusId  
   ,PSST.SegmentId  
FROM #InpSegmentTableVar INPTBL  
INNER JOIN ProjectSegmentStatus PSST (NOLOCK)  
 ON PSST.ProjectId = @ProjectId  
  AND PSST.CustomerId = @CustomerId  
  AND PSST.SectionId = @SectionId  
  AND PSST.SegmentStatusId = INPTBL.SegmentStatusId  
END
GO


