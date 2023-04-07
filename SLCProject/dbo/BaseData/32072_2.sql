
USE SLCProject
Go

---Customer Support 32072: Customer has multiple corrupt Reference Standards (RS#) (Grimm & Parker)
---Execute On server 3

 DECLARE   @SectionId int =0,
           @SegmentStatusId int =0,
           @SegmentId int =0,
           @ProjectId int =0,
           @CustomerId int =0,
           @mSectionId int =0,
		   @SegmentDescription nvarchar(max),
		   @ModifiedBy int=0,
		   @ModifiedDate  datetime2

DROP TABLE IF EXISTS #TempReferenceStandard
DROP TABLE IF EXISTS #RSCodesInSegmnetDesc

create table #RSCodesInSegmnetDesc(SectionId int,
 SegmentStatusId int,
 SegmentId int,
 ProjectId int,
 CustomerId int,
 mSectionId int,
 RSCode int,
 ModifiedBy  int,
 ModifiedDate  datetime2
 )

SELECT
	pssv.SectionId
   ,ps.SegmentStatusId
   ,pssv.SegmentId
   ,pssv.ProjectId
   ,pssv.CustomerId
   ,mSectionId
   ,ps.SegmentDescription
   ,ps.CreatedBy
   ,ps.CreateDate
   ,ROW_NUMBER() OVER (PARTITION BY pssv.CustomerId ORDER BY pssv.CustomerId) AS RowNo 
   INTO #TempReferenceStandard
FROM ProjectSegmentStatusView pssv WITH(NOLOCK)
LEFT OUTER JOIN ProjectSegmentReferenceStandard psrs WITH(NOLOCK)
	ON psrs.SectionId = pssv.SectionId
		AND psrs.ProjectId = pssv.ProjectId
		AND psrs.SegmentId = pssv.SegmentId
		AND psrs.CustomerId = pssv.CustomerId
INNER JOIN ProjectSegment ps WITH(NOLOCK)
	ON ps.SegmentId = pssv.SegmentId
		AND ps.SegmentStatusId = pssv.SegmentStatusId
		AND ps.SectionId = pssv.SectionId
		AND ps.ProjectId = pssv.ProjectId
		AND ps.CustomerId = pssv.CustomerId
WHERE ps.SegmentDescription LIKE '%{RS%'
AND pssv.CustomerId = 783
AND pssv.ProjectId = 4729
AND ps.SegmentDescription NOT LIKE '%{RSTEMP%'
AND ps.SegmentSource = 'U'
AND psrs.SegmentId IS NULL

DECLARE @RowCount int=( SELECT
		COUNT(*)
	FROM #TempReferenceStandard)

 WHILE(@RowCount>0)
 begin
SELECT TOP 1
	@SectionId = SectionId
   ,@SegmentStatusId = SegmentStatusId
   ,@SegmentId = SegmentId
   ,@ProjectId = ProjectId
   ,@CustomerId = CustomerId
   ,@mSectionId = mSectionId
   ,@SegmentDescription = SegmentDescription
   ,@ModifiedBy = CreatedBy
   ,@ModifiedDate = CreateDate
FROM #TempReferenceStandard
WHERE RowNo = @RowCount


INSERT INTO #RSCodesInSegmnetDesc (SectionId,
SegmentStatusId,
SegmentId,
ProjectId,
CustomerId,
mSectionId,
ModifiedDate,
ModifiedBy,
RSCode)
	SELECT
		@SectionId AS SectionId
	   ,@SegmentStatusId AS SegmentStatusId
	   ,@SegmentId AS SegmentId
	   ,@ProjectId AS ProjectId
	   ,@CustomerId AS CustomerId
	   ,@mSectionId AS mSectionId
	   ,@ModifiedDate AS ModifiedDate
	   ,@ModifiedBy AS ModifiedBy
	   ,Ids
	FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription, '{RS#')

SET @RowCount = @RowCount - 1;
print @RowCount

END;

INSERT INTO ProjectSegmentReferenceStandard
SELECT
	rscis.SectionId
   ,rscis.SegmentId
   ,rscis.RSCode
   ,'M' AS RefStandardSource
   ,rscis.RSCode
   ,rscis.ModifiedDate AS CreateDate
   ,rscis.ModifiedBy AS CreatedBy
   ,rscis.ModifiedDate AS ModifiedDate
   ,rscis.ModifiedBy AS  ModifiedBy
   ,0 AS mSegmentId
   ,ProjectId
   ,CustomerId
   ,rscis.RSCode
   ,0 AS IsDeleted
FROM #RSCodesInSegmnetDesc rscis 

   