--Customer Support 67343: Ch# issues from their master - 38818 [SLCProject_SqlSlcOp002]
USE  [SLCProject]
GO

UPDATE ProjectSegment
SET IsDeleted=0
WHERE SegmentId=176743639 AND ProjectId=15328 AND CustomerId=1754 AND SectionId=19123588


UPDATE ProjectSegmentChoice
SET IsDeleted=0
WHERE SegmentChoiceId IN (60283399,60283400,60283401)  AND ProjectId=15328 AND CustomerId=1754 AND SectionId=19123588


UPDATE ProjectChoiceOption
SET IsDeleted=0
WHERE ProjectId=15328 AND CustomerId=1754 AND SectionId=19123588 AND SegmentChoiceId IN (60283399,60283400,60283401)


UPDATE SelectedChoiceOption
SET IsDeleted=0
WHERE  ProjectId=15328 AND CustomerId=1754 AND SectionId=19123588
AND SegmentChoiceCode IN (2790,2789,2791) AND ChoiceOptionCode IN (4156,4157,4158,4159,4160,4162,4161)
AND IsDeleted = 1	

----- SectionId=19123707
UPDATE ProjectSegment
SET IsDeleted=0
WHERE SegmentId=174862606 AND ProjectId=15328 AND CustomerId=1754 AND SectionId=19123707

UPDATE ProjectSegmentChoice
SET IsDeleted=0
WHERE SegmentChoiceId =59717610  AND ProjectId=15328 AND CustomerId=1754 AND SectionId=19123707

UPDATE ProjectChoiceOption
SET IsDeleted=0
WHERE ProjectId=15328 AND CustomerId=1754 AND SectionId=19123707 AND SegmentChoiceId = 59717610


UPDATE SelectedChoiceOption
SET IsDeleted=0
WHERE  ProjectId=15328 AND CustomerId=1754 AND SectionId=19123707
AND SegmentChoiceCode =369368 AND ChoiceOptionCode IN (777595,777596,777597)
AND IsDeleted = 1