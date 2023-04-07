CREATE PROCEDURE [dbo].[usp_GetUpdatesNeedsReview]  
@projectId INT NULL, @sectionId INT NULL, @customerId INT NULL, @userId INT NULL=0,@CatalogueType NVARCHAR (50) NULL='FS'                      
AS  
  BEGIN  
    
DECLARE @PprojectId INT = @projectId;  
DECLARE @PsectionId INT = @sectionId;  
DECLARE @PcustomerId INT = @customerId;  
DECLARE @PuserId INT = @userId;  
DECLARE @PCatalogueType NVARCHAR = @CatalogueType;  
  
   DECLARE @counter int=1, @max int=0,@SegmentStatusId bigint=0,@sequenceNos nvarchar(max)='',@Action NVARCHAR(50)='',  
   @ScenarioA bit,@ScenarioB bit,@ScenarioC bit  
   DECLARE @ProjectSegmentStatus TABLE   
   (  
   [SegmentStatusId] [bigint] NULL,  
   [SectionId] [int] NULL,  
   [ParentSegmentStatusId] [bigint] NULL,  
   [isParent] bit NULL ,  
   [mSegmentStatusId] [int] NULL,  
   [mSegmentId] [int] NULL,  
   [SegmentId] [bigint] NULL,  
   [SegmentSource] [char](1) NULL,  
   [SegmentOrigin] [char](2) NULL,  
   [IndentLevel] [tinyint] NULL,  
   [SequenceNumber] [decimal](18, 4) NULL,  
   [Remark] NVARCHAR(max) NULL,  
   [isDeleted] bit null,  
   [MessageDescription] NVARCHAR(max) NULL,  
   [ScenarioA] bit,  
   [ScenarioB] bit,  
   [ScenarioC] bit  
   )  
  
    ;  
WITH CTE  
AS  
(SELECT  
 pss.SegmentStatusId  
   ,pss.SectionId  
   ,pss.ParentSegmentStatusId  
   ,pss.mSegmentStatusId  
   ,pss.mSegmentId  
   ,pss.SegmentId  
   ,pss.SegmentSource  
   ,pss.SegmentOrigin  
   ,pss.IndentLevel  
   ,pss.SequenceNumber  
   ,pss.SpecTypeTagId  
   ,pss.SegmentStatusTypeId  
   ,pss.IsParentSegmentStatusActive  
   ,pss.ProjectId  
   ,pss.CustomerId  
   ,pss.SegmentStatusCode  
   ,pss.IsShowAutoNumber  
   ,pss.IsRefStdParagraph  
   ,pss.FormattingJson  
   ,pss.CreateDate  
   ,pss.CreatedBy  
   ,pss.ModifiedDate  
   ,pss.ModifiedBy  
   ,pss.IsPageBreak  
   ,pss.SLE_DocID  
   ,pss.SLE_ParentID  
   ,pss.SLE_SegmentID  
   ,pss.SLE_ProjectSegID  
   ,pss.SLE_StatusID  
   ,pss.A_SegmentStatusId  
   ,pss.IsDeleted  
   ,pss.TrackOriginOrder  
   ,pss.MTrackDescription  
 FROM ProjectSegmentStatus AS pss WITH (NOLOCK)  
 INNER JOIN [SLCMaster].[dbo].[SegmentStatus] AS mss  WITH (NOLOCK)  
  ON pss.mSegmentStatusId = mss.SegmentStatusId  
 WHERE pss.projectId = @PprojectId  
 AND pss.sectionId = @PsectionId  
 AND mss.isDeleted = 1  
 AND ISNULL(pss.IsDeleted, 0) = 0)  
SELECT  
 ROW_NUMBER() OVER (ORDER BY SegmentStatusId) AS ID  
   ,*  
   ,CONVERT(NVARCHAR(MAX), '') AS Remark INTO #temp  
FROM cte;  
  
