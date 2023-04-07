/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 55389: SLC - Barton Malow #15 - Blue Highlight Remains in Document after Find & Replace Is Used
 
*/

DROP TABLE IF EXISTS #ProjectSegment
SELECT * INTO #ProjectSegment FROM ProjectSegment PS WITH(NOLOCK)
WHERE CustomerId = 3155 AND SegmentDescription like '%<mark data-markjs="true">%'
OR SegmentDescription like '%<mark data-markjs="true" class="">%'
OR SegmentDescription like '%<mark data-markjs="true" class="currentMatch">%'
OR SegmentDescription like '%<mark class="currentMatch" data-markjs="true">%'

SELECT * 
into bpmcore_Staging_SLC..ProjectSegment3155
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
