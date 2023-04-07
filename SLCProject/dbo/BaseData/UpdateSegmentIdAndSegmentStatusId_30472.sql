
DECLARE @ProjectId INT = 651;

--create temp table 
DROP TABLE IF EXISTS #ChoiceCodesInSegmnetDesc;
CREATE TABLE #ChoiceCodesInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, ChoiceCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

--Select Segmentsdescription which having Choices
SELECT PSSV.SectionId, PSSV.SegmentDescription,PSSV.ProjectId,PSSV.SegmentOrigin,
PSSV.CustomerId,PSSV.SegmentStatusId,PSSV.SegmentId ,PS.ModifiedBy, ROW_NUMBER() OVER(ORDER BY PSSV.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM ProjectSegmentStatusView PSSV WITH(NOLOCK) 
INNER JOIN ProjectSegment PS WITH(NOLOCK) ON
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
 
 --9  rows should affected
 UPDATE PSC SET PSC.SegmentStatusId= CCIS.SegmentStatusId,PSC.SegmentId=CCIS.SegmentId    
 FROM #ChoiceCodesInSegmnetDesc CCIS  INNER JOIN
 ProjectSegmentChoice PSC WITH(NOLOCK) ON PSC.SectionId=CCIS.SectionId AND CCIS.CustomerId=PSC.CustomerId
 AND CCIS.ProjectId=PSC.ProjectId AND CCIS.ChoiceCode=PSC.SegmentChoiceCode 
 WHERE PSC.CustomerId=1431
 