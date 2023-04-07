/*
Customer Support 37204: SLC CH# issue
Server :2
*/

Declare @customerId int =216
Declare @ProjectId int =5771

DROP TABLE IF EXISTS #temSelectedChoiceoptionData
Create table #temSelectedChoiceoptionData(
SegmentChoiceCode	int,
ChoiceOptionCode	int,
ChoiceOptionSource	char,
IsSelected	bit,
SectionId	int,
ProjectId	int,
CustomerId	int,
OptionJson	nvarchar,
IsDeleted	bit
)

---hold Data in temparary table
insert into #temSelectedChoiceoptionData
	SELECT
		psc.SegmentChoiceCode
	   ,pco.ChoiceOptionCode
	   ,pco.ChoiceOptionSource
	   ,0 AS IsSelected
	   ,psc.SectionId
	   ,psc.ProjectId
	   ,pco.CustomerId
	   ,NULL AS OptionJson
	   ,0 AS IsDeleted
	FROM ProjectSegmentChoice psc WITH (NOLOCK)
	INNER JOIN ProjectChoiceOption pco WITH (NOLOCK)
		ON pco.SegmentChoiceId = psc.SegmentChoiceId
			AND pco.SectionId = psc.SectionId
			AND pco.ProjectId = psc.ProjectId
			AND pco.CustomerId = psc.CustomerId
	LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK)
		ON pco.ChoiceOptionCode = sco.ChoiceOptionCode
			AND pco.SectionId = sco.SectionId
			AND pco.ProjectId = sco.ProjectId
			AND pco.CustomerId = sco.CustomerId
			AND sco.ChoiceOptionSource = pco.ChoiceOptionSource
     	WHERE sco.SelectedChoiceOptionId IS NULL 
	AND pco.CustomerId = @customerId
	AND pco.ProjectId = @ProjectId
	AND ISNULL(pco.IsDeleted, 0) = 0
	AND ISNULL(psc.IsDeleted, 0) = 0

	----Data insert actual table  --
--(1242 rows affected)
insert into SelectedChoiceOption
   select
   SegmentChoiceCode,
   ChoiceOptionCode,
   ChoiceOptionSource,
   IsSelected,
   SectionId,
   ProjectId,
   CustomerId,
   OptionJson,
   IsDeleted from #temSelectedChoiceoptionData

--here update isselected is equal to 1 bydefault
UPDATE A
SET IsSelected = 1
from(
select SCO.*,
ROW_NUMBER() OVER (PARTITION BY SCO.SegmentChoiceCode
,SCO.ChoiceOptionSource, SCO.SectionId,SCO.ProjectId,SCO.CustomerId 
ORDER BY sco.SelectedChoiceOptionId) AS RowNo
from SelectedChoiceOption SCO WITH (NOLOCK) inner join #temSelectedChoiceoptionData t
on sco.SegmentChoiceCode=t.SegmentChoiceCode
and sco.ChoiceOptionCode=t.ChoiceOptionCode
and sco.SectionId=t.SectionId
 and sco.ProjectId=t.ProjectId
 and sco.ChoiceOptionSource = 'U'
 and sco.CustomerId=t.CustomerId)AS A where A.RowNo=1 
















 