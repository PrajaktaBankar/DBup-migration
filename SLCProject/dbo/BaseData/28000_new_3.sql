USE SLCProject
GO
--Customer Support 28000: SLC User Says Fill In The Blank Text was Replaced with {CH#} Issue - PPL 34275
--execute on server 02
UPDATE x SET x.IsDeleted=1
FROM (

SELECT
	ROW_NUMBER() OVER (PARTITION BY ChoiceOptionCode, SegmentChoiceCode, ProjectId, SectionId, CustomerId ORDER BY SelectedChoiceOptionId ASC) AS rowid
   ,*
FROM SelectedChoiceOption
WHERE ProjectId = 5026
AND ChoiceOptionSource = 'U'  
)as x WHERE x.rowid>1

DECLARE @segmentdescription nvarchar(max)='';

SELECT @segmentdescription =SegmentDescription FROM SLCMaster..Segment WHERE segmentid=669635

UPDATE ps SET ps.SegmentDescription=@segmentdescription  FROM ProjectSegment ps WHERE ps.SegmentStatusId=246477811

DELETE   FROM SelectedChoiceOption WHERE   ProjectId = 5026 and SegmentChoiceCode=49107 and ChoiceOptionSource='U'
and SectionId=6023632 and IsDeleted=1

DELETE x FROM (
SELECT ROW_NUMBER ()OVER(PARTITION BY SegmentChoiceCode	,ChoiceOptionCode  ORDER BY SelectedChoiceOptionId  ) as rowid,
* FROM SelectedChoiceOption WHERE   ProjectId = 5026 and SegmentChoiceCode=49107 and ChoiceOptionSource='U'
and SectionId=6023632
) AS x WHERE x.rowid>1

DELETE   FROM ProjectChoiceOption	WHERE ProjectId = 5026  and SegmentChoiceId=16651465

DELETE FROM ProjectSegmentChoice WHERE   ProjectId = 5026 and SegmentChoiceCode=49107 and SegmentChoiceId=16651465

 