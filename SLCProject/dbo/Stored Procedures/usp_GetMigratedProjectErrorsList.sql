CREATE PROCEDURE usp_GetMigratedProjectErrorsList
(@ProjectId INT, @CustomerId INT)
AS
BEGIN
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;

select
PME.MigrationExceptionId,
--CONCAT(PS.SourceTag, ':' ,PS.Author) AS Section,
--COALESCE(PS.[Description],'') AS SectionName,
CAST('' AS NVARCHAR(25)) AS Section,
CAST('' AS NVARCHAR(500)) AS SectionName,
CAST(0 AS INT) AS SequenceNumber,
PME.SegmentDescription as SegmentDescription1,
PME.SegmentStatusId,
PME.SectionId,
COALESCE(PME.BrokenPlaceHolderType,'NA') AS MissingEntities,
'' AS ProjectName,
ISNULL(PME.IsResolved,0) AS IsResolved,
CAST(0 AS BIT) AS HasCorruptSequenceNumbers,
0 AS SegmentId,
0 as mSegmentStatusId,
0 AS mSegmentId,
'' AS SegmentOrigin,
PME.ProjectId,
(CASE WHEN PATINDEX('%{RS#%', SegmentDescription) > 0 THEN 1
WHEN PATINDEX('%{RSTEMP#%', SegmentDescription) > 0 THEN 1
WHEN PATINDEX('%{GT#%', SegmentDescription) > 0 THEN 1
ELSE 0
END) as HasRSAndGTCodes,
(CASE WHEN PATINDEX('%{CH#%', SegmentDescription) > 0 THEN 1 ELSE 0 END) as HasCHCodes
into #errorList
from ProjectMigrationException PME WITH(NOLOCK)
WHERE PME.ProjectId = @PProjectId
AND PME.CustomerId = @PCustomerId
AND ISNULL(PME.IsResolved,0) = 0;

UPDATE e
set e.Section=CONCAT(PS.SourceTag, ':' ,PS.Author),
e.SectionName=COALESCE(PS.[Description],'')
from #errorList e INNER JOIN ProjectSection PS WITH(NOLOCK)
ON e.SectionId = PS.SectionId
AND e.ProjectId = PS.ProjectId
WHERE PS.ProjectId = @PProjectId
AND PS.CustomerId = @PCustomerId

-- set Sequence Number
update e
set e.SequenceNumber = CAST(PSS.SequenceNumber AS INT) ,
e.mSegmentId=ISNULL(pss.mSegmentId,0),
e.mSegmentStatusId=ISNULL(pss.mSegmentStatusId,0),
e.SegmentId=ISNULL(pss.SegmentId,0),
e.SegmentOrigin=pss.SegmentOrigin
from #errorList as e join ProjectSegmentStatus as PSS WITH(NOLOCK) ON
e.SectionId = PSS.SectionId and e.SegmentStatusId = PSS.SegmentStatusId
WHERE PSS.ProjectId = @PProjectId --AND e.SegmentStatusId IS NOT NULL;

-- set hasCorruptSequenceNumbers Flag
select DISTINCT SectionId, CAST(0 as BIT) AS HasCorruptSequenceNumbers into #seqNumIssue from #errorList;

update s
set HasCorruptSequenceNumbers = 1
from #seqNumIssue as s join ProjectSegmentStatus as pss WITH(NOLOCK) ON
s.SectionId = pss.SectionId and PSS.ProjectId = @ProjectId
WHERE PSS.ProjectId = @ProjectId and pss.SegmentId is null and SegmentSource= 'U';

update e
set e.HasCorruptSequenceNumbers = s.HasCorruptSequenceNumbers
from #errorList as e join #seqNumIssue as s WITH(NOLOCK) ON
e.SectionId = s.SectionId;

UPDATE t
SET t.segmentDescription1 = dbo.[fnGetSegmentDescriptionTextForChoice](t.SegmentStatusId)
FROM #errorList t
where HasCHCodes = 1

UPDATE t
SET t.segmentDescription1 = dbo.[fnGetSegmentDescriptionTextForRSAndGT](@ProjectId, @CustomerId, segmentDescription1)
FROM #errorList t
where HasRSAndGTCodes = 1


SELECT *,REPLACE(segmentDescription1,'{\rs\#', '{rs#') AS segmentDescription
from #errorList order by sectionId

END;