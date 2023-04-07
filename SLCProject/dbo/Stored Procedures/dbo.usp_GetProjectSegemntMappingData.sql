CREATE PROCEDURE [dbo].[usp_GetProjectSegemntMappingData] 
(    
@ProjectId int,    
@CustomerId int    
)    
AS    
BEGIN  
  
DECLARE @SegemntChoiceTbl Table(    
SegmentChoiceCode BIGINT ,    
ChoiceOptionCode BIGINT ,     
IsSelected bit ,    
SectionId int ,    
ProjectId int     
)  
    
    
DECLARE @SegmentStatusTbl table(    
mSegmentStatusId int null,    
mSegmentId int null,    
SpecTypeTagId int null,    
SegmentStatusTypeId int null,    
IsParentSegmentStatusActive int null ,    
mSectionId int ,    
SectionId int    
 )  
    
    
DECLARE @SectionTbl table(    
SectionId int,    
mSectionId int,    
ProjectId int,    
CustomerId Int    
)  
/*Get Active sections */  
INSERT INTO @SectionTbl (SectionId, mSectionId, ProjectId, CustomerId)  
 SELECT  
  ps.SectionId  
    ,ps.mSectionId  
    ,ps.ProjectId  
    ,ps.CustomerId  
 FROM ProjectSection ps WITH (NOLOCK)  
 INNER JOIN ProjectSegmentStatus pss WITH (NOLOCK)  
  ON pss.SectionId = ps.SectionId  
   AND ps.ProjectId = pss.ProjectId  
   AND ps.CustomerId = pss.CustomerId  
 WHERE ps.ProjectId = @ProjectId  
 AND ps.CustomerId = @CustomerId  
 AND pss.ParentSegmentStatusId = 0  
 AND pss.SegmentStatusTypeId < 6  
  
  
SELECT DISTINCT  
 sco.SegmentChoiceCode  
   ,sco.ChoiceOptionCode  
   ,sco.ChoiceOptionSource  
   ,sco.IsSelected  
   ,sco.SectionId  
   ,sco.ProjectId  
   ,sco.CustomerId  
   ,sco.OptionJson  
   ,sco.IsDeleted INTO #TempSelectedChoiceOption  
FROM SelectedChoiceOption sco WITH (NOLOCK)  
INNER JOIN @SectionTbl st  
 ON st.SectionId = sco.SectionId  
  AND st.ProjectId = sco.ProjectId  
  AND st.CustomerId = sco.CustomerId  
WHERE sco.ProjectId = @ProjectId  
AND sco.CustomerId = @CustomerId  
AND ISNULL(sco.IsDeleted, 0) = 0  
AND sco.IsSelected=1  
  
SELECT DISTINCT  
 pss.mSegmentStatusId  
   ,pss.mSegmentId  
   ,pss.SpecTypeTagId  
   ,pss.SegmentStatusTypeId  
   ,pss.IsParentSegmentStatusActive  
   ,stbl.mSectionId  
   ,pss.SegmentId  
   ,pss.SegmentStatusId  
   ,pss.SectionId  
   ,pss.ProjectId  
   ,pss.CustomerId  
   ,pss.SegmentSource  
   ,pss.SegmentOrigin  
   ,pss.IndentLevel  
   ,pss.SequenceNumber  
   ,pss.IsShowAutoNumber  
   ,pss.IsRefStdParagraph
   ,CONVERT(BIGINT, pss.A_SegmentStatusId)AS MaxSegmentStatusId
    INTO #TempProjectSegmentStatuss  
FROM ProjectSegmentStatus pss WITH (NOLOCK)  
INNER JOIN @SectionTbl stbl  
 ON stbl.SectionId = pss.SectionId  
  AND stbl.ProjectId = pss.ProjectId  
  AND stbl.CustomerId = pss.CustomerId  
WHERE pss.ProjectId = @ProjectId  
AND pss.CustomerId = @CustomerId  
AND ISNULL(pss.IsDeleted, 0) = 0  
  
