CREATE PROCEDURE [dbo].[usp_InsertSpecDataSectionSegmentChoice]           
(@InpSegmentJson NVARCHAR(MAX) =''    )          
AS                
                  
BEGIN  
     
     
DECLARE @PInpSegmentJson NVARCHAR(MAX) =  @InpSegmentJson;  
    
    
      
 --DECLARE INP NOTE TABLE               
 DECLARE @InpParentSegmentStatusidTableVar TABLE(                
 SegmentStatusId BIGINT DEFAULT 0 ,              
 ProjectId INT DEFAULT 0  ,              
 CustomerId INT DEFAULT 0  ,              
 SectionId INT DEFAULT 0  ,              
 SegmentId BIGINT DEFAULT 0    ,         
 SegmentChoiceId BIGINT ,          
 ChoiceOptionId BIGINT ,          
 OptionJson nvarchar(max)   ,        
 mSegmentStatusId INT ,          
 mSegmentId INT ,        
 mSegmentChoiceCode int,        
 mSectionId int,      
 SegmentChoiceCode BIGINT   ,    
 SrNo int    
 );  
    
              
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE               
IF @PInpSegmentJson != ''              
BEGIN  
INSERT INTO @InpParentSegmentStatusidTableVar  
 SELECT  
  *  
    ,0  
    ,ROW_NUMBER() OVER (ORDER BY CustomerId) AS SrNo  
 FROM OPENJSON(@PInpSegmentJson)  
 WITH (  
 SegmentStatusId BIGINT '$.SegmentStatusId',  
 ProjectId INT '$.ProjectId',  
 CustomerId INT '$.CustomerId',  
 SectionId INT '$.SectionId',  
 SegmentId BIGINT '$.SegmentId',  
 SegmentChoiceId BIGINT '$.SegmentChoiceId',  
 ChoiceOptionId BIGINT '$.ChoiceOptionId',  
 OptionJson NVARCHAR(MAX) '$.OptionJson',  
 mSegmentStatusId INT '$.mSegmentStatusId',  
 mSegmentId INT '$.mSegmentId',  
 mSegmentChoiceCode INT '$.SegmentChoiceId',  
 mSectionId INT '$.mSectionId'  
 );  
END  
  
  
DECLARE @SectionTable TABLE (  
 mSectionId INT  
   ,SectionId INT  
   ,ProjectId INT  
   ,CustomerId INT  
)  
  
INSERT INTO @SectionTable (mSectionId, SectionId, ProjectId, CustomerId)  
 SELECT DISTINCT  
  mSectionId  
    ,SectionId  
    ,ProjectId  
    ,CustomerId  
 FROM @InpParentSegmentStatusidTableVar  
  
  
DECLARE @ProjectId INT = (SELECT TOP 1  
  ProjectId  
 FROM @SectionTable)  
DECLARE @CustomerId INT = (SELECT TOP 1  
  CustomerId  
 FROM @SectionTable)  
  
  
DROP TABLE IF EXISTS #MasterSegmentChoice  
  
  
SELECT DISTINCT  
 slcmsc.* INTO #MasterSegmentChoice  
FROM SLCMaster.dbo.SegmentChoice slcmsc WITH (NOLOCK)  
INNER JOIN @SectionTable ss  
 ON slcmsc.SectionId = ss.mSectionId  
  
DROP TABLE IF EXISTS #MasterChoiceOption  
  
SELECT  
 slcmco.* INTO #MasterChoiceOption  
FROM #MasterSegmentChoice SLCMSC  
INNER JOIN SLCMaster..ChoiceOption slcmco WITH (NOLOCK)  
 ON SLCMSC.SegmentChoiceId = slcmco.SegmentChoiceId  
  
  
  
DECLARE @Count INT = (SELECT  
  COUNT(*)  
 FROM @InpParentSegmentStatusidTableVar)  
  
DECLARE @results INT = 1  
  
DECLARE @id_control INT = 0  
DECLARE @loop_control INT = 100  
  
IF (@Count > @loop_control)  
BEGIN  
SET @results = @Count / @loop_control;  
SET @results = @results + 1  
end  
else  
begin  
SET @results = 1  
end  
  
INSERT INTO ProjectSegmentChoice (SectionId  
, SegmentStatusId  
, SegmentId  
, ChoiceTypeId  
, ProjectId  
, CustomerId  
, SegmentChoiceSource  
, CreatedBy  
, CreateDate  
, A_SegmentChoiceId  
, IsDeleted)  
 SELECT DISTINCT  
  INBT.SectionId  
    ,INBT.SegmentStatusId  
    ,INBT.SegmentId  
    ,slcmsc.ChoiceTypeId  
    ,ProjectId  
    ,CustomerId  
    ,'U' AS SegmentChoiceSource  
    ,CustomerId AS CreatedBy  
    ,GETUTCDATE() AS CreateDate  
    ,INBT.SegmentChoiceId AS A_SegmentChoiceId  
    ,0 AS IsDeleted  
 FROM @InpParentSegmentStatusidTableVar INBT  
 INNER JOIN SLCMaster..SegmentChoice slcmsc  WITH (NOLOCK)   
  ON  slcmsc.SectionId=INBT.mSectionId   
  AND slcmsc.SegmentStatusId=INBT.mSegmentStatusId  
  AND  INBT.mSegmentChoiceCode = slcmsc.SegmentChoiceId  
  
  
DROP TABLE IF EXISTS #ProjectSegmentChoiceTemp  
  
SELECT DISTINCT  
 psc.* INTO #ProjectSegmentChoiceTemp  
