
CREATE PROC [dbo].[usp_getMutedSegments]                        
(                        
  @SectionId INT  = NULL --= 449                    
 ,@MSectionId INT  = NULL --= 9                    
 ,@ProjectId INT  = NULL --= 1                        
 ,@CustomerId INT  = NULL --= 8                    
 ,@UserId INT  = NULL --= 92                      
 ,@CatalogueType NVARCHAR(10) NULL = 'FS'             
)                      
AS BEGIN    
      
 --Variable declaration     
DECLARE @PSectionId INT = @SectionId    
                     
DECLARE @PMSectionId INT = @MSectionId    
                    
DECLARE @PProjectId INT = @ProjectId    
                      
DECLARE @PCustomerId INT = @CustomerId    
                  
DECLARE @PUserId INT = @UserId    
                    
DECLARE @PCatalogueType NVARCHAR(10) = @CatalogueType    
    
--Get master paragraphs    
SELECT    
 SS.SegmentStatusId    
   ,SS.SectionId    
   ,SS.ParentSegmentStatusId    
   ,SS.SegmentId    
   ,SS.IndentLevel    
   ,SS.SegmentSource    
   ,SS.SequenceNumber    
   ,SS.SpecTypeTagId    
   ,SS.SegmentStatusTypeId    
   ,SS.IsParentSegmentStatusActive    
   ,SS.SegmentStatusCode    
   ,SS.IsShowAutoNumber    
   ,SS.FormattingJson    
   ,SS.IsRefStdParagraph    
   ,SS.CreateDate    
   ,SS.ModifiedDate    
   ,SS.PublicationDate    
   ,SS.IsDeleted    
   ,SS.MasterDataTypeId    
   ,LAG(SS.SegmentStatusId, 1) OVER (ORDER BY SS.SequenceNumber) AS PrevSegmentStatusId    
   ,CASE    
  WHEN LRT.TagType IS NULL THEN 0    
  ELSE 1    
 END AS IsManufacturerUpdate INTO #MasterSegmentStatus    
FROM SLCMaster..SegmentStatus SS WITH (NOLOCK)    
LEFT JOIN SLCMaster..SegmentRequirementTag SRT WITH (NOLOCK)    
 ON SRT.SectionId = @PMSectionId    
  AND SRT.SegmentStatusId = SS.SegmentStatusId    
  AND SRT.RequirementTagId=11    
LEFT JOIN SLCMaster..LuRequirementTag LRT WITH (NOLOCK)    
 ON LRT.RequirementTagId = SRT.RequirementTagId    
  AND LRT.RequirementTagId=11    
WHERE SS.SectionId = @PMSectionId    
AND ISNULL(SS.IsDeleted, 0) = 0    
    
SELECT    
 MSS.SegmentStatusId    
   ,MSS.SectionId    
   ,MSS.ParentSegmentStatusId    
   ,MSS.SegmentId    
   ,MSS.IndentLevel    
   ,MSS.SegmentSource    
   ,MSS.SequenceNumber    
   ,MSS.SpecTypeTagId    
   ,MSS.SegmentStatusTypeId    
   ,MSS.IsParentSegmentStatusActive    
   ,MSS.SegmentStatusCode    
   ,MSS.IsShowAutoNumber    
   ,MSS.FormattingJson    
   ,MSS.IsRefStdParagraph    
   ,MSS.CreateDate    
   ,MSS.ModifiedDate    
   ,MSS.PublicationDate    
   ,MSS.IsDeleted    
   ,MSS.MasterDataTypeId    
   ,MSS.PrevSegmentStatusId    
   ,MSS.IsManufacturerUpdate    
   ,PSS.mSegmentId INTO #MutedParagraphs    
FROM #MasterSegmentStatus MSS    
LEFT JOIN ProjectSegmentStatus PSS WITH (NOLOCK)    
 ON PSS.mSegmentStatusId = MSS.SegmentStatusId AND PSS.ProjectId = @PProjectId
  AND PSS.SectionId = @PSectionId    
  AND ISNULL(PSS.IsDeleted,0) = 0
