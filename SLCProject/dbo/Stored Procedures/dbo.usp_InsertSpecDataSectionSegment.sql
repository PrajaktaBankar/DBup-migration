CREATE PROCEDURE [dbo].[usp_InsertSpecDataSectionSegment]   
@InpSegmentJson NVARCHAR(MAX)              
AS              
            
BEGIN  
  
DECLARE @PInpSegmentJson NVARCHAR(MAX) = @InpSegmentJson;  
SET NOCOUNT ON;  
              
DECLARE @ProjectId INT,@mSectionId int =0,@MaxSequenceNumber decimal(18,4),@MaxSegmentStatusId bigint=0;  
DECLARE @SectionId INT;  
DECLARE @CustomerId INT;  
DECLARE @UserId INT;  
DECLARE @IsAutoSelectParagraph BIT = 0;  
DECLARE @MultipleProductConditionalRuleId   INT=0;  
              
 --DECLARE INP SEGMENT TABLE               
 CREATE TABLE #InpSegmentTableVar (                
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
  TempSegmentStatusId BIGINT NULL,              
  SegmentStatusId BIGINT NULL  ,        
  SegmentDescription nvarchar(max),      
  mSectionId INT,    
  MaxSegmentStatusId BIGINT ,   
  RowId INT NULL,        
  SequenceNumber DECIMAL(18,4) DEFAULT 2   
 );  
    
 --DECLARE INP SEGMENT TABLE               
 CREATE TABLE #InpSegmentTableSection (                
  SectionId INT,                
  ProjectId INT,              
  CustomerId INT DEFAULT 0      
 );  
              
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE               
IF @PInpSegmentJson != ''              
BEGIN  
  
INSERT INTO #InpSegmentTableVar  
 SELECT  
  *  
    ,ROW_NUMBER() OVER (PARTITION BY SectionId ORDER BY SectionId) AS RowId  
    ,0.0  
 FROM OPENJSON(@PInpSegmentJson)  
 WITH (  
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
 TempSegmentStatusId BIGINT '$.TempSegmentStatusId',  
 SegmentStatusId BIGINT '$.SegmentStatusId',  
 SegmentDescription NVARCHAR(MAX) '$.SegmentDescription',  
 mSectionId INT '$.mSectionId',  
 MaxSegmentStatusId BIGINT '$.MaxSegmentStatusId'  
 );  
  
SELECT DISTINCT  
 ps.mSectionId  
   ,ps.ProjectId  
   ,Ps.CustomerId  
   ,ps.SectionId INTO #SectionTBL  
FROM #InpSegmentTableVar tmp  
INNER JOIN ProjectSection ps WITH (NOLOCK)  
 ON ps.mSectionId = tmp.mSectionId  
  AND tmp.ProjectId = ps.ProjectId  
  AND tmp.CustomerId = ps.CustomerId  
  
SELECT DISTINCT  
 SectionId  
   ,MaxSegmentStatusId  
   ,CustomerId INTO #RMultipleConditionalRuleTable  
FROM #InpSegmentTableVar  
  
SELECT DISTINCT  
 SectionId  
   ,MaxSegmentStatusId  
   ,CustomerId  
   ,ROW_NUMBER() OVER (ORDER BY MaxSegmentStatusId) AS RowNo INTO #MultipleConditionalRuleTable  
FROM #RMultipleConditionalRuleTable  
  
  
  
DECLARE @n INT = (SELECT  
    COUNT(MaxSegmentStatusId)  
   FROM #MultipleConditionalRuleTable)  
    ,@n1 INT = 1;  
WHILE (@n1 <= @n)  
BEGIN  
  
SELECT  
 @CustomerId = CustomerId  
   ,@MaxSegmentStatusId = MaxSegmentStatusId  
FROM #MultipleConditionalRuleTable  
WHERE RowNo = @n1  
  
  
DROP TABLE IF EXISTS #InsertSegmentDataTable  
  
SELECT  
 ps.SectionId  
   ,IST.ParentSegmentStatusId  
   ,IST.IndentLevel  
   ,IST.SegmentStatusTypeId  
   ,IST.IsParentSegmentStatusActive  
   ,IST.SpecTypeTagId  
   ,IST.ProjectId  
   ,IST.CustomerId  
   ,IST.CreatedBy  
   ,IST.IsRefStdParagraph  
   ,IST.TempSegmentStatusId  
   ,IST.SegmentStatusId  
   ,IST.SegmentDescription  
   ,IST.mSectionId  
   ,pss.SequenceNumber AS MaxSequenceNumber  
   ,IST.MaxSegmentStatusId  
   ,IST.RowId  
   ,CAST(pss.SequenceNumber AS DECIMAL(18, 4)) + ROW_NUMBER()  
 OVER (PARTITION BY IST.SectionId, CAST(pss.SequenceNumber AS DECIMAL(18, 4)) ORDER BY IST.RowId) AS SequenceNumber INTO #InsertSegmentDataTable  
  
FROM #InpSegmentTableVar IST  
INNER JOIN #SectionTBL ps WITH (NOLOCK)  
 ON ps.mSectionId = IST.mSectionId  
  AND IST.ProjectId = ps.ProjectId  
  AND IST.CustomerId = ps.CustomerId  
INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)  
 ON pss.SectionId = ps.SectionId  
  AND pss.mSegmentStatusId = IST.MaxSegmentStatusId  
  AND pss.ProjectId = IST.ProjectId  
  AND pss.CustomerId = IST.CustomerId  
