---Customer Support 59529: Data issue - DGA - Royce Nicolas with Mountain View - 40387
--Server 4 

--1st issue resolve
DROP TABLE IF EXISTS #tempChiceTable

SELECT
	0 AS SegmentChoiceId
   ,SectionId
   ,1170442885 AS SegmentStatusId
   ,198292622 AS SegmentId
   ,ChoiceTypeId
   ,ProjectId
   ,CustomerId
   ,SegmentChoiceSource
   ,CreatedBy
   ,CreateDate
   ,IsDeleted
   ,SegmentChoiceCode AS A_SegmentChoiceId INTO #tempChiceTable
FROM ProjectSegmentChoice WITH (NOLOCK)
WHERE SegmentStatusId = 1108630222
AND SectionId = 21629253
AND ProjectId = 16238


INSERT INTO ProjectSegmentChoice (SectionId, SegmentStatusId, SegmentId, ChoiceTypeId, ProjectId, CustomerId, SegmentChoiceSource, CreatedBy, CreateDate, IsDeleted, A_SegmentChoiceId)
	SELECT

		SectionId
	   ,SegmentStatusId
	   ,SegmentId
	   ,ChoiceTypeId
	   ,ProjectId
	   ,CustomerId
	   ,SegmentChoiceSource
	   ,CreatedBy
	   ,CreateDate
	   ,IsDeleted
	   ,A_SegmentChoiceId

	FROM #tempChiceTable



SELECT

	psc.SegmentChoiceId
   ,co.SortOrder
   ,'U' AS ChoiceOptionSource
   ,OptionJson
   ,psc.ProjectId
   ,psc.SectionId
   ,psc.CustomerId
   ,ChoiceOptionCode
   ,psc.CreatedBy
   ,psc.CreateDate
   ,co.ChoiceOptionId AS A_ChoiceOptionId
   ,0 AS IsDeleted INTO #TempProjectChoiceOptionTable
FROM #tempChiceTable tp
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
	ON tp.SectionId = psc.SectionId 
		AND tp.ProjectId = psc.ProjectId
		AND tp.A_SegmentChoiceId = psc.A_SegmentChoiceId
INNER JOIN SLCMaster..ChoiceOption co WITH (NOLOCK)
	ON tp.A_SegmentChoiceId = co.SegmentChoiceId


INSERT INTO ProjectChoiceOption (SegmentChoiceId, SortOrder, ChoiceOptionSource, OptionJson, ProjectId, SectionId, CustomerId, CreatedBy, CreateDate, A_ChoiceOptionId, IsDeleted)
	SELECT

		SegmentChoiceId
	   ,SortOrder
	   ,'U' AS ChoiceOptionSource
	   ,OptionJson
	   ,ProjectId
	   ,SectionId
	   ,CustomerId
	   ,CreatedBy
	   ,CreateDate
	   ,A_ChoiceOptionId
	   ,IsDeleted
	FROM #TempProjectChoiceOptionTable


INSERT INTO SelectedChoiceOption
	SELECT
		psc.SegmentChoiceCode
	   ,pco.ChoiceOptionCode
	   ,'U' AS ChoiceOptionSource
	   ,sco.IsSelected
	   ,psc.SectionId
	   ,psc.ProjectId
	   ,psc.CustomerId
	   ,NULL
	   ,0 AS IsDeleted

	FROM #TempProjectChoiceOptionTable tpc
	INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
		ON tpc.SegmentChoiceId = pco.SegmentChoiceId
			AND tpc.A_ChoiceOptionId = pco.A_ChoiceOptionId
	INNER JOIN SelectedChoiceOption sco WITH (NOLOCK)
		ON sco.ChoiceOptionCode = tpc.A_ChoiceOptionId
			AND tpc.ProjectId = sco.ProjectId
			AND tpc.SectionId = sco.SectionId
			AND sco.ChoiceOptionSource = 'M'
	INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
		ON tpc.SegmentChoiceId = psc.SegmentChoiceId


DROP TABLE IF EXISTS #TempProjectSegmentTable

SELECT DISTINCT
	ps.SegmentDescription
   ,psc.SegmentChoiceCode
   ,psc.SegmentStatusId
   ,psc.SegmentId
   ,psc.ProjectId
   ,psc.SectionId
   ,psc.CustomerId
   ,psc.A_SegmentChoiceId INTO #TempProjectSegmentTable
FROM ProjectSegment ps WITH (NOLOCK)
INNER JOIN #tempChiceTable tct
	ON tct.ProjectId = ps.ProjectId
		AND ps.SectionId = tct.SectionId
		AND ps.SegmentDescription LIKE '%{CH#' + CAST(tct.A_SegmentChoiceId AS NVARCHAR(100)) + '}%'
		AND ps.SegmentStatusId = 1108630222
INNER JOIN ProjectSegmentChoice psc WITH (NOLOCK)
	ON tct.A_SegmentChoiceId = psc.A_SegmentChoiceId
		AND psc.ProjectId = tct.ProjectId
		AND psc.SegmentStatusId = tct.SegmentStatusId

DROP TABLE IF EXISTS #finalDescription
SELECT TOP 1
	* INTO #finalDescription
FROM #TempProjectSegmentTable
 

 DECLARE @i int=1;
 WHILE(@i<= 3)
 BEGIN
 DECLARE @n NVARCHAR(MAX)='';
