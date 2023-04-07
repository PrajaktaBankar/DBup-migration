CREATE PROCEDURE [dbo].[usp_InsertSpecDataSectionSegmentChoiceToSLCProject]            
(@InpSegmentJson NVARCHAR(MAX) =''    )  
AS              
                
BEGIN  
        
  DECLARE @PInpSegmentJson NVARCHAR(MAX) =  @InpSegmentJson;  
         
 --DECLARE INP NOTE TABLE               
 DECLARE @InpParentSegmentStatusidTableVar TABLE(     
 mSectionId INT DEFAULT 0 ,                  
 SegmentStatusId BIGINT DEFAULT 0 ,              
 ProjectId INT DEFAULT 0  ,              
 CustomerId INT DEFAULT 0  ,              
 SectionId INT DEFAULT 0  ,              
 SegmentId BIGINT DEFAULT 0    ,         
 SegmentChoiceCode BIGINT ,          
 ChoiceOptionCode BIGINT ,          
 OptionJson nvarchar(max)   ,        
 IsSelected bit ,          
 ChoiceTypeId INT ,      
 mSegmentChoiceCode BIGINT ,      
 SortOrder INT,      
  MasterSegmentChoiceId BIGINT ,      
 MasterChoiceOptionId BIGINT,     
  SegmentChoiceId BIGINT       
 );  
    
      
        
          
              
 --PUT FETCHED INP RESULT IN LOCAL TABLE VARIABLE               
IF @PInpSegmentJson != ''              
BEGIN  
INSERT INTO @InpParentSegmentStatusidTableVar  
 SELECT  
  *  
    ,0  
 FROM OPENJSON(@PInpSegmentJson)  
 WITH (  
 mSectionId INT '$.mSectionId',  
 SegmentStatusId BIGINT '$.SegmentStatusId',  
 ProjectId INT '$.ProjectId',  
 CustomerId INT '$.CustomerId',  
 SectionId INT '$.SectionId',  
 SegmentId BIGINT '$.SegmentId',  
 SegmentChoiceCode BIGINT '$.SegmentChoiceCode',  
 ChoiceOptionCode BIGINT '$.ChoiceOptionCode',  
 OptionJson NVARCHAR(MAX) '$.OptionJson',  
 IsSelected BIT '$.IsSelected',  
 ChoiceTypeId INT '$.ChoiceTypeId',  
 mSegmentChoiceCode BIGINT '$.SegmentChoiceCode',  
 SortOrder INT '$.SortOrder',  
 MasterSegmentChoiceId BIGINT '$.MasterSegmentChoiceId',  
 MasterChoiceOptionId BIGINT '$.MasterChoiceOptionId'  
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
    ,INBT.ChoiceTypeId  
    ,ProjectId  
    ,CustomerId  
    ,'U' AS SegmentChoiceSource  
    ,CustomerId AS CreatedBy  
    ,GETUTCDATE() AS CreateDate  
    ,INBT.MasterSegmentChoiceId AS A_SegmentChoiceId  
    ,0 AS IsDeleted  
 FROM @InpParentSegmentStatusidTableVar INBT  
  
  
UPDATE INBT  
SET INBT.SegmentChoiceId = psc.SegmentChoiceId  
   ,INBT.SegmentChoiceCode = psc.SegmentChoiceCode  
FROM @InpParentSegmentStatusidTableVar INBT  
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)  
 ON INBT.SectionId = psc.SectionId  
 AND INBT.ProjectId = psc.ProjectId  
 AND INBT.CustomerId = psc.CustomerId  
 AND INBT.SegmentStatusId = psc.SegmentStatusId  
 AND INBT.MasterSegmentChoiceId = psc.A_SegmentChoiceId  
  
  
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
    ,IIF(INBT.MasterChoiceOptionId = slcmco.ChoiceOptionCode, INBT.OptionJson, slcmco.OptionJson) AS OptionJson  
    ,INBT.ProjectId  
    ,INBT.SectionId  
    ,INBT.CustomerId  
    ,INBT.CustomerId  
    ,GETUTCDATE() AS CreateDate  
    ,slcmco.ChoiceOptionCode AS A_ChoiceOptionId  
    ,0 AS IsDeleted  
 FROM @InpParentSegmentStatusidTableVar INBT  
 INNER JOIN #MasterSegmentChoice SLCMSC  
  ON INBT.MasterSegmentChoiceId = SLCMSC.SegmentChoiceId  
 INNER JOIN #MasterChoiceOption slcmco  
  ON SLCMSC.SegmentChoiceId = slcmco.SegmentChoiceId  
  
  
--UPDATE pco    
--SET pco.OptionJson = INBT.OptionJson    
--FROM ProjectChoiceOption pco WITH (NOLOCK)    
--INNER JOIN @InpParentSegmentStatusidTableVar INBT    
-- ON  INBT.SectionId = pco.SectionId    
-- AND INBT.SegmentChoiceId = pco.SegmentChoiceId    
-- AND INBT.MasterChoiceOptionId = pco.A_ChoiceOptionId    
  
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
    ,IIF(INBT.MasterChoiceOptionId = pco.A_ChoiceOptionId, 1, 0) AS IsSelected  
    ,INBT.SectionId  
    ,INBT.ProjectId  
    ,INBT.CustomerId  
    ,NULL AS OptionJson  
    ,0 AS IsDeleted  
  
 FROM @InpParentSegmentStatusidTableVar INBT  
 INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)  
  ON pco.SectionId = INBT.SectionId  
   AND INBT.SegmentChoiceId = pco.SegmentChoiceId  
  
  
--UPDATE sco    
--SET sco.IsSelected = 1    
--FROM @InpParentSegmentStatusidTableVar INBT    
--INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)    
-- ON INBT.SectionId = pco.SectionId    
-- AND INBT.SegmentChoiceId = pco.SegmentChoiceId    
-- AND INBT.MasterChoiceOptionId = pco.A_ChoiceOptionId    
--INNER JOIN SelectedChoiceOption sco WITH (NOLOCK)    
-- ON sco.SectionId = pco.SectionId    
-- AND sco.ProjectId = pco.ProjectId    
-- AND sco.CustomerId = pco.CustomerId    
-- AND INBT.SegmentChoiceCode = sco.SegmentChoiceCode    
-- AND pco.ChoiceOptionCode = sco.ChoiceOptionCode    
-- AND sco.ChoiceOptionSource = 'U'    
  
  
DECLARE @MultipleHyperlinkCount INT = 0;  
SELECT  
 COUNT(SegmentStatusId) AS TotalCountSegmentStatusId INTO #TotalCountSegmentStatusIdTbl  
FROM @InpParentSegmentStatusidTableVar  
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
 ON ps.SectionId = INBT.SectionId  
 AND ps.ProjectId = INBT.ProjectId  
 AND ps.CustomerId = INBT.CustomerId  
 AND ps.SegmentStatusId = INBT.SegmentStatusId  
 AND ps.SegmentId = INBT.SegmentId  
 AND (ps.SegmentDescription LIKE '% {CH#' + CAST(INBT.mSegmentChoiceCode AS NVARCHAR(MAX)) + '}%'  
 OR ps.SegmentDescription LIKE '%{CH#' + CAST(INBT.mSegmentChoiceCode AS NVARCHAR(MAX)) + '}%'  
 OR ps.SegmentDescription LIKE '%{CH#' + CAST(INBT.mSegmentChoiceCode AS NVARCHAR(MAX)) + '} %')  
  
  
SET @MultipleHyperlinkCount = @MultipleHyperlinkCount - 1;  
        
 END  
END 

Go
    
    