SELECT  
 mSegmentStatusId  
   ,mSegmentId  
   ,SpecTypeTagId  
   ,SegmentStatusTypeId  
   ,CAST(IsParentSegmentStatusActive AS BIT) AS IsParentSegmentStatusActive  
   ,mSectionId  
FROM #TempProjectSegmentStatuss  
WHERE SegmentStatusTypeId < 6  
AND SegmentSource = 'M'  
  
SELECT DISTINCT  
 sco.SegmentChoiceCode  
   ,sco.ChoiceOptionCode  
   ,CAST(sco.IsSelected AS BIT) AS IsSelected  
   ,stbl.mSegmentStatusId  
   ,stbl.mSegmentId  
   ,stbl.mSectionId  
   ,sco.OptionJson  
FROM #TempProjectSegmentStatuss stbl  
INNER JOIN SLCMaster..SegmentChoice slcmsc WITH (NOLOCK)  
 ON stbl.mSectionId = slcmsc.SectionId  
  AND slcmsc.SegmentStatusId = stbl.mSegmentStatusId  
  AND slcmsc.SegmentId = stbl.mSegmentId  
INNER JOIN #TempSelectedChoiceOption sco 
 ON sco.SectionId = stbl.SectionId  
  AND sco.SegmentChoiceCode = slcmsc.SegmentChoiceCode  
WHERE sco.ChoiceOptionSource = 'M'  
AND stbl.SegmentStatusTypeId < 6  
AND sco.IsSelected = 1  
ORDER BY sco.SegmentChoiceCode ASC  
  
SELECT DISTINCT  
 pss.mSectionId  
   ,pn.NoteText  
   ,pn.Title  
   ,pss.mSegmentId  
   ,pss.mSegmentStatusId  
FROM ProjectNote pn WITH (NOLOCK)  
INNER JOIN #TempProjectSegmentStatuss pss   
 ON pn.SectionId = pss.SectionId  
  AND pn.ProjectId = pss.ProjectId  
  AND pn.CustomerId = pss.CustomerId  
  AND pn.SegmentStatusId = pss.SegmentStatusId  
  AND pss.SegmentStatusTypeId < 6  
  AND pss.SegmentSource = 'M'  
  
  
  
DROP TABLE IF EXISTS #TempProjectSegmentStatus  
  
  
SELECT  
 pss.SegmentStatusId  
   ,pss.SectionId  
   ,pss.SegmentId  
   ,pss.SegmentSource  
   ,SegmentOrigin  
   ,IndentLevel  
   ,SequenceNumber  
   ,SpecTypeTagId  
   ,SegmentStatusTypeId  
   ,IsParentSegmentStatusActive  
   ,pss.ProjectId  
   ,pss.CustomerId  
   ,IsShowAutoNumber  
   ,IsRefStdParagraph  
   ,pss.mSectionId  
   ,ps.SegmentDescription 
   ,pss.MaxSegmentStatusId 
   INTO #TempProjectSegmentStatus  
FROM ProjectSegment ps WITH (NOLOCK)  
INNER JOIN #TempProjectSegmentStatuss pss   
 ON pss.sectionId = ps.SectionId  
  AND pss.SegmentStatusId = ps.SegmentStatusId  
  AND pss.SegmentId = ps.SegmentId  
  AND pss.ProjectId = ps.ProjectId  
  AND pss.CustomerId = ps.CustomerId  
  AND pss.SegmentSource = 'U'  
  
SELECT DISTINCT  
 SegmentStatusId AS OriginalSegmentStatusId  
   ,SectionId AS OriginalSectionId  
   ,SegmentId AS OriginalSegmentId  
   ,SegmentSource  
   ,SegmentOrigin  
   ,IndentLevel  
   ,SequenceNumber  
   ,SpecTypeTagId  
   ,SegmentStatusTypeId  
   ,IsParentSegmentStatusActive  
   ,ProjectId  
   ,CustomerId  
   ,IsShowAutoNumber  
   ,IsRefStdParagraph  
   ,mSectionId  
   ,SegmentDescription  
   ,MaxSegmentStatusId 
