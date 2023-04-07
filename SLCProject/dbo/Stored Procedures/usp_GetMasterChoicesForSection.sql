CREATE PROCEDURE usp_GetMasterChoicesForSection      
(      
 @MasterSectionId INT      
)      
AS       
BEGIN      
SET NOCOUNT ON;      
      
 DECLARE @finalOutput TABLE      
 (      
   SegmentId INT      
   ,mSegmentId INT      
   ,ChoiceTypeId INT      
   ,ChoiceSource CHAR(1)      
   ,SegmentChoiceCode     INT      
   ,ChoiceOptionCode   INT       
   ,IsSelected    BIT      
   ,ChoiceOptionSource   CHAR(1)       
   ,OptionJson NVARCHAR(MAX)         
   ,SortOrder    TINYINT      
   ,SegmentChoiceId    INT      
   ,ChoiceOptionId   BIGINT       
   ,SelectedChoiceOptionId BIGINT      
 )      
      
SELECT ss.SegmentStatusId, ss.SegmentId INTO #SegmentStatus       
FROM SLCMaster..SegmentStatus ss  WITH (NOLOCK) WHERE ss.SectionId= @MasterSectionId      
      
SELECT sco.SelectedChoiceOptionId, sco.SegmentChoiceCode, sco.ChoiceOptionCode, sco.ChoiceOptionSource,sco.IsSelected,sco.SectionId      
INTO #SelectedChoiceOption      
FROM SLCMaster..SelectedChoiceOption sco  WITH (NOLOCK)      
WHERE sco.SectionId= @MasterSectionId      
      
SELECT         
   sc.SegmentId        
  ,sc.ChoiceTypeId        
  ,sc.SegmentChoiceSource        
  ,sc.SegmentChoiceCode        
  ,sc.SegmentChoiceId        
  ,sc.SectionId INTO #SegmentChoice      
FROM SLCMaster..SegmentChoice sc  WITH (NOLOCK) INNER JOIN      
#SegmentStatus ss ON sc.SegmentStatusId = ss.SegmentStatusId AND sc.SectionId = @MasterSectionId      
      
SELECT       
   co.ChoiceOptionCode        
  ,co.OptionJson        
  ,co.SortOrder        
  ,co.ChoiceOptionId        
  ,co.SegmentChoiceId        
  ,sc.SectionId  INTO #ChoiceOption       
FROM SLCMaster..ChoiceOption co  WITH (NOLOCK)      
INNER JOIN #SegmentChoice sc ON co.SegmentChoiceId = sc.SegmentChoiceId      
      
INSERT INTO @finalOutput      
  SELECT          
   0        
     ,PCH.SegmentId AS mSegmentId          
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
  FROM  #SegmentStatus  PSST WITH (NOLOCK)        
  INNER JOIN #SegmentChoice PCH WITH (NOLOCK)        
  ON PSST.SegmentId = PCH.SegmentId        
  INNER JOIN #ChoiceOption  PCHOP WITH (NOLOCK)          
   ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId        
  INNER JOIN #SelectedChoiceOption  PSCHOP WITH (NOLOCK)          
   ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode          
    AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode;        
      
SELECT * FROM @finalOutput       
      
END 