WHERE MSS.SectionId = @PMSectionId    
AND PSS.mSegmentStatusId IS NULL    
    
DECLARE @ParentSegmentStatusId INT = 0;    
-- Get Muted paragraphs     
SELECT    
 --0 AS MasterParagraphX      
 ISNULL((SELECT TOP 1    
   ISNULL(TMSS.SegmentStatusId, 0)    
  FROM #MasterSegmentStatus TMSS    
  WHERE TMSS.ParentSegmentStatusId = MST.ParentSegmentStatusId    
  AND TMSS.IndentLevel = MST.IndentLevel    
  AND TMSS.SequenceNumber < MST.SequenceNumber    
  ORDER BY TMSS.SequenceNumber DESC)    
 , 0) AS MasterParagraphX    
   ,ISNULL(MST.PrevSegmentStatusId ,0) as PrevSegmentStatusId  
   ,@PSectionId AS SectionId    
   ,ISNULL(MST.ParentSegmentStatusId,0) AS ParentSegmentStatusId    
   ,ISNULL(MST.SegmentStatusId,0) AS MSegmentStatusId    
   ,0 AS SegmentStatusId    
   ,ISNULL(MST.SegmentId,0) AS MSegmentId    
   ,0 AS SegmentId    
   ,MST.SegmentSource    
   ,MST.IndentLevel    
   ,MST.SequenceNumber    
   ,MST.SegmentStatusTypeId    
   ,MST.IsParentSegmentStatusActive    
   ,@PProjectId AS ProjectId    
   ,@PCustomerId AS CustomerId    
   ,@PUserId AS UserId    
   ,MST.SegmentStatusCode    
   ,ISNULL(MST.SpecTypeTagId, 0) AS SpecTypeTagId    
   ,MST.IsShowAutoNumber    
   ,ISNULL(MST.FormattingJson, '') AS FormattingJson    
   ,MST.IsRefStdParagraph    
   ,MST.IsManufacturerUpdate    
   ,MS.SegmentDescription    
FROM #MutedParagraphs MST    
LEFT JOIN SLCMaster..Segment MS WITH (NOLOCK)    
 ON MS.SegmentId = MST.SegmentId    
ORDER BY MST.SequenceNumber    
    
--GET SEGMENT CHOICES                
SELECT DISTINCT    
 ISNULL(SCH.SegmentChoiceId,0) As SegmentChoiceId  
   ,ISNULL(SCH.SegmentChoiceCode,0)  As SegmentChoiceCode  
   ,ISNULL(SCH.SectionId ,0) As SectionId  
   ,ISNULL(SCH.ChoiceTypeId,0) As ChoiceTypeId  
   ,ISNULL(SCH.SegmentId,0) As SegmentId  
FROM SLCMaster..SegmentChoice SCH WITH (NOLOCK)    
INNER JOIN #MutedParagraphs MST    
 ON SCH.SegmentStatusId = MST.SegmentStatusId    
    
--GET SEGMENT CHOICES OPTIONS                                          
SELECT DISTINCT    
    ISNULL(CHOP.SegmentChoiceId,0) As SegmentChoiceId  
   ,ISNULL(CHOP.ChoiceOptionId,0) As ChoiceOptionId  
   ,CHOP.SortOrder    
   ,SCHOP.IsSelected    
   ,ISNULL(CHOP.ChoiceOptionCode,0)  as ChoiceOptionCode  
   ,CHOP.OptionJson    
FROM SLCMaster..SegmentChoice SCH WITH (NOLOCK)    
INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)    
 ON SCH.SegmentChoiceId = CHOP.SegmentChoiceId    
INNER JOIN SLCMaster..SelectedChoiceOption SCHOP WITH (NOLOCK)    
 ON SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode    
INNER JOIN #MutedParagraphs MST WITH (NOLOCK)    
 ON SCH.SegmentStatusId = MST.SegmentStatusId    
    
END 
GO