FROM #TempProjectSegmentStatus  
  
  
SELECT DISTINCT  
 psc.SegmentChoiceId  
   ,psc.SectionId  
   ,psc.SegmentStatusId  
   ,psc.SegmentId  
   ,psc.ChoiceTypeId  
   ,psc.ProjectId  
   ,psc.CustomerId  
   ,psc.SegmentChoiceSource  
   ,psc.SegmentChoiceCode  
   ,psc.A_SegmentChoiceId INTO #TempProjectSegmentChoice  
FROM @SectionTbl stb  
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)  
 ON stb.SectionId = psc.SectionId  
  AND stb.ProjectId = psc.ProjectId  
  AND stb.CustomerId = psc.CustomerId  
WHERE psc.ProjectId = @ProjectId  
AND psc.CustomerId = @CustomerId  
  
  
SELECT DISTINCT  
 pco.SegmentChoiceId  
   ,pco.SectionId  
   ,pco.ProjectId  
   ,pco.CustomerId  
   ,pco.ChoiceOptionCode  
   ,pco.OptionJson  
   ,pco.SortOrder  
   ,pco.A_ChoiceOptionId INTO #TempProjectChoiceOption  
FROM #TempProjectSegmentChoice stb  
INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)  
 ON stb.SegmentChoiceId = pco.SegmentChoiceId  
  AND pco.SectionId = stb.SectionId  
  AND pco.ProjectId = stb.ProjectId  
  AND pco.CustomerId = stb.CustomerId  
WHERE pco.ProjectId = @ProjectId  
AND pco.CustomerId = @CustomerId  
  
SELECT DISTINCT  
 sco.SegmentChoiceCode  
   ,pco.ChoiceOptionCode  
   ,CAST(sco.IsSelected AS BIT) AS IsSelected  
   ,stbl.SegmentStatusId  
   ,stbl.SegmentId  
   ,stbl.SectionId  
   ,pco.OptionJson  
   ,stbl.mSectionId  
   ,psc.ChoiceTypeId  
   ,pco.SortOrder  
   ,psc.A_SegmentChoiceId AS MasterSegmentChoiceId  
   ,pco.A_ChoiceOptionId AS MasterChoiceOptionId  
FROM #TempProjectSegmentStatus stbl  
INNER JOIN #TempProjectSegmentChoice psc  
 ON stbl.SectionId = psc.SectionId  
  AND psc.SegmentStatusId = stbl.SegmentStatusId  
INNER JOIN #TempProjectChoiceOption pco  
 ON pco.SegmentChoiceId = psc.SegmentChoiceId  
INNER JOIN #TempSelectedChoiceOption sco  
 ON sco.SectionId = stbl.SectionId  
  AND sco.ProjectId = stbl.ProjectId  
  AND sco.CustomerId = stbl.CustomerId  
  AND sco.ChoiceOptionCode = pco.ChoiceOptionCode  
WHERE sco.ChoiceOptionSource = 'U'  
ORDER BY sco.SegmentChoiceCode ASC  
  
  
SELECT DISTINCT  
 stbl.mSectionId  
   ,pn.NoteText  
   ,pn.Title  
   ,stbl.SegmentId  
   ,stbl.SegmentStatusId  
   ,stbl.SectionId  
FROM ProjectNote pn WITH (NOLOCK)  
INNER JOIN #TempProjectSegmentStatus stbl  
 ON stbl.SectionId = pn.SectionId  
  AND stbl.ProjectId = pn.ProjectId  
  AND stbl.CustomerId = pn.CustomerId  
  AND stbl.SegmentStatusId = pn.SegmentStatusId  
WHERE pn.ProjectId = @ProjectId  
AND pn.CustomerId = @CustomerId  
  
  
END  
GO


