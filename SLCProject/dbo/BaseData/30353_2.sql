  --execute on server 2
 --Customer Support 30353: CH# Issues in a Project
 
DELETE A FROM(
SELECT * 
,ROW_NUMBER()over(PARTITION BY SegmentChoiceCode,	ChoiceOptionCode	, 		SectionId	,ProjectId	,CustomerId ORDER BY SelectedChoiceOptionId)as row_no
FROM SelectedChoiceOption WITH (NOLOCK) WHERE  ProjectId=4359 and SectionId=5231274 and CustomerId=662 and choiceoptionsource='U'
)as A WHERE A.row_no>1


DELETE FROM ProjectChoiceOption WHERE SegmentChoiceId=12488911
DELETE FROM ProjectSegmentChoice WHERE SegmentChoicecode=141457 and ProjectId=4359 AND SegmentChoiceId=12488911

DELETE FROM ProjectChoiceOption WHERE SegmentChoiceId=12488900
DELETE FROM ProjectSegmentChoice WHERE SegmentChoicecode=141456 and ProjectId=4359 AND SegmentChoiceId=12488900

DELETE FROM ProjectChoiceOption WHERE SegmentChoiceId=12488901
DELETE FROM ProjectSegmentChoice WHERE SegmentChoicecode=141455 and ProjectId=4359 AND SegmentChoiceId=12488901

DELETE FROM ProjectChoiceOption WHERE SegmentChoiceId=12488902
DELETE FROM ProjectSegmentChoice WHERE SegmentChoicecode=141458 and ProjectId=4359 AND SegmentChoiceId=12488902

UPDATE  sco set sco.IsDeleted=0 from SelectedChoiceOption sco  WITH (NOLOCK) WHERE sco.SegmentChoicecode in(141458,141457,141455,141456) and sco.ProjectId=4359  and sco.CustomerId=662

delete FROM ProjectSegmentChoice WHERE SegmentChoiceId=15340881 and ProjectId=4359 and CustomerId=662

UPDATE psc SET psc.SegmentStatusId=ps.SegmentStatusId FROM ProjectSegment ps WITH (NOLOCK) INNER JOIN
ProjectSegmentChoice psc WITH (NOLOCK) ON ps.ProjectId=psc.ProjectId and ps.SectionId=psc.SectionId and ps.CustomerId=psc.CustomerId and ps.SegmentId=psc.SegmentId
WHERE ps.SegmentId=32183688 and ps.ProjectId=4359 and ps.CustomerId=662


DELETE FROM ProjectChoiceOption WHERE SegmentChoiceId=15341145
DELETE FROM ProjectSegmentChoice WHERE SegmentChoicecode=193190 and ProjectId=4359 AND SegmentChoiceId=15341145

UPDATE psc SET psc.SegmentStatusId=ps.SegmentStatusId FROM ProjectSegment ps  WITH (NOLOCK) INNER JOIN
ProjectSegmentChoice psc WITH (NOLOCK) ON ps.ProjectId=psc.ProjectId and ps.SectionId=psc.SectionId and ps.CustomerId=psc.CustomerId and ps.SegmentId=psc.SegmentId
WHERE ps.SegmentId=32184115 and ps.ProjectId=4359 and ps.CustomerId=662


update  psc SET psc.SegmentId=32457988 from
ProjectSegmentChoice psc  WITH (NOLOCK)
WHERE psc.SegmentStatusId=205232317 and psc.ProjectId=4359 and psc.CustomerId=662