/*
 server name : SLCProject_SqlSlcOp002
 Customer Support 58921: SLC User Sees CH# Issue

*/

UPDATE PSC SET IsDeleted = 0 from ProjectSegmentChoice PSC WITH(NOLOCK) where SegmentStatusId = 453800879
UPDATE PCO SET IsDeleted = 0 from ProjectChoiceOption PCO WITH(NOLOCK) where SegmentChoiceId in (27417530,27417531)

UPDATE PN SET 
NoteText = 'FED-STD-101C was superseded by MIL-STD-3010 -&nbsp;Test Procedures for Packaging Materials and Container. ~Rondi Werner 3/29/2021'
FROM ProjectNote PN WITH(NOLOCK) where segmentstatusId = 9896908

DROP TABLE IF EXISTS #ProjectSegment
SELECT * INTO #ProjectSegment FROM ProjectSegment PS WITH(NOLOCK)
WHERE CustomerId = 260 AND SegmentDescription like '%<mark data-markjs="true">%'
OR SegmentDescription like '%<mark data-markjs="true" class="">%'
OR SegmentDescription like '%<mark data-markjs="true" class="currentMatch">%'
OR SegmentDescription like '%<mark class="currentMatch" data-markjs="true">%'

SELECT * 
into bpmcore_Staging_SLC..ProjectSegment260
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


DROP TABLE IF EXISTS #CorrectProjectSegmentParagraphs	
select distinct ps.ProjectId, ps.SourceTag, ps.Author, pv.SequenceNumber, pv.SegmentDescription, 'ProjectSegment' as [Table_Name]
into #CorrectProjectSegmentParagraphs
from #ProjectSegment tsco
inner join ProjectSegmentStatusView WITH(NOLOCK) pv on pv.SectionId=tsco.SectionId and pv.SegmentStatusId=tsco.SegmentStatusId and pv.SegmentId=tsco.SegmentId
inner join ProjectSection WITH(NOLOCK) ps on ps.SectionId=tsco.SectionId
where isnull(ps.IsDeleted, 0)=0

--select * from bpmcore_Staging_SLC..ProjectSegment1362
select * from #CorrectProjectSegmentParagraphs
