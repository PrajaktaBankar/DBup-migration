 
DECLARE @ProjectId INT = 4827
--create temp table 
DROP TABLE IF EXISTS #HyperlinkCodeInSegmnetDesc;
CREATE TABLE #HyperlinkCodeInSegmnetDesc (ProjectId INT, SectionId INT,CustomerId INT, HyperLinkCode INT,SegmentStatusId int,SegmentId int,ModifiedBy INT);
DROP TABLE IF EXISTS #TempProjectSegmentStatusView;

 
SELECT PS.SectionId, PS.SegmentDescription,PS.ProjectId,PS.SegmentSource,
PS.CustomerId,PS.SegmentStatusId,PS.SegmentId ,PS.ModifiedBy, ROW_NUMBER() OVER(ORDER BY PS.SegmentStatusId ASC) AS RowId
INTO #TempProjectSegmentStatusView
FROM  ProjectSegmentStatusView PSS WITH(NOLOCK) INNER JOIN ProjectSegment PS WITH(NOLOCK) ON
PS.SectionId=PSS.SectionId and PS.ProjectId=PSS.ProjectId and PS.CustomerId=PSS.CustomerId 
and PS.SegmentId=PSS.SegmentId and PS.SegmentStatusId=PSS.SegmentStatusId
WHERE PS.ProjectId = @ProjectId AND PS.SegmentSource='U' AND
ISNULL(PS.IsDeleted,0)=0  AND  PS.SegmentDescription LIKE '%{HL#%'

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

INSERT INTO #HyperlinkCodeInSegmnetDesc(ProjectId,SectionId,CustomerId,HyperLinkCode,SegmentStatusId,SegmentId,ModifiedBy)
SELECT @ProjectId AS ProjectId, @SectionId AS SectionId,@CustomerId as CustomerId,Ids,@SegmentStatusId AS SegmentStatusId,@SegmentId AS SegmentId ,@ModifiedBy as ModifiedBy
FROM [dbo].[fn_GetIdSegmentDescription](@SegmentDescription,'{HL#')

SET @LoopCount = @LoopCount - 1;
 
END
  
DROP TABLE IF exists #HyperlinkCodeInSegmnetDesc1

SELECT CCIS.* INTO #HyperlinkCodeInSegmnetDesc1
FROM #HyperlinkCodeInSegmnetDesc CCIS 
LEFT OUTER JOIN ProjectHyperLink TPSCO WITH(NOLOCK)
ON TPSCO.HyperLinkId = CCIS.HyperLinkCode and TPSCO.ProjectId=CCIS.ProjectId and CCIS.CustomerId=TPSCO.CustomerId
AND CCIS.SectionId=TPSCO.SectionId AND  CCIS.SegmentId=TPSCO.SegmentId and CCIS.SegmentStatusId =TPSCO.SegmentStatusId
WHERE TPSCO.HyperLinkId IS NULL 

INSERT INTO ProjectHyperLink
SELECT
hlcisd.SectionId	,hlcisd.SegmentId	,hlcisd.SegmentStatusId	,hlcisd.ProjectId	,hlcisd.CustomerId	,phl.LinkTarget	,phl.LinkText	,phl.LuHyperLinkSourceTypeId	,phl.CreateDate	,phl.CreatedBy	,phl.ModifiedDate	,phl.ModifiedBy	,phl.SLE_DocID	,phl.SLE_SegmentID	,phl.SLE_StatusID	,phl.SLE_LinkNo	,phl.HyperLinkId AS A_HyperLinkId
 FROM ProjectHyperLink phl WITH(NOLOCK) INNER JOIN 
 #HyperlinkCodeInSegmnetDesc1 hlcisd WITH(NOLOCK) ON
phl.HyperLinkId=hlcisd.HyperLinkCode
WHERE phl.ProjectId=3706

UPDATE ps SET ps.SegmentDescription=REPLACE(ps.SegmentDescription,'{HL#'+cast(phl.A_HyperLinkId AS NVARCHAR(50) )+ '}','{HL#'+cast(phl.HyperLinkId AS nvarchar(50) )+ '}')
 FROM #HyperlinkCodeInSegmnetDesc1 hlcisd  INNER JOIN ProjectHyperLink phl WITH(NOLOCK) ON
phl.A_HyperLinkId=hlcisd.HyperLinkCode INNER JOIN ProjectSegment ps WITH(NOLOCK) ON
ps.SectionId=phl.SectionId and phl.ProjectId=ps.ProjectId and phl.CustomerId=ps.CustomerId and phl.SegmentId=ps.SegmentId
and phl.SegmentStatusId=ps.SegmentStatusId 

UPDATE phl set phl.A_HyperLinkId=null FROM #HyperlinkCodeInSegmnetDesc1 hlcisd INNER JOIN ProjectHyperLink phl WITH(NOLOCK) ON
phl.A_HyperLinkId=hlcisd.HyperLinkCode INNER JOIN ProjectSegment ps WITH(NOLOCK) ON
ps.SectionId=phl.SectionId and phl.ProjectId=ps.ProjectId and phl.CustomerId=ps.CustomerId and phl.SegmentId=ps.SegmentId
and phl.SegmentStatusId=ps.SegmentStatusId 

DROP TABLE IF EXISTS #HyperlinkCodeInSegmnetDesc1