WHERE IST.MaxSegmentStatusId = @MaxSegmentStatusId  
  ORDER BY	 CAST(IST.RowId AS INT)
  
--INSERT DATA IN SegmentStatus              
--NOTE -- HERE Saving TempSegmentStatusId in ParentSegmentStatusId for join purpose              
INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId,  
SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId,  
SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, CustomerId,  
IsShowAutoNumber, CreateDate, CreatedBy, IsRefStdParagraph, mSegmentStatusId, mSegmentId, A_SegmentStatusId)  
 SELECT  
  INPTBL.SectionId AS SectionId  
    ,INPTBL.TempSegmentStatusId AS ParentSegmentStatusId  
    ,NULL AS SegmentId  
    ,'U' AS SegmentSource  
    ,'U' AS SegmentOrigin  
    ,INPTBL.IndentLevel  
    ,INPTBL.SequenceNumber  
    ,2 AS SpecTypeTagId  
    ,IIF(IsParentSegmentStatusActive = 1, 2, 6) AS SegmentStatusTypeId  
    ,IsParentSegmentStatusActive  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,1 AS IsShowAutoNumber  
    ,GETUTCDATE() AS CreateDate  
    ,INPTBL.CreatedBy  
    ,INPTBL.IsRefStdParagraph  
    ,0 AS mSegmentStatusId  
    ,0 AS mSegmentId  
    ,INPTBL.MaxSegmentStatusId AS A_SegmentStatusId  
 FROM #InsertSegmentDataTable INPTBL  
 ORDER BY INPTBL.SectionId, CAST(INPTBL.SequenceNumber AS INT) ASC  
  
SELECT TOP 1  
 @SectionId = SectionId  
   ,@ProjectId = ProjectId  
   ,@CustomerId = CustomerId  
   ,@mSectionId = mSectionId  
   ,@MaxSequenceNumber = MaxSequenceNumber  
   ,@MaxSegmentStatusId = MaxSegmentStatusId  
FROM #InsertSegmentDataTable  
  
  
DROP TABLE IF EXISTS #TempProjectsegentStatus  
  
SELECT DISTINCT  
 pss.SectionId  
   ,pss.SegmentId  
   ,pss.SegmentstatusId  
   ,pss.SegmentSource  
   ,pss.SegmentOrigin  
   ,pss.IndentLevel  
   ,pss.SequenceNumber  
   ,pss.ProjectId  
   ,pss.CustomerId  
   ,pss.mSegmentStatusId  
   ,pss.mSegmentId  
   ,pss.ParentSegmentStatusId  
   ,pss.IsDeleted INTO #TempProjectsegentStatus  
FROM ProjectsegmentStatus pss WITH (NOLOCK)  
WHERE pss.SectionId = @SectionId  
AND pss.ProjectId = @ProjectId  
AND pss.CustomerId = @CustomerId  
AND ISNULL(pss.IsDeleted, 0) = 0  
ORDER BY pss.SequenceNumber  
  
  
--UPDATE Corrected SegmentStatusId IN INP TBL              
UPDATE INPTBL  
SET INPTBL.SegmentStatusId = PSST.SegmentStatusId  
FROM #InsertSegmentDataTable INPTBL  
INNER JOIN #TempProjectsegentStatus PSST WITH (NOLOCK)  
 ON PSST.SectionId = INPTBL.SectionId  
 AND PSST.ProjectId = INPTBL.ProjectId  
 AND PSST.CustomerId = INPTBL.CustomerId  
WHERE PSST.SectionId = INPTBL.SectionId  
AND PSST.ParentSegmentStatusId = INPTBL.TempSegmentStatusId  
AND PSST.ProjectId = INPTBL.ProjectId  
AND PSST.CustomerId = INPTBL.CustomerId  
AND INPTBL.MaxSegmentStatusId = @MaxSegmentStatusId  
----NOW UPDATE PARENT SEGMENT STATUS ID TO -1 WHICH WILL GET UPDATED LATER FROM API              
UPDATE PSST  
SET PSST.ParentSegmentStatusId = -1  
FROM #InsertSegmentDataTable INPTBL  
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
 ON INPTBL.TempSegmentStatusId = PSST.ParentSegmentStatusId  
 AND PSST.SectionId = INPTBL.SectionId  
 AND PSST.ProjectId = INPTBL.ProjectId  
 AND PSST.CustomerId = INPTBL.CustomerId  