--SELECT  
-- *  
--FROM #temp;  
SET @max = (SELECT  
  COUNT(*)  
 FROM #temp);  
  
  WHILE(@counter<=@max)  
  BEGIN  
SET @SegmentStatusId = (SELECT  
  SegmentStatusId  
 FROM #temp  
 WHERE ID = @counter);  
WITH CTE  
AS  
(SELECT   
    SegmentStatusId  
   ,SectionId  
   ,ParentSegmentStatusId  
   ,mSegmentStatusId  
   ,mSegmentId  
   ,SegmentId  
   ,SegmentSource  
   ,SegmentOrigin  
   ,IndentLevel  
   ,SequenceNumber  
   ,SpecTypeTagId  
   ,SegmentStatusTypeId  
   ,IsParentSegmentStatusActive  
   ,ProjectId  
   ,CustomerId  
   ,SegmentStatusCode  
   ,IsShowAutoNumber  
   ,IsRefStdParagraph  
   ,FormattingJson  
   ,CreateDate  
   ,CreatedBy  
   ,ModifiedDate  
   ,ModifiedBy  
   ,IsPageBreak  
   ,SLE_DocID  
   ,SLE_ParentID  
   ,SLE_SegmentID  
   ,SLE_ProjectSegID  
   ,SLE_StatusID  
   ,A_SegmentStatusId  
   ,IsDeleted  
   ,TrackOriginOrder  
   ,MTrackDescription  
 FROM ProjectSegmentStatus AS pss  WITH (NOLOCK)  
 WHERE pss.SegmentStatusId = @SegmentStatusId  
 AND pss.projectID = @PprojectId  
 AND pss.sectionId = @PsectionId  
 UNION ALL  
 SELECT  
 pss.SegmentStatusId  
   ,pss.SectionId  
   ,pss.ParentSegmentStatusId  
   ,pss.mSegmentStatusId  
   ,pss.mSegmentId  
   ,pss.SegmentId  
   ,pss.SegmentSource  
   ,pss.SegmentOrigin  
   ,pss.IndentLevel  
   ,pss.SequenceNumber  
   ,pss.SpecTypeTagId  
   ,pss.SegmentStatusTypeId  
   ,pss.IsParentSegmentStatusActive  
   ,pss.ProjectId  
   ,pss.CustomerId  
   ,pss.SegmentStatusCode  
   ,pss.IsShowAutoNumber  
   ,pss.IsRefStdParagraph  
   ,pss.FormattingJson  
   ,pss.CreateDate  
   ,pss.CreatedBy  
   ,pss.ModifiedDate  
   ,pss.ModifiedBy  
   ,pss.IsPageBreak  
   ,pss.SLE_DocID  
   ,pss.SLE_ParentID  
   ,pss.SLE_SegmentID  
   ,pss.SLE_ProjectSegID  
   ,pss.SLE_StatusID  
   ,pss.A_SegmentStatusId  
   ,pss.IsDeleted  
   ,pss.TrackOriginOrder  
   ,pss.MTrackDescription  
 FROM  ProjectSegmentStatus AS pss  WITH (NOLOCK)  
 INNER JOIN CTE AS c  
  ON pss.ParentSegmentStatusId = c.SegmentStatusId  
 WHERE pss.projectID = @PprojectId  
 AND pss.sectionId = @PsectionId)  
SELECT  
 @SegmentStatusId AS MasterSegmentStatusId  
   ,* INTO #temp1  
FROM cte  
ORDER BY ParentSegmentStatusId, SegmentStatusId;  
SET @ScenarioA = 0  
SET @ScenarioB = 0  
SET @ScenarioC = 0  
   -- CASE 1-Deleted master paragraph has at least one master subparagraph that has not been deleted  
   IF (( SELECT  
  COUNT(*)  
 FROM #temp1 AS t  
 INNER JOIN [SLCMaster].[dbo].[SegmentStatus] AS mss  WITH (NOLOCK)  
  ON mss.segmentId = t.msegmentId  
 WHERE mss.IndentLevel != t.IndentLevel  
 AND mss.SegmentStatusId = t.mSegmentStatusId)  
>= 1)  
BEGIN  
--US-30907 - To get correct sequence number of edit mode using segmentStatusId  

SELECT  t.*
INTO #tempCounts
 FROM #temp1 AS t  
 INNER JOIN [SLCMaster].[dbo].[SegmentStatus] AS mss WITH (NOLOCK)  
  ON mss.segmentId = t.msegmentId  
 WHERE mss.IndentLevel != t.IndentLevel  
 AND mss.SegmentStatusId = t.mSegmentStatusId 

SET @sequenceNos = (SELECT ',' + CONVERT(NVARCHAR(MAX), SegmentStatusId) FROM #tempCounts FOR XML PATH (''))

SET @Action = 'NEED_TO_PROMOTE'  
SET @ScenarioA = 1  

IF (SUBSTRING(@sequenceNos, 2, LEN(@sequenceNos))) = CAST(@SegmentStatusId AS NVARCHAR(100))
BEGIN
	SET @ScenarioA = 0
END

IF ((SELECT COUNT(1) FROM #tempCounts WHERE SegmentSource = 'M') = (SELECT COUNT(1) FROM #tempCounts))
BEGIN
	SET @ScenarioA = 0
END

DROP TABLE #tempCounts  
   END  
   -- CASE 2 - Deleted master paragraph has at least one user sub-paragraph  
   IF (( SELECT  
  COUNT(*)  
 FROM #temp1  
 WHERE SegmentSource = 'U'  
 AND SegmentOrigin = 'U')  
>= 1)  
BEGIN  
SET @Action = 'NEED_TO_REVIEW'  
--SET @sequenceNos=NULL  
SET @ScenarioB = 1  
   END  
   --CASE 3 -Deleted master paragraph has user modifications -- M or M*  
   IF (( SELECT  
  COUNT(*)  
 FROM #temp1  
 WHERE SegmentSource = 'M'  
 AND SegmentOrigin = 'U'  
 AND segmentId IS NOT NULL)  
>= 1)  
BEGIN  
SET @Action = 'NEED_TO_REVIEW'  
--SET @sequenceNos=NULL  
SET @ScenarioC = 1  
  
   END  
  
INSERT INTO @ProjectSegmentStatus ([SegmentStatusId], [SectionId], [ParentSegmentStatusId], [isParent],  
[mSegmentStatusId], [mSegmentId], [SegmentId], [SegmentSource], [SegmentOrigin], [IndentLevel], [SequenceNumber], [Remark], [isDeleted]  
, [ScenarioA], [ScenarioB], [ScenarioC])  
 SELECT  
  [SegmentStatusId]  
    ,[SectionId]  
    ,[ParentSegmentStatusId]  
    ,CASE  
   WHEN [SegmentStatusId] = @SegmentStatusId THEN 1  
   ELSE 0  
  END AS [isParent]  
    ,[mSegmentStatusId]  
    ,[mSegmentId]  
    ,[SegmentId]  
    ,[SegmentSource]  
    ,[SegmentOrigin]  
    ,[IndentLevel]  
    ,[SequenceNumber]  
    ,CASE  
   WHEN [SegmentStatusId] = @SegmentStatusId THEN @Action  
   ELSE NULL  
  END  
    ,CASE  
   WHEN [SegmentStatusId] = @SegmentStatusId THEN 1  
   ELSE 0  
  END AS [isDeleted]  
    ,CASE  
   WHEN [SegmentStatusId] = @SegmentStatusId THEN @ScenarioA  
   ELSE 0  
  END AS ScenarioA  
    ,CASE  
   WHEN [SegmentStatusId] = @SegmentStatusId THEN @ScenarioB  
   ELSE 0  
  END AS ScenarioB  
    ,CASE  
   WHEN [SegmentStatusId] = @SegmentStatusId THEN @ScenarioC  
   ELSE 0  
  END AS ScenarioC  
 FROM #temp1  
  
UPDATE @ProjectSegmentStatus  
SET [MessageDescription] = @sequenceNos  
WHERE [SegmentStatusId] = @SegmentStatusId  
  
SET @sequenceNos = NULL;  
  
DROP TABLE #temp1;  
SET @counter = @counter + 1  
    
  END --END OF WHILE LOOP  
  
UPDATE @ProjectSegmentStatus  
SET Remark = 'NEED_TO_PROMOTE'  
WHERE [ScenarioA] = 1  
  
--UPDATE @ProjectSegmentStatus  
--SET Remark='READY_TO_DELETE' WHERE [ScenarioA]=0 AND [ScenarioB]=0 AND [ScenarioC]=0  
--AND isDeleted=1  
  
--DELETE FROM @ProjectSegmentStatus WHERE [ScenarioA]=0 AND [ScenarioB]=0 AND [ScenarioC]=0  
--AND isDeleted=1  
  
  
SELECT  
 CONVERT(INT, (ROW_NUMBER() OVER (ORDER BY pss.SegmentStatusId))) AS RowNumber  
   ,pss.SegmentStatusId AS PSegmentStatusId  
   ,pss.ParentSegmentstatusId  
   ,pss.mSegmentId  
   ,pss.mSegmentStatusId  
   ,ps.mSectionId AS MSectionId  
   ,pss.SectionId AS PSectionId  
   ,pss.SegmentSource  
   ,pss.SegmentOrigin  
   ,psv.SegmentCode AS SegmentCode  
   ,psv.SegmentDescription  
   ,pss.Remark AS ActionName  
   ,pss.SequenceNumber  
   ,pss.SegmentId AS PSegmentId  
   ,pss.IsDeleted AS MasterSegmentIsDelete  
   ,pss.IndentLevel  
   ,SUBSTRING(pss.MessageDescription, 2, LEN(pss.MessageDescription)) AS MessageDescription  
   ,[ScenarioA]  
   ,[ScenarioB]  
   ,[ScenarioC]  
   ,CONVERT(BIT, 1) AS isParent INTO #tempTbl  
FROM @ProjectSegmentStatus AS pss  
INNER JOIN ProjectSegmentStatusView AS psv WITH (NOLOCK)  
 ON pss.SegmentStatusId = psv.SegmentStatusId  
INNER JOIN ProjectSection AS ps  WITH (NOLOCK)  
 ON ps.SectionId = pss.SectionId  
WHERE pss.IsDeleted = 1  
ORDER BY pss.IndentLevel, pss.SegmentStatusId  
  
UPDATE CH  
SET ch.isParent = 0  
FROM #tempTbl CH  
INNER JOIN #tempTbl PA  
 ON CH.ParentSegmentStatusId = PA.pSegmentStatusId  
  
;  
WITH cte  
AS  
(SELECT  
  *  
 FROM #tempTbl AS s  
 WHERE [ScenarioA] = 0  
 AND [ScenarioB] = 0  
 AND [ScenarioC] = 0  
 AND isParent = 1  
 UNION ALL  
 SELECT  
  t.*  
 FROM #tempTbl AS t  
 INNER JOIN cte AS c  
  ON t.ParentSegmentStatusId = c.PSegmentStatusId)  
UPDATE t  
SET isParent = 1  
FROM cte  
INNER JOIN #tempTbl AS t  
 ON cte.PSegmentStatusId = t.PSegmentStatusId;  
  
  
DELETE FROM #tempTbl  
WHERE [ScenarioA] = 0  
 AND [ScenarioB] = 0  
 AND [ScenarioC] = 0  
 AND isParent = 1  
  
  
  
SELECT  
 *  
FROM #tempTbl  
  
  
-- EXECUTE usp_getUpdatesNeedsReview 12922,6631715,2227,0,'FS'  
  
  
--GET SEGMENT CHOICES                    
SELECT  
DISTINCT  
	Convert(BIGINT,SCH.SegmentChoiceId ) as SegmentChoiceId  , 
	Convert(BIGINT,SCH.SegmentChoiceCode ) as SegmentChoiceCode  , 
   SCH.SectionId  ,
   SCH.ChoiceTypeId,  
	Convert(BIGINT,SCH.SegmentId ) as SegmentId 
FROM SLCMaster..SegmentChoice SCH  WITH (NOLOCK)  
INNER JOIN @ProjectSegmentStatus TMPSG  
 ON SCH.SegmentId = TMPSG.mSegmentId  
WHERE TMPSG.IsDeleted = 1  
  
--GET SEGMENT CHOICES OPTIONS                    
SELECT DISTINCT  
   CAST(CHOP.SegmentChoiceId AS BIGINT) AS SegmentChoiceId  
   ,CAST(CHOP.ChoiceOptionId AS BIGINT) AS ChoiceOptionId  
   ,CHOP.SortOrder  
   ,SCHOP.IsSelected  
   ,CAST(CHOP.ChoiceOptionCode AS BIGINT) AS ChoiceOptionCode  
   ,CHOP.OptionJson  
FROM SLCMaster..SegmentChoice SCH  WITH (NOLOCK)  
INNER JOIN SLCMaster..ChoiceOption CHOP  WITH (NOLOCK)  
 ON SCH.SegmentChoiceId = CHOP.SegmentChoiceId  
INNER JOIN SLCMaster..SelectedChoiceOption SCHOP  WITH (NOLOCK)  
 ON SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode  
INNER JOIN @ProjectSegmentStatus TMPSG  
 ON SCH.SegmentId = TMPSG.mSegmentId  
  
END  