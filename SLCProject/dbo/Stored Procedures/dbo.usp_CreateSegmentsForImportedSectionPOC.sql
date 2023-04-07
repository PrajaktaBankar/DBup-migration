CREATE PROCEDURE [dbo].[usp_CreateSegmentsForImportedSectionPOC]    
@InpSegmentJson NVARCHAR(MAX) 
AS  
    
BEGIN  
--Set Nocount On  
SET NOCOUNT ON;  
  
DECLARE @ProjectId INT;  
DECLARE @SectionId INT;  
DECLARE @CustomerId INT;  
DECLARE @UserId INT;  
DECLARE @IsAutoSelectParagraph BIT = 0;  
  
 --DECLARE INP SEGMENT TABLE   
 CREATE TABLE #InpSegmentTableVar (    
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
 SegmentStatusId BIGINT NULL,  
 SegmentStatusCode BIGINT NULL,  
 SegmentCode BIGINT NULL ,
 Comment VARCHAR(max) NULL,
 Author varchar(max) NULL,
 ReferenceText VARCHAR(MAX) NULL
 );  
  


 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE   
IF @InpSegmentJson != ''  
BEGIN  
INSERT INTO #InpSegmentTableVar  
  SELECT   JSON_VALUE(c.value, '$.rowId') as RowId,
  JSON_VALUE(c.value, '$.sectionId') as SectionId, 
  JSON_VALUE(c.value, '$.parentSegmentStatusId') as  ParentSegmentStatusId, 
  JSON_VALUE(c.value, '$.indentLevel') as  IndentLevel,
  JSON_VALUE(c.value, '$.segmentStatusTypeId') as  SegmentStatusTypeId,
  JSON_VALUE(c.value, '$.isParentSegmentStatusActive') as   IsParentSegmentStatusActive,
   JSON_VALUE(c.value, '$.specTypeTagId') as    SpecTypeTagId,
  JSON_VALUE(c.value, '$.projectId') as  ProjectId, 
  JSON_VALUE(c.value, '$.customerId') as  CustomerId, 
  JSON_VALUE(c.value, '$.createdBy') as  CreatedBy,
  JSON_VALUE(c.value, '$.isRefStdParagraph') as  IsRefStdParagraph,
  JSON_VALUE(c.value, '$.sequenceNumber') as    SequenceNumber,
  JSON_VALUE(c.value, '$.tempSegmentStatusId') as    TempSegmentStatusId,
  JSON_VALUE(c.value, '$.segmentStatusId') as     SegmentStatusId,
    JSON_VALUE(c.value, '$.SegmentStatusCode') as     SegmentStatusCode,
    JSON_VALUE(c.value, '$.SegmentCode') as     SegmentCode,
	JSON_VALUE(p.value, '$.Comments') as     Comment,
 JSON_VALUE(p.value, '$.Author') as     Author,
 JSON_VALUE(p.value, '$.ReferenceText') as    ReferenceText
  FROM  
 OPENJSON ( @InpSegmentJson,'$.ImportSegment') as c
 CROSS APPLY OPENJSON (c.value,'$.Comment') 
 as p;  
 
 INSERT INTO #InpSegmentTableVar  
  SELECT   JSON_VALUE(c.value, '$.rowId') as RowId,
  JSON_VALUE(c.value, '$.sectionId') as SectionId, 
  JSON_VALUE(c.value, '$.parentSegmentStatusId') as  ParentSegmentStatusId, 
  JSON_VALUE(c.value, '$.indentLevel') as  IndentLevel,
  JSON_VALUE(c.value, '$.segmentStatusTypeId') as  SegmentStatusTypeId,
  JSON_VALUE(c.value, '$.isParentSegmentStatusActive') as   IsParentSegmentStatusActive,
   JSON_VALUE(c.value, '$.specTypeTagId') as    SpecTypeTagId,
  JSON_VALUE(c.value, '$.projectId') as  ProjectId, 
  JSON_VALUE(c.value, '$.customerId') as  CustomerId, 
  JSON_VALUE(c.value, '$.createdBy') as  CreatedBy,
  JSON_VALUE(c.value, '$.isRefStdParagraph') as  IsRefStdParagraph,
  JSON_VALUE(c.value, '$.sequenceNumber') as    SequenceNumber,
  JSON_VALUE(c.value, '$.tempSegmentStatusId') as    TempSegmentStatusId,
  JSON_VALUE(c.value, '$.segmentStatusId') as     SegmentStatusId,
    JSON_VALUE(c.value, '$.SegmentStatusCode') as     SegmentStatusCode,
    JSON_VALUE(c.value, '$.SegmentCode') as     SegmentCode,
	null,--JSON_VALUE(p.value, '$.Comments') as     Comment,
	null,
	null
-- JSON_VALUE(p.value, '$.Author') as     Author,
-- JSON_VALUE(p.value, '$.ReferenceText') as    ReferenceText
  FROM  
 OPENJSON ( @InpSegmentJson,'$.ImportSegment') as c
-- CROSS APPLY OPENJSON (c.value,'$.Comment') 
-- as p
 --WHERE p.value is null;
END  
  


 --SELECT * FROM #InpSegmentTableVar ;

SELECT TOP 1  
 @ProjectId = ProjectId  
   ,@SectionId = SectionId  
   ,@CustomerId = CustomerId  
   ,@UserId = CreatedBy  