WHERE PSST.SectionId = INPTBL.SectionId  
AND PSST.ParentSegmentStatusId = INPTBL.TempSegmentStatusId  
AND PSST.ProjectId = INPTBL.ProjectId  
AND PSST.CustomerId = INPTBL.CustomerId  
AND INPTBL.MaxSegmentStatusId = @MaxSegmentStatusId  
  
----INSERT INTO PROJECT SEGMENT              
INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription,  
SegmentSource, CreatedBy, CreateDate)  
 SELECT  
  INPTBL.SegmentStatusId  
    ,INPTBL.SectionId AS SectionId  
    ,INPTBL.ProjectId  
    ,INPTBL.CustomerId  
    ,segmentDescription AS SegmentDescription  
    ,'U' AS SegmentSource  
    ,INPTBL.CreatedBy  
    ,GETUTCDATE() AS CreateDate  
 FROM #InsertSegmentDataTable INPTBL  
  
----UPDATE SEGMENT ID IN SEGMENT STATUS              
UPDATE PSST  
SET PSST.SegmentId = PSG.SegmentId  
FROM #InsertSegmentDataTable INPTBL  
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
 ON PSST.SegmentStatusId = INPTBL.SegmentStatusId  
 AND PSST.SectionId = INPTBL.SectionId  
 AND PSST.ProjectId = INPTBL.ProjectId  
 AND PSST.CustomerId = INPTBL.CustomerId  
INNER JOIN ProjectSegment PSG WITH (NOLOCK)  
 ON PSST.SegmentStatusId = PSG.SegmentStatusId  
 AND PSST.SectionId = PSG.SectionId  
 AND PSST.ProjectId = PSG.ProjectId  
 AND PSST.CustomerId = PSG.CustomerId  
WHERE PSST.SectionId = INPTBL.SectionId  
AND PSST.ProjectId = INPTBL.ProjectId  
AND PSST.CustomerId = INPTBL.CustomerId  
AND INPTBL.MaxSegmentStatusId = @MaxSegmentStatusId  
  
DECLARE @SequenceCount INT = 0;  
  
SET @SequenceCount = ((@MaxSequenceNumber + (SELECT  
  COUNT(MaxSegmentStatusId)  
 FROM #InsertSegmentDataTable)  
))  
  
print @SequenceCount  
  
DROP TABLE IF EXISTS #tempSequenceNumber  
  
SELECT  
 PSST.ProjectId  
   ,PSST.SectionId  
   ,PSST.CustomerId  
   ,PSST.SegmentId  
   ,PSST.SegmentStatusId  
   ,CAST(CONCAT((@SequenceCount + ROW_NUMBER() OVER (ORDER BY PSST.SequenceNumber)), '.0000') AS DECIMAL(18, 4)) AS newSequenceNumber INTO #tempSequenceNumber  
  
FROM #TempProjectsegentStatus PSST WITH (NOLOCK)  
WHERE PSST.SectionId = @SectionId  
AND PSST.ProjectId = @ProjectId  
AND PSST.CustomerId = @CustomerId  
AND PSST.SequenceNumber >= CAST(@MaxSequenceNumber + 1 AS DECIMAL(18, 4))  
AND PSST.SegmentSource = 'M'  
AND ISNULL(PSST.IsDeleted, 0) = 0  
ORDER BY PSST.SequenceNumber  
  
  
UPDATE PSST  
SET PSST.SequenceNumber = tp.newSequenceNumber  
FROM #tempSequenceNumber tp  
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
 ON PSST.SegmentStatusId = tp.SegmentStatusId  
 AND PSST.SectionId = tp.SectionId  
 AND PSST.ProjectId = tp.ProjectId  
 AND PSST.CustomerId = tp.CustomerId  
 AND PSST.SegmentSource = 'M'  
  
  
UPDATE PSST  
SET PSST.SegmentStatusId = INPTBL.SegmentStatusId,  
PSST.SectionId=INPTBL.SectionId  
FROM #InsertSegmentDataTable INPTBL  
INNER JOIN #InpSegmentTableVar PSST WITH (NOLOCK)  
 ON INPTBL.TempSegmentStatusId = PSST.TempSegmentStatusId  
 AND PSST.ProjectId = INPTBL.ProjectId  
 AND PSST.CustomerId = INPTBL.CustomerId  
WHERE   PSST.TempSegmentStatusId = INPTBL.TempSegmentStatusId  
AND PSST.ProjectId = INPTBL.ProjectId  
AND PSST.CustomerId = INPTBL.CustomerId   
  
SET @n1 = @n1 + 1;  
  
END  
   
  
------SELECT RESULT GRID              
SELECT  
 INPTBL.SegmentStatusId  
   ,INPTBL.TempSegmentStatusId  
   ,PSST.SegmentId  
   ,INPTBL.SectionId AS sectionId  
FROM #InpSegmentTableVar INPTBL  
INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)  
 ON PSST.SegmentStatusId = INPTBL.SegmentStatusId  
  AND PSST.SectionId = INPTBL.SectionId  
  AND PSST.ProjectId = INPTBL.ProjectId  
  AND PSST.CustomerId = INPTBL.CustomerId  
  
  
