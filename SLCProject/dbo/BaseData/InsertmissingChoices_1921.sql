--Execute it on server 3
--Customer Support 30405: CH# - Steven Moore with MGMA - 10272

DECLARE @ProjectId INT = 1921;

--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Select Segmentsdescription which having Choices
SELECT PSSV.SectionId, PSSV.SegmentDescription,PSSV.ProjectId,PSSV.SegmentOrigin,
PSSV.CustomerId,PSSV.SegmentStatusId,PSSV.SegmentId ,PS.ModifiedBy, ROW_NUMBER() OVER(ORDER BY PSSV.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH(NOLOCK) 
INNER JOIN ProjectSegment PS WITH(NOLOCK)  ON 
 PS.SegmentStatusId=PSSV.SegmentStatusId AND PS.SegmentId=PSSV.SegmentId
 and PS.ProjectId=PSSV.ProjectId
WHERE PSSV.ProjectId = @ProjectId AND
ISNULL(PSSV.IsDeleted,0)=0 AND PSSV.SegmentOrigin='U' 
AND PSSV.SegmentSource='M' AND PSSV.SegmentDescription LIKE '%{CH#%'

--Insert choices data in ProjectSegmentChoice temp table for Project 
DROP TABLE IF EXISTS #TempProjectSegmentChoice;
SELECT * INTO #TempProjectSegmentChoice 
FROM ProjectSegmentChoice PSC WITH(NOLOCK)
WHERE PSC.ProjectId = @ProjectId
AND PSC.SegmentChoiceSource ='U'

--Insert choices data in ProjectChoiceOption temp table for Project 
DROP TABLE IF EXISTS #TempProjectChoiceOption;
SELECT * INTO #TempProjectChoiceOption 
FROM ProjectChoiceOption PCO WITH(NOLOCK)
WHERE PCO.ProjectId = @ProjectId
AND PCO.ChoiceOptionSource='U'

--Insert choices data in SelectedChoiceOption temp table for Project 
DROP TABLE IF EXISTS #TempProjectSelectedChoiceOption;
SELECT * INTO #TempProjectSelectedChoiceOption 
FROM SelectedChoiceOption SCO WITH(NOLOCK)
 WHERE SCO.ProjectId = @ProjectId
 AND SCO.ChoiceOptionSource='U'

 --Fetch choice code from SegmentDescription
DECLARE @LoopCount INT = (SELECT COUNT(1) AS TotalRows FROM #TempProjectSegmentStatusView)

DECLARE @SegmentDescription NVARCHAR(MAX) = '';
DECLARE @SectionId INT = 0;
DECLARE @CustomerId INT = 0;
DECLARE @SegmentStatusId INT = 0;
DECLARE @SegmentId INT = 0;
DECLARE @ModifiedBy INT = 0;
WHILE @LoopCount > 0
BEGIN
SELECT @SegmentDescription = TPSSV.SegmentDescription, @SectionId = TPSSV.SectionId ,
@CustomerId =TPSSV.CustomerId,@SegmentStatusId=TPSSV.SegmentStatusId ,@SegmentId=TPSSV.SegmentId,
@ModifiedBy =TPSSV.ModifiedBy

FROM #TempProjectSegmentStatusView TPSSV WHERE RowId = @LoopCount;

INSERT INTO #ChoiceCodesInSegmnetDesc(ProjectId,SectionId,CustomerId,ChoiceCode,SegmentStatusId,SegmentId,ModifiedBy)
SELECT @ProjectId AS ProjectId, @SectionId AS SectionId,@CustomerId as CustomerId,Ids,@SegmentStatusId AS SegmentStatusId,@SegmentId AS SegmentId ,@ModifiedBy as ModifiedBy
FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription,'{CH#')

SET @LoopCount = @LoopCount - 1;
END;

--Filter missing choices data from #TempProjectSegmentChoice
drop table if exists #TempProjectSegmentChoice1

SELECT CCIS.ProjectId,CCIS.SectionId,CCIS.ChoiceCode ,CCIS.CustomerId,
CCIS.SegmentStatusId,CCIS.SegmentId,CCIS.ModifiedBy into #TempProjectSegmentChoice1
FROM #ChoiceCodesInSegmnetDesc CCIS 
LEFT OUTER JOIN #TempProjectSegmentChoice TPSCO 
ON TPSCO.SegmentChoiceCode = CCIS.ChoiceCode and TPSCO.ProjectId=CCIS.ProjectId
and CCIS.SectionId=TPSCO.SectionId
WHERE TPSCO.SegmentChoiceCode IS NULL 



--Filter missing choices data from #TempProjectChoiceOption1

DROP TABLE IF EXISTS  #TempProjectChoiceOption1

 SELECT SLCMCO.* INTO  #TempProjectChoiceOption1 FROM 
 #TempProjectSegmentChoice1 tblins    
 INNER JOIN SLCMaster..SegmentChoice SC WITH(NOLOCK) ON SC.SegmentChoiceCode=tblins.ChoiceCode  
 INNER JOIN SLCMaster..ChoiceOption SLCMCO WITH(NOLOCK) ON  SC.SegmentChoiceId=SLCMCO.SegmentChoiceId
 LEFT OUTER JOIN ProjectChoiceOption PCO WITH(NOLOCK) ON PCO.ChoiceOptionCode=SLCMCO.ChoiceOptionCode AND
 tblins.ProjectId =PCO.ProjectId AND tblins.SectionId=PCO.SectionId
 WHERE  
 SC.SegmentChoiceId=SLCMCO.SegmentChoiceId 

--Filter missing choices data from ##TempProjectSelectedChoiceOption

drop table if exists #TempProjectSelectedChoiceOption1
SELECT CCIS.ProjectId,CCIS.SectionId,CCIS.ChoiceCode ,CCIS.CustomerId,
CCIS.SegmentStatusId,CCIS.SegmentId,CCIS.ModifiedBy into #TempProjectSelectedChoiceOption1
FROM #ChoiceCodesInSegmnetDesc CCIS 
LEFT OUTER JOIN #TempProjectSelectedChoiceOption TPSCO 
ON TPSCO.SegmentChoiceCode = CCIS.ChoiceCode and TPSCO.ProjectId=CCIS.ProjectId
and CCIS.SectionId=TPSCO.SectionId
WHERE TPSCO.SegmentChoiceCode IS NULL 

--if missing data is present in filtered table then insert into original table from SLCMaster
--(7 rows affected)

IF((select count(1) #TempProjectSegmentChoice1)>0)
BEGIN
INSERT INTO ProjectSegmentChoice
SELECT 
 tblins.SectionId	
,tblins.SegmentStatusId	
,tblins.SegmentId	
,SMSC.ChoiceTypeId	 
,tblins.ProjectId	
,tblins.CustomerId	
,'U' AS SegmentChoiceSource
,tblins.ChoiceCode	
,tblins.ModifiedBy	
,GETUTCDATE() AS CreateDate
,NULL AS ModifiedBy	
,NULL	AS ModifiedDate
,NULL AS SLE_DocID	
,NULL AS  SLE_SegmentID
,NULL AS SLE_StatusID	
,NULL AS SLE_ChoiceNo	
,SMSC.ChoiceTypeId
,null AS A_SegmentChoiceId
,0 AS IsDeleted

 FROM SLCMaster..SegmentChoice SMSC WITH (NOLOCK) inner join 
#TempProjectSegmentChoice1 tblins on tblins.ChoiceCode=SMSC.SegmentChoiceCode
 WHERE tblins.ChoiceCode=SMSC.SegmentChoiceCode
 END
 
--if missing data is present in filtered table then insert into original table from SLCMaster
--(12 rows affected)

  if((select count(1) FROM #TempProjectChoiceOption1)>0)
  BEGIN
 INSERT INTO ProjectChoiceOption
 SELECT 
 PSC.SegmentChoiceId	
,SC.SortOrder	
,'U' AS ChoiceOptionSource
,SC.OptionJson	
,PSC.ProjectId	
,PSC.SectionId	
,PSC.CustomerId	
,SC.ChoiceOptionCode	
,PSC.CreatedBy	
,GETUTCDATE() AS CreateDate
,PSC.CreatedBy		
,NULL AS ModifiedDate
,NULL AS A_ChoiceOptionId
,0 AS IsDeleted
 FROM ProjectSegmentChoice PSC WITH(NOLOCK) INNER JOIN
 #TempProjectSegmentChoice1 tblins  on tblins.ChoiceCode=PSC.SegmentChoiceCode 
 AND PSC.ProjectId=tblins.ProjectId AND PSC.SectionId=tblins.SectionId 
 INNER JOIN SLCMaster..SegmentChoice SLCSC WITH(NOLOCK)  ON tblins.ChoiceCode=SLCSC.SegmentChoiceCode 
 INNER JOIN #TempProjectChoiceOption1 SC WITH(NOLOCK) ON SC.SegmentChoiceId=SLCSC.SegmentChoiceId  
 WHERE tblins.ChoiceCode=PSC.SegmentChoiceCode 
 AND PSC.ProjectId=tblins.ProjectId AND PSC.SectionId=tblins.SectionId  

 END


--if missing data is present in filtered table then insert into original table from SLCMaster
--(12 rows affected)
IF((select count(1) #TempProjectSelectedChoiceOption1)>0)
BEGIN
INSERT INTO SelectedChoiceOption
SELECT 
tblins.ChoiceCode, 
SCO.ChoiceOptionCode, 
'U' AS ChoiceOptionSource,
SCO.IsSelected, 
tblins.SectionId, 
tblins.ProjectId,
tblins.CustomerId AS CustomerId,NULL AS OptionJson,0 AS IsDeleted
 FROM SLCMaster..SelectedChoiceOption SCO WITH (NOLOCK) INNER JOIN
#TempProjectSelectedChoiceOption1 tblins on tblins.ChoiceCode=SCO.SegmentChoiceCode
 WHERE tblins.ChoiceCode=SCO.SegmentChoiceCode   
 END
 
 