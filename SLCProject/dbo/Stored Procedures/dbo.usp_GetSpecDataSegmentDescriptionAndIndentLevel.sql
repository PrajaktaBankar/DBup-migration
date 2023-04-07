CREATE PROCEDURE [dbo].[usp_GetSpecDataSegmentDescriptionAndIndentLevel] 
(                        
@NoteDataString nvarchar(max),  
@MultipleProductTableJson nvarchar(max)  
)                        
AS      
         
BEGIN  
    
declare @RowTable Table(        
        
CustomerId INT ,        
SectionId INT ,        
SegmentStatusId BIGINT ,        
SegmentId BIGINT,        
ProjectId INT ,        
IndentLevel INT ,        
SegmentDescription NVARCHAR(MAX) ,        
ParentSegmentStatusId BIGINT ,        
SequenceNumber DECIMAL(18, 4) ,        
ProductId INT ,        
ActionTypeId INT ,        
OptionJson nvarchar(max),        
SegmentChoiceId BIGINT ,        
ChoiceOptionId BIGINT       ,  
MultipleProductConditionalRuleId int,    
MaxSegmentStatusId BIGINT  default 0 ,   
MaxSequenceNumber decimal(18,4)   ,   
PreviousProductPrefix  NVARCHAR(20)   ,   
ProductPrefix  NVARCHAR(20) ,
ProductCount int   
            
  
)  
  
DROP TABLE IF EXISTS #tempp1, #InputTable  
SELECT DISTINCT  
 * INTO #InputTable  
FROM OPENJSON(@NoteDataString) WITH (  
CustomerId INT '$.CustomerId',  
SectionId INT '$.SectionId',  
ProjectId INT '$.ProjectId',  
ProductId INT '$.ProductId' ,
ProductCount INT '$.ProductCount'  
)  
  
SELECT DISTINCT  
 * INTO #MultipleProductConditionalRuleInputTable  
FROM OPENJSON(@MultipleProductTableJson) WITH (  
CustomerId INT '$.CustomerId',  
SectionId INT '$.SectionId',  
MultipleProductConditionalRuleId INT '$.MultipleProductConditionalRuleId',  
SegmentStatusId BIGINT '$.SegmentStatusId',  
SequenceNumber NVARCHAR(20) '$.SequenceNumber',  
PreviousProductPrefix NVARCHAR(20) '$.PreviousProductPrefix',  
ProductPrefix NVARCHAR(20) '$.ProductPrefix'


  
)  
  
  
DROP TABLE IF EXISTS #SectionTBL  
  
SELECT DISTINCT  
 ps.mSectionId  
   ,ps.ProjectId  
   ,Ps.CustomerId  
   ,ps.SectionId INTO #SectionTBL  
FROM #InputTable tmp  
INNER JOIN ProjectSection ps WITH (NOLOCK)  
 ON ps.mSectionId = tmp.SectionId  
  AND tmp.ProjectId = ps.ProjectId  
  AND tmp.CustomerId = ps.CustomerId  
  
  
DECLARE @SegmentStatusSectionMultipleProduct TABLE (  
 SegmentStatusId BIGINT  
   ,mSectionId INT  
  
)  
  
  
DROP TABLE IF EXISTS #TempSegmentChoice  
  
SELECT  
 sc.SectionId  
   ,sc.SegmentStatusId  
   ,sc.SegmentId  
   ,sc.SegmentChoiceId  
   ,sc.SegmentChoiceCode INTO #TempSegmentChoice  
FROM SLCMaster..SegmentChoice sc WITH (NOLOCK)  
INNER JOIN #SectionTBL st  
 ON st.mSectionId = sc.SectionId  
  
  
SELECT DISTINCT  
 pssv.CustomerId  
   ,pssv.mSectionId AS SectionId  
   ,pssv.mSegmentStatusId AS SegmentStatusId  
   ,pssv.mSegmentId AS SegmentId  
   ,pssv.ProjectId  
   ,pssv.IndentLevel  
   ,pssv.SegmentDescription  
   ,CONVERT(BIGINT,pssv.ParentSegmentStatusId)as ParentSegmentStatusId  
   ,pssv.SequenceNumber  
   ,1 AS ActionTypeId  
   ,NULL AS OptionJson  
   ,NULL AS SegmentChoiceId  
   ,NULL AS ChoiceOptionId  
   ,mpcr.MultipleProductConditionalRuleId  
   ,mpcr.PreviousProductPrefix  
   ,mpcr.ProductPrefix 
  
     INTO #TempProjectSegmentStatusView  
FROM #SectionTBL inp  
INNER JOIN ProjectSegmentStatusView pssv WITH (NOLOCK)  
 ON pssv.SectionId = inp.SectionId  
INNER JOIN #MultipleProductConditionalRuleInputTable mpcr  
 ON pssv.mSegmentStatusId = mpcr.SegmentStatusId  
  AND pssv.ProjectId = inp.ProjectId  
  AND pssv.CustomerId = inp.CustomerId  
  
  
SELECT  
 pssv.CustomerId  
   ,pssv.SectionId  
   ,pssv.SegmentStatusId  
   ,pssv.SegmentId  
   ,pssv.ProjectId  
   ,pssv.IndentLevel  
   ,pssv.SegmentDescription  
   ,pssv.ParentSegmentStatusId  
   ,pssv.SequenceNumber  
   ,inp.ProductId  
   ,1 AS ActionTypeId  
   ,NULL AS OptionJson  
   ,NULL AS SegmentChoiceId  
   ,NULL AS ChoiceOptionId  
   ,pssv.MultipleProductConditionalRuleId  
   ,pssv.PreviousProductPrefix  
   ,pssv.ProductPrefix 
   ,inp.ProductCount
   INTO #TempProjectSegmentStatusResult  