UPDATE tt
SET tt.SegmentDescription = REPLACE(tt.SegmentDescription, '{CH#' + CAST(tpt.A_SegmentChoiceId AS NVARCHAR(100)) + '}', '{CH#' + CAST(tpt.SegmentChoiceCode AS NVARCHAR(100)) + '}')
FROM #finalDescription tt WITH (NOLOCK)
INNER JOIN #TempProjectSegmentTable tpt
	ON tt.ProjectId = tpt.ProjectId
WHERE tt.SegmentDescription LIKE '%{CH#' + CAST(tpt.A_SegmentChoiceId AS NVARCHAR(100)) + '}%'
SET @i = @i + 1;
 END


UPDATE psc
SET psc.SegmentDescription = tct.SegmentDescription
FROM #finalDescription tct
INNER JOIN ProjectSegment psc WITH (NOLOCK)
	ON psc.ProjectId = tct.ProjectId
	AND psc.SegmentStatusId = tct.SegmentStatusId
	AND tct.SegmentId = psc.SegmentId

---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  update  psc
 set psc.SegmentId = 212032335
 ,psc.SegmentStatusId = 1170442885
 from ProjectSegmentChoice psc WITH (NOLOCK)
 where psc.SectionId = 21629253 and psc.ProjectId = 16238  and psc.SegmentStatusId = 1108630085

Update ps
set ps.SegmentDescription
='Freezer Rooms: A completely integrated system consisting of {CH#286653} &nbsp;{CH#286654}&nbsp;-cooled condensing unit located where indicated on drawings, and an evaporator unit located {CH#286655}&nbsp;the room, along with fan, cooling coil, controls, and accessories necessary for proper air movement and conditioning to satisfy the design intent.'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1170442885 and ps.ProjectId = 16238 and ps.CustomerId = 1807 and ps.SectionId = 21629253 and ps.SegmentID = 212032335 
----------------------------------------------------------------------------------------------------------------------------------------
update ps
set ps.SegmentDescription ='Supply Temperature: -2 degree C'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1179258556 and ps.SectionId = 21629253 and ps.ProjectId = 16238 and ps.CustomerId =1807 

update ps
set ps.SegmentDescription ='Return Temperature: +3 degree C minimum'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1179258558 and ps.SectionId = 21629253 and ps.ProjectId = 16238 and ps.CustomerId =1807 

update ps
set ps.SegmentDescription ='Circulating Glycol Fan Coil: Factory interlaced copper tube, aluminum fin coil with aluminum housing which includes an integral sloped drain pan:'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1170444684 and ps.SectionId = 21629253 and ps.ProjectId = 16238 and ps.CustomerId =1807 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------
update ps
set ps.SegmentDescription ='<p>Section 01 3510 - Special Project Procedures for Controlled Environment Facilities: Locations of controlled environment rooms.<p>'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1284601673 and ps.SectionId = 19973817 and ps.ProjectId = 16238 and ps.CustomerId =1807 

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

  update psc
 set psc.SegmentId = 212032335
 from ProjectSegmentChoice psc WITH (NOLOCK)
 where psc.SectionId = 21629253 and psc.ProjectId = 16238  and psc.SegmentStatusId = 1108630085

Update ps 
set ps.SegmentDescription
='Freezer Rooms: A completely integrated system consisting of {CH#286653} &nbsp;{CH#286654}&nbsp;-cooled condensing unit located where indicated on drawings, and an evaporator unit located {CH#286655}&nbsp;the room, along with fan, cooling coil, controls, and accessories necessary for proper air movement and conditioning to satisfy the design intent.'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1170442885 and ps.ProjectId = 16238 and ps.CustomerId = 1807 and ps.SectionId = 21629253 and ps.SegmentID = 212032335
------------------------------------------------------------------------------------------------------------------------------------------   
 
  update psc
 set psc.SegmentId = 198292622
 from ProjectSegmentChoice psc  WITH (NOLOCK)
 where psc.SectionId = 21629253 and psc.ProjectId = 16238 and psc.CustomerId = 1807 and psc.SegmentStatusId = 1108630222

  Update ps
set ps.SegmentDescription='Observation Window:Minimum {CH#286774}&nbsp; observation window constructed from {CH#286775}&nbsp; panes of glass with sealed air spaces between them.'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1108629984 and ps.ProjectId = 16238 and ps.CustomerId = 1807 and ps.SectionId = 21629253 and ps.SegmentID = 198292622
----------------------------------------------------------------------------------------------------------------------------------------------
  update psc
 set psc.SegmentId = 198292698
 from ProjectSegmentChoice psc WITH (NOLOCK)
 where psc.SectionId = 21629253 and psc.ProjectId = 16238  and psc.SegmentStatusId = 1108630222

 ---------------------------------------------------------------------------------------------------------------------------------------
update ps
set ps.SegmentDescription ='<p>Section 01 3510 - Special Project Procedures for Controlled Environment Facilities: Locations of controlled environment rooms.</p>'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1288606166 and ps.SectionId = 24370271 and ps.ProjectId = 19534 and ps.CustomerId =1807 

update ps
set ps.SegmentDescription ='Operation: {CH#259044}. Electro-hydraulic raising of the deck, controlled from a remote mounted NEMA4X rated push-button control station.Supplied with a 1 HP motor.'
from ProjectSegment ps WITH (NOLOCK)
where ps.SegmentStatusId = 1297607733 and ps.SectionId = 24369294 and ps.ProjectId = 19534 and ps.CustomerId =1807 


