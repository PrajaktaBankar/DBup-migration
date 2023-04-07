--Execute it on Server 2
--Customer Support 28000: SLC User Says Fill In The Blank Text was Replaced with {CH#} Issue - PPL 34275

DECLARe @ProjectId INT = 3308
DECLARE @SectionId INT = 4960052
DECLARE @SegmentStatusId INt= 195147906
DECLARE @SegmentChoiceCode INt = 10023796

select * from ProjectSegmentChoice WITh	(NOLOCK)
where ProjectId = @ProjectId and SectionId = @SectionId and 
SegmentStatusId=@SegmentStatusId and 
SegmentChoiceCode=@SegmentChoiceCode

--(1 Row Affected)
UPDATE  B SET IsDeleted=0 FROM
(
SELECT PSC.* FROM ProjectSegmentChoice PSC WITH (NOLOCK) 
where PSC.ProjectId = @ProjectId and PSC.SectionId = @SectionId and 
PSC.SegmentStatusId=@SegmentStatusId and 
PSC.SegmentChoiceCode=@SegmentChoiceCode
) B


