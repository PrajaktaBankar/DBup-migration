CREATE PROCEDURE [dbo].[usp_SetProjectSegemntMappingData] (@ProjectId INT,    
@CustomerId INT,    
@segmentMappingDataJson NVARCHAR(MAX),    
@segmentChoiceMappingDataJson NVARCHAR(MAX))    
AS    
BEGIN    
 DECLARE @InCompleteStatus INT = 2;    
 DECLARE @CompleteStatus INT = 3;    
 DECLARE @CompletePer90 INT = 90;   
 DECLARE @CompletePer INT = 100;    
 DECLARE @SegmentMappingTbl TABLE (    
  mSegmentStatusId INT    
    ,mSegmentId INT    
    ,SpecTypeTagId INT    
    ,SegmentStatusTypeId INT    
    ,IsParentSegmentStatusActive BIT    
    ,mSectionId INT    
    ,SectionId INT  
 )    
    
 DECLARE @DistinctSectionTbl TABLE (SectionId INT)  
 INSERT INTO @SegmentMappingTbl    
  SELECT    
   *     
  FROM OPENJSON(@segmentMappingDataJson)    
  WITH (    
  mSegmentStatusId INT '$.mSegmentStatusId',    
  mSegmentId INT '$.mSegmentId',    
  SpecTypeTagId INT '$.SpecTypeTagId',    
  SegmentStatusTypeId INT '$.SegmentStatusTypeId',    
  IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive',    
  mSectionId INT '$.mSectionId',    
  SectionId INT '$.SectionId'
    
  );    
  
  INSERT INTO @DistinctSectionTbl  
  SELECT DISTINCT SectionId FROM @SegmentMappingTbl  
  
 DECLARE @SegmentChoiceMappingTbl TABLE (    
  mSegmentStatusId INT    
    ,mSegmentId INT    
    ,mSectionId INT    
    ,SegmentChoiceCode BIGINT    
    ,ChoiceOptionCode BIGINT    
    ,IsSelected BIT    
    ,SectionId INT   
	,OptionJson nvarchar(MAX)    
 )    
    
 INSERT INTO @SegmentChoiceMappingTbl    
  SELECT    
   *    
  FROM OPENJSON(@segmentChoiceMappingDataJson)    
  WITH (    
  mSegmentStatusId INT '$.mSegmentStatusId',    
  mSegmentId INT '$.mSegmentId',    
  mSectionId INT '$.mSectionId',    
  SegmentChoiceCode BIGINT '$.SegmentChoiceCode',    
  ChoiceOptionCode BIGINT '$.ChoiceOptionCode',    
  IsSelected BIT '$.IsSelected',    
  SectionId INT '$.SectionId'    
  ,OptionJson NVARCHAR(MAX)  '$.OptionJson' 
  );    
    
 DECLARE @SegmentRowCount INT = (SELECT    
   COUNT(mSegmentStatusId)    
  FROM @SegmentMappingTbl)    
    
 SELECT    
  *    
 FROM @SegmentMappingTbl    
    
 IF (@SegmentRowCount > 0)    
 BEGIN    
    
  UPDATE pss    
  SET pss.SpecTypeTagId = smtbl.SpecTypeTagId    
     ,pss.SegmentStatusTypeId = smtbl.SegmentStatusTypeId    
     ,pss.IsParentSegmentStatusActive = smtbl.IsParentSegmentStatusActive    
  FROM ProjectSegmentStatus pss WITH (NOLOCK)    
  INNER JOIN @SegmentMappingTbl smtbl    
   ON smtbl.SectionId = pss.SectionId    
   AND smtbl.mSegmentId = pss.mSegmentId    
   AND smtbl.mSegmentStatusId = pss.mSegmentStatusId    
  WHERE pss.ProjectId = @ProjectId    
  AND pss.CustomerId = @CustomerId    
    
    
    
 END    
  
  UPDATE IPR    
 SET IPR.StatusId = @InCompleteStatus    
    ,IPR.CompletedPercentage = @CompletePer90   
 ,IPR.IsNotify=0  
 FROM ImportProjectRequest IPR  WITH (NOLOCK)   
 INNER JOIN @DistinctSectionTbl SM    
  ON IPR.TargetSectionId = SM.SectionId    
    
 DECLARE @ChoiceTableRowCount INT = (SELECT    
   COUNT(mSegmentStatusId)    
  FROM @SegmentChoiceMappingTbl)    
    
 IF (@ChoiceTableRowCount > 0)    
 BEGIN    
    
  UPDATE sco    
  SET sco.IsSelected = scmtbl.IsSelected  
  ,sco.OptionJson=CASE WHEN scmtbl.OptionJson='' THEN NULL ELSE scmtbl.OptionJson END
  FROM SelectedChoiceOption sco WITH (NOLOCK)    
  INNER JOIN @SegmentChoiceMappingTbl scmtbl    
   ON scmtbl.SegmentChoiceCode = sco.SegmentChoiceCode    
   AND scmtbl.ChoiceOptionCode = sco.ChoiceOptionCode    
   AND sco.SectionId = scmtbl.SectionId    
  WHERE sco.ProjectId = @ProjectId    
  AND sco.CustomerId = @CustomerId    
  AND sco.ChoiceOptionSource = 'M'    
 END    
    
    
 UPDATE IPR    
 SET IPR.StatusId = @CompleteStatus    
    ,IPR.CompletedPercentage = @CompletePer    
 ,IPR.IsNotify=0  
 FROM ImportProjectRequest IPR   WITH (NOLOCK) 
 INNER JOIN @DistinctSectionTbl SM    
  ON IPR.TargetSectionId = SM.SectionId    
    
END
GO


