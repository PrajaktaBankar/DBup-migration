/* 
server name : SLCProject_SqlSlcOp005 
Customer Support 60568: SLC text prints with yellow highlight 
*/

DROP TABLE IF EXISTS #ProjectSegment
SELECT * INTO #ProjectSegment FROM ProjectSegment PS WITH(NOLOCK) 
WHERE CustomerId = 4156 AND SegmentDescription like '%<mark data-markjs="true">%'
OR SegmentDescription like '%<mark data-markjs="true" class="">%'
OR SegmentDescription like '%<mark data-markjs="true" class="currentMatch">%'
OR SegmentDescription like '%<mark class="currentMatch" data-markjs="true">%'

SELECT * 
into bpmcore_Staging_SLC..ProjectSegment4156
FROM #ProjectSegment

UPDATE PS
SET SegmentDescription = REPLACE(SegmentDescription,'<mark data-markjs="true">' ,'')
FROM #ProjectSegment PS
UPDATE PS
SET SegmentDescription = REPLACE(SegmentDescription,'<mark data-markjs="true" class="">' ,'')
FROM #ProjectSegment PS
UPDATE PS
SET SegmentDescription = REPLACE(SegmentDescription,'<mark data-markjs="true" class="currentMatch">' ,'')
FROM #ProjectSegment PS
UPDATE PS
SET SegmentDescription = REPLACE(SegmentDescription,'<mark class="currentMatch" data-markjs="true">' ,'')
FROM #ProjectSegment PS
UPDATE PS
SET SegmentDescription = REPLACE(SegmentDescription,'</mark>' ,'')
FROM #ProjectSegment PS

--SELECT * FROM #ProjectSegment

UPDATE PS
SET PS.SegmentDescription = TPS.SegmentDescription
FROM #ProjectSegment TPS INNER JOIN ProjectSegment PS WITH(NOLOCK)
ON TPS.SegmentStatusId = PS.SegmentStatusId AND TPS.SectionId = PS.SectionId


--SELECT p.ProjectId, p.[Name] as ProjectName, psec.SourceTag, psec.Author, pss.SequenceNumber, ps.SegmentDescription FROM #ProjectSegment ps
--	inner join dbo.ProjectSegmentStatus pss on pss.SegmentStatusId=ps.SegmentStatusId and ps.SectionId=pss.SectionId
--	inner join dbo.ProjectSection psec on psec.SectionId=pss.SectionId
--	inner join dbo.Project p on p.ProjectId=pss.ProjectId
--order by ProjectName, SourceTag, SequenceNumber