FROM #InpSegmentTableVar  
  
--SET PROPER DIVISION ID FOR IMPORTED SECTION
EXEC usp_SetDivisionIdForUserSection @ProjectId, @SectionId, @CustomerId

--CHECK SETTING OF AUTOSELECT PARAGRAPH  
IF EXISTS (SELECT  
   TOP 1 1  FROM CustomerGlobalSetting  WITH(NOLOCK)
  WHERE CustomerId = @CustomerId  
  AND UserId = @UserId)  
BEGIN  
SET @IsAutoSelectParagraph = (SELECT TOP 1  
  --IsAutoSelectParagraph  
  IsAutoSelectForImport
 FROM CustomerGlobalSetting   WITH(NOLOCK)
 WHERE CustomerId = @CustomerId  
 AND UserId = @UserId  
 ORDER BY CustomerGlobalSettingId DESC)  
END  
ELSE IF EXISTS (SELECT  
  TOP 1 1
 FROM CustomerGlobalSetting   WITH(NOLOCK)
 WHERE CustomerId IS NULL  
 AND UserId IS NULL)  
BEGIN  
SET @IsAutoSelectParagraph = (SELECT TOP 1  
  --IsAutoSelectParagraph  
  IsAutoSelectForImport
 FROM CustomerGlobalSetting   WITH(NOLOCK)
 WHERE CustomerId IS NULL  
 AND UserId IS NULL  
 ORDER BY CustomerGlobalSettingId DESC)  
END  
  
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
IsShowAutoNumber, CreateDate, CreatedBy, IsRefStdParagraph, SegmentStatusCode,  
mSegmentStatusId, mSegmentId)  
 SELECT  
     INPTBL.SectionId  
    ,INPTBL.TempSegmentStatusId AS ParentSegmentStatusId  
    ,NULL AS SegmentId  
    ,'U' AS SegmentSource  
    ,'U' AS SegmentOrigin  
    ,INPTBL.IndentLevel  
    ,INPTBL.SequenceNumber  
    ,NULL AS SpecTypeTagId  
    ,INPTBL.SegmentStatusTypeId  
    ,INPTBL.IsParentSegmentStatusActive  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,1 AS IsShowAutoNumber  
    ,GETUTCDATE() AS CreateDate  
    ,INPTBL.CreatedBy  
    ,INPTBL.IsRefStdParagraph  
    ,INPTBL.SegmentStatusCode  
    ,0 AS mSegmentStatusId  
    ,0 AS mSegmentId -- ,
	--INPTBL.RowId
 FROM #InpSegmentTableVar INPTBL  
 ORDER BY INPTBL.RowId
   ASC  
  
----UPDATE Corrected SegmentStatusId IN INP TBL  
UPDATE INPTBL  
SET INPTBL.SegmentStatusId = PSST.SegmentStatusId  
FROM #InpSegmentTableVar INPTBL  
INNER JOIN ProjectSegmentStatus PSST   WITH(NOLOCK)
 ON INPTBL.ProjectId = @ProjectId  
 AND INPTBL.CustomerId = @CustomerId  
 AND INPTBL.SectionId = @SectionId  
 AND INPTBL.TempSegmentStatusId = PSST.ParentSegmentStatusId  
 AND PSST.SectionId=@SectionId  AND psst.ProjectId=@ProjectId  AND
 PSST.CustomerId=@CustomerId  
  
----NOW UPDATE PARENT SEGMENT STATUS ID TO -1 WHICH WILL GET UPDATED LATER FROM API  
UPDATE PSST  
SET PSST.ParentSegmentStatusId = -1  
FROM ProjectSegmentStatus PSST   WITH(NOLOCK)
WHERE PSST.ProjectId = @ProjectId  
AND PSST.SectionId = @SectionId  
AND PSST.CustomerId = @CustomerId  
  

INSERT INTO [Comments]
           ([SectionId]
           ,[CommentText]
           ,[Author]
           ,[ReferenceText])
	SELECT INPTBL.SectionId,
	 INPTBL.Comment,
	 INPTBL.Author,
	 INPTBL.ReferenceText
	FROM #InpSegmentTableVar INPTBL
	WHERE INPTBL.Comment IS NOT NULL
----INSERT INTO PROJECT SEGMENT  
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,  
SegmentSource, CreatedBy, CreateDate, SegmentCode)  
 SELECT  
     INPTBL.SegmentStatusId  
    ,INPTBL.SectionId  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,'' AS SegmentDescription  
    ,'U' AS SegmentSource  
    ,INPTBL.CreatedBy  
    ,GETUTCDATE() AS CreateDate  
    ,INPTBL.SegmentCode  
 FROM #InpSegmentTableVar INPTBL  
  
----UPDATE SEGMENT ID IN SEGMENT STATUS  
UPDATE PSST  
SET PSST.SegmentId = PSG.SegmentId  
FROM ProjectSegmentStatus PSST   WITH(NOLOCK)
INNER JOIN ProjectSegment PSG   WITH(NOLOCK)
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
INNER JOIN ProjectSegmentStatus PSST  WITH(NOLOCK)
 ON PSST.ProjectId = @ProjectId  
  AND PSST.CustomerId = @CustomerId  
  AND PSST.SectionId = @SectionId  
  AND PSST.SegmentStatusId = INPTBL.SegmentStatusId  
END
GO