FROM ProjectSegmentChoice psc WITH (NOLOCK)  
WHERE psc.ProjectId = @ProjectId  
AND psc.CustomerId = @CustomerId  
  
UPDATE INBT  
SET INBT.SegmentChoiceId = psc.SegmentChoiceId  
   ,INBT.SegmentChoiceCode = psc.SegmentChoiceCode  
FROM @InpParentSegmentStatusidTableVar INBT  
INNER JOIN #ProjectSegmentChoiceTemp psc  
 ON INBT.SegmentChoiceId = psc.A_SegmentChoiceId  
 AND INBT.SegmentStatusId = psc.SegmentStatusId  
 AND INBT.SegmentId = psc.SegmentId  
WHERE psc.ProjectId = @ProjectId  
AND psc.CustomerId = @CustomerId  
  
  
  
WHILE (@results > 0)  
BEGIN  
  
PRINT 'ProjectChoiceOption'  
  
INSERT INTO ProjectChoiceOption (SegmentChoiceId,  
ChoiceOptionSource  
, SortOrder  
, OptionJson  
, ProjectId  
, SectionId  
, CustomerId  
, CreatedBy  
, CreateDate  
, A_ChoiceOptionId  
, IsDeleted)  
  
 SELECT DISTINCT  
  INBT.SegmentChoiceId  
    ,'U' AS ChoiceOptionSource  
    ,slcmco.SortOrder  
    ,IIF(INBT.ChoiceOptionId = slcmco.ChoiceOptionCode, INBT.OptionJson, slcmco.OptionJson) AS OptionJson  
    ,INBT.ProjectId  
    ,INBT.SectionId  
    ,INBT.CustomerId  
    ,INBT.CustomerId AS CreatedBy  
    ,GETUTCDATE() AS CreateDate  
    ,slcmco.ChoiceOptionCode  
    ,0 AS IsDeleted  
 FROM @InpParentSegmentStatusidTableVar INBT  
 INNER JOIN #MasterChoiceOption slcmco  
  ON INBT.mSegmentChoiceCode = slcmco.SegmentChoiceId  
 WHERE INBT.SrNo > @id_control  
 AND INBT.SrNo <= @id_control + @loop_control  
  
PRINT 'SelectedChoiceOption'  
  
INSERT INTO SelectedChoiceOption (SegmentChoiceCode  
, ChoiceOptionCode  
, ChoiceOptionSource  
, IsSelected  
, SectionId  
, ProjectId  
, CustomerId  
, OptionJson,  
IsDeleted)  
  
 SELECT DISTINCT  
  INBT.SegmentChoiceCode  
    ,pco.ChoiceOptionCode  
    ,'U' AS ChoiceOptionSource  
    ,IIF(INBT.ChoiceOptionId = pco.A_ChoiceOptionId, 1, 0) AS IsSelected  
    ,INBT.SectionId  
    ,INBT.ProjectId  
    ,INBT.CustomerId  
    ,NULL AS OptionJson  
    ,0 AS IsDeleted  
 FROM @InpParentSegmentStatusidTableVar INBT  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)  
  ON INBT.SectionId = pco.SectionId  
   AND INBT.ProjectId = pco.ProjectId  
   AND INBT.CustomerId = pco.CustomerId  
   AND INBT.SegmentChoiceId = pco.SegmentChoiceId  
 WHERE pco.ProjectId = @ProjectId  
 AND pco.CustomerId = @CustomerId  
 AND INBT.SrNo > @id_control  
 AND INBT.SrNo <= @id_control + @loop_control  
  
  
DROP TABLE IF EXISTS #TotalCountSegmentStatusIdTbl  
  
DECLARE @MultipleHyperlinkCount INT = 0;  
SELECT  
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl  
FROM @InpParentSegmentStatusidTableVar INBT  
WHERE INBT.SrNo > @id_control  
AND INBT.SrNo <= @id_control + @loop_control  
GROUP BY SegmentStatusId  
  
SELECT  
 @MultipleHyperlinkCount = MAX(TotalCountSegmentStatusId)  
FROM #TotalCountSegmentStatusIdTbl  
WHILE (@MultipleHyperlinkCount > 0)  
BEGIN  
  
UPDATE ps  
SET ps.SegmentDescription = REPLACE(ps.SegmentDescription, '{CH#' + CAST(INBT.mSegmentChoiceCode AS NVARCHAR(MAX)) + '}', '{CH#' + CAST(INBT.SegmentChoiceCode AS NVARCHAR(MAX)) + '}')  
FROM ProjectSegment ps WITH (NOLOCK)  
INNER JOIN @InpParentSegmentStatusidTableVar INBT  
 ON ps.SegmentStatusId = INBT.SegmentStatusId  
 AND ps.SegmentId = INBT.SegmentId  
 AND ps.SectionId = INBT.SectionId  
 AND ps.ProjectId = INBT.ProjectId  
 AND ps.CustomerId = INBT.CustomerId  
 AND ps.SegmentDescription LIKE '%{CH#' + CAST(INBT.mSegmentChoiceCode AS NVARCHAR(MAX)) + '}%'  
WHERE ps.ProjectId = @ProjectId  
AND ps.CustomerId = @CustomerId  
AND INBT.SrNo > @id_control  
AND INBT.SrNo <= @id_control + @loop_control  
  
SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;  
      
    
END  
SET @results = @results - 1  
-- next batch                  
SET @id_control = @id_control + @loop_control  
   
  END  

   END  
  
  
   
GO