SELECT DISTINCT  
 ProjectId  
   ,SectionId  
   ,CustomerId  
   ,mSectionId INTO #DistinctProjectSection  
FROM #InpSegmentTableVar  
  
SELECT  
 ProjectId  
   ,SectionId  
   ,CustomerId  
   ,mSectionId  
   ,ROW_NUMBER() OVER (ORDER BY SectionId) AS RowId INTO #TemDistinctProjectSection  
FROM #DistinctProjectSection  
  
SET @n1 = 0;  
  
SELECT  
 @n1 = COUNT(SectionId)  
FROM #TemDistinctProjectSection  
  
  
UPDATE ss  
SET ss.IsDeleted = 1  
FROM ProjectSegmentStatus ss WITH (NOLOCK)  
INNER JOIN #SectionTBL INPTBL  
 ON  INPTBL.SectionId = ss.SectionId  
 AND ss.ProjectId = INPTBL.ProjectId  
 AND ss.CustomerId = INPTBL.CustomerId  
WHERE INPTBL.SectionId = ss.SectionId  
AND ss.mSegmentStatusId IN (  
612416,  
625566,  
625567,  
625568,  
625569,  
625570,  
625571,  
612422,  
612423,  
612424,  
612425,  
612426,  
612405,  
625572,  
625573,  
625574,  
625575,  
625576,  
625577,  
612411,  
612412,  
612413,  
612414,  
612415)  
AND ss.ProjectId = INPTBL.ProjectId  
AND ss.CustomerId = INPTBL.CustomerId  
  
SET @n = 1;  
  
WHILE (@n <= @n1)      
BEGIN  
  
SELECT  
 @SectionId = SectionId  
   ,@ProjectId = ProjectId  
   ,@CustomerId = CustomerId  
FROM #TemDistinctProjectSection  
WHERE RowId = @n  
  
DROP TABLE IF EXISTS #UpDateSegmentStatusIdAndSegmentId  
  
SELECT  
 B.SegmentStatusId AS ParentSegmentStatusId  
   ,A.SegmentStatusId  
   ,ps.SegmentId  
   ,A.SectionId  
   ,A.ProjectId INTO #UpDateSegmentStatusIdAndSegmentId  
FROM ProjectSegmentStatus A WITH (NOLOCK)  
CROSS APPLY (SELECT  
  MAX(SegmentStatusId)  
 FROM ProjectSegmentStatus B WITH (NOLOCK)  
 WHERE A.SectionId = B.SectionId  
 AND A.ProjectId = B.ProjectId  
 AND B.IndentLevel < A.IndentLevel  
 AND CAST(A.SequenceNumber AS INT) > CAST(B.SequenceNumber AS INT)  
 AND A.SegmentStatusId > B.SegmentStatusId  
 AND ISNULL(B.IsDeleted, 0) = 0) B (SegmentStatusId)  
INNER JOIN ProjectSegment ps WITH (NOLOCK)  
 ON ps.SegmentStatusId = A.SegmentStatusId  
  AND ps.SectionId = A.SectionId  
  AND ps.ProjectId = A.ProjectId  
WHERE A.SectionId = @SectionId  
AND A.ProjectId = @ProjectId  
AND A.CustomerId = @CustomerId  
AND ISNULL(A.IsDeleted, 0) = 0  
AND A.SegmentSource = 'U'  
ORDER BY SequenceNumber  
  
UPDATE pss  
SET pss.ParentSegmentStatusId = uss.ParentSegmentStatusId  
   ,pss.SegmentId = uss.SegmentId  
FROM ProjectSegmentStatus pss WITH (NOLOCK)  
INNER JOIN #UpDateSegmentStatusIdAndSegmentId uss  
 ON uss.SegmentStatusId = pss.SegmentStatusId  
 AND pss.SectionId = uss.SectionId  
 AND pss.ProjectId = uss.ProjectId  
 AND ISNULL(pss.IsDeleted, 0) = 0  
WHERE pss.SectionId = @SectionId  
AND pss.ProjectId = @ProjectId  
AND pss.CustomerId = @CustomerId  
AND pss.SegmentSource = 'U'  
SET @n = @n + 1;  
  
END  
END  
  
END  
  
GO


