 

--Execute on server 3
--Customer Support 31078: Links Not Appearing in Migrated Project, but SLC says Duplicate links not allowed

 
---407  rows should affected 
UPDATE pss SET
pss.mSegmentId=ss.SegmentId 
from ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN SLCMaster..SegmentStatus ss WITH(NOLOCK)
on pss.mSegmentStatusId=ss.SegmentStatusId 
INNER JOIN ProjectSegmentStatusView pssv WITH(NOLOCK) on pss.SegmentStatusId=pssv.SegmentStatusId AND pss.ProjectId=pssv.ProjectId
AND pss.SectionId=pssv.SectionId AND pss.CustomerId=pssv.CustomerId AND ss.SectionId=pssv.mSectionId AND pss.SectionId=pssv.SectionId
AND pssv.CustomerId=464  and pss.ProjectId=1516
AND pss.mSegmentId<>ss.SegmentId 
AND pss.SegmentSource='M'
INNER JOIN ProjectSegmentLink psl WITH(NOLOCK) on
psl.SourceSegmentCode=ss.SegmentId AND psl.SourceSegmentStatusCode=ss.SegmentStatusId
AND psl.CustomerId=pss.CustomerId and psl.ProjectId=pss.ProjectId
 
 -- 343  rows should affected
UPDATE pss set
pss.mSegmentId=ss.SegmentId 
from ProjectSegmentStatus pss WITH(NOLOCK) INNER JOIN SLCMaster..SegmentStatus ss WITH(NOLOCK)
on pss.mSegmentStatusId=ss.SegmentStatusId 
INNER JOIN ProjectSegmentStatusView pssv WITH(NOLOCK) on pss.SegmentStatusId=pssv.SegmentStatusId AND pss.ProjectId=pssv.ProjectId
AND pss.SectionId=pssv.SectionId AND pss.CustomerId=pssv.CustomerId AND ss.SectionId=pssv.mSectionId AND pss.SectionId=pssv.SectionId
AND pssv.CustomerId=464  and pss.ProjectId=1516
AND pss.mSegmentId<>ss.SegmentId 
AND pss.SegmentSource='M'
INNER JOIN ProjectSegmentLink psl WITH(NOLOCK) on
psl.TargetSegmentCode=ss.SegmentId AND psl.TargetSegmentStatusCode =ss.SegmentStatusId
AND psl.CustomerId=pss.CustomerId and psl.ProjectId=pss.ProjectId


 -- 3822 row should affected.
DELETE A FROM (
SELECT *,
ROW_NUMBER()OVER(PARTITION BY SourceSectionCode,	SourceSegmentStatusCode	,SourceSegmentCode,TargetSegmentStatusCode	,TargetSegmentCode,
SourceSegmentChoiceCode	,SourceChoiceOptionCode,
TargetSegmentChoiceCode	,TargetChoiceOptionCode,TargetSectionCode 
 ORDER BY SegmentLinkId )as row_no
FROM ProjectSegmentLink WITH(NOLOCK)
 WHERE CustomerId=464 and ProjectId=1516  AND LinkSource='M'  
 )As A WHERE A.row_no>1
 
 