FROM #TempProjectSegmentStatusView pssv  
INNER JOIN #InputTable inp  
 ON inp.SectionId = pssv.SectionId  
ORDER BY SectionId, ProductId, SequenceNumber  
  

INSERT INTO @RowTable (CustomerId,  
SectionId,  
SegmentStatusId,  
SegmentId,  
ProjectId,  
IndentLevel,  
SegmentDescription,  
ParentSegmentStatusId,  
SequenceNumber,  
ProductId,  
ActionTypeId,  
OptionJson,  
SegmentChoiceId,  
ChoiceOptionId,  
MultipleProductConditionalRuleId,  
PreviousProductPrefix,  
ProductPrefix, ProductCount)  
 SELECT DISTINCT  
  pssv.CustomerId  
    ,pssv.SectionId  
    ,pssv.SegmentStatusId  
    ,pssv.SegmentId  
    ,pssv.ProjectId  
    ,pssv.IndentLevel  
    ,pssv.SegmentDescription  
    ,pssv.ParentSegmentStatusId  
    ,pssv.SequenceNumber  
    ,pssv.ProductId  
    ,1 AS ActionTypeId  
    ,NULL AS OptionJson  
    ,NULL AS SegmentChoiceId  
    ,NULL AS ChoiceOptionId  
    ,pssv.MultipleProductConditionalRuleId  
    ,pssv.PreviousProductPrefix  
    ,pssv.ProductPrefix  
	 ,pssv.ProductCount
 FROM #TempProjectSegmentStatusResult pssv  
 ORDER BY SectionId, ProductId, SequenceNumber  
  
INSERT INTO @RowTable (CustomerId,  
SectionId,  
SegmentStatusId,  
SegmentId,  
ProjectId,  
IndentLevel,  
SegmentDescription,  
ParentSegmentStatusId,  
SequenceNumber,  
ProductId,  
ActionTypeId,  
OptionJson,  
SegmentChoiceId,  
ChoiceOptionId,  
MultipleProductConditionalRuleId,  
PreviousProductPrefix,  
ProductPrefix ,ProductCount)  
 SELECT DISTINCT  
  pssv.CustomerId  
    ,pssv.SectionId  
    ,pssv.SegmentStatusId  
    ,pssv.SegmentId  
    ,pssv.ProjectId  
    ,pssv.IndentLevel  
    ,pssv.SegmentDescription  
    ,pssv.ParentSegmentStatusId  
    ,pssv.SequenceNumber  
    ,pssv.ProductId  
    ,3 AS ActionTypeId  
    ,co.OptionJson  
    ,sc.SegmentChoiceId  
    ,co.ChoiceOptionId  
    ,pssv.MultipleProductConditionalRuleId  
    ,pssv.PreviousProductPrefix  
    ,pssv.ProductPrefix  
	 ,pssv.ProductCount
 FROM #TempProjectSegmentStatusResult pssv  
 INNER JOIN SLCMaster..SegmentStatus ss WITH (NOLOCK)  
  ON ss.SegmentStatusId = pssv.SegmentStatusId  
   AND ss.SegmentId = pssv.SegmentId  
 INNER JOIN #TempSegmentChoice sc  
  ON ss.SectionId = sc.SectionId  
   AND ss.SegmentStatusId = sc.SegmentStatusId  
   AND ss.SegmentId = sc.SegmentId  
 INNER JOIN SLCMaster..ChoiceOption co WITH (NOLOCK)  
  ON co.SegmentChoiceId = sc.SegmentChoiceId  
 INNER JOIN SLCMaster..SelectedChoiceOption sco WITH (NOLOCK)  
  ON sco.SectionId = sc.SectionId  
   AND sco.SegmentChoiceCode = sc.SegmentChoiceCode  
   AND sco.ChoiceOptionCode = co.ChoiceOptionCode  
   AND sco.IsSelected = 1  
   AND ISNULL(ss.IsDeleted, 0) = 0  
 ORDER BY SectionId, ProductId, SequenceNumber  
  
 DROP TABLE IF EXISTS #MaxSequenceNumberTemptable  
  
SELECT  
 MAX(CAST(SequenceNumber AS DECIMAL(18, 4))) AS MaxSequenceNumber  
   ,MultipleProductConditionalRuleId INTO #MaxSequenceNumberTemptable  
FROM #MultipleProductConditionalRuleInputTable  
GROUP BY MultipleProductConditionalRuleId  
  
UPDATE RT  
SET RT.MaxSegmentStatusId = mpcrt.SegmentStatusId  
   ,RT.MaxSequenceNumber =CAST(msnt.MaxSequenceNumber AS DECIMAL(18,4))  
FROM #MaxSequenceNumberTemptable msnt  
INNER JOIN #MultipleProductConditionalRuleInputTable mpcrt  
 ON msnt.MultipleProductConditionalRuleId = mpcrt.MultipleProductConditionalRuleId  
 AND CAST(mpcrt.SequenceNumber AS DECIMAL(18, 4)) = CAST(msnt.MaxSequenceNumber AS DECIMAL(18, 4))  
INNER JOIN @RowTable RT  
 ON RT.MultipleProductConditionalRuleId = mpcrt.MultipleProductConditionalRuleId  
  
SELECT DISTINCT  
 *  
FROM @RowTable  
ORDER BY SectionId, ProductId, ProductCount,SequenceNumber  
  
END  
GO


