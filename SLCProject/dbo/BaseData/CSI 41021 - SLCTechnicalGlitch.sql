
select S01.* into #TempMasterStaging from SQL00.SLCMasterStaging.dbo.SegmentStaging S WITH (NOLOCK)
inner join SLCMasterStaging.dbo.SegmentStaging S01 WITH (NOLOCK) on
S.Old_DocId=S01.Old_DocId and S.Old_StatusId=S01.Old_StatusId and S.Old_SegmentId=S01.Old_SegmentId
where S.MasterDataTypeId IN (4) and S.SegmentDescription like'%{[0-9]}%'
and S.Old_DocId IS NOT NULL AND S.Old_StatusId IS NOT NULL AND S.Old_SegmentId IS NOT NULL 
AND S.SegmentId = S01.SegmentId 

Update S
SET S.SegmentDescription = S01.SegmentDescription
from SQL00.SLCMasterStaging.dbo.SegmentStaging S WITH (NOLOCK)
inner join SLCMasterStaging.dbo.SegmentStaging S01 WITH (NOLOCK) on
S.Old_DocId=S01.Old_DocId and S.Old_StatusId=S01.Old_StatusId and S.Old_SegmentId=S01.Old_SegmentId
where S.MasterDataTypeId IN (4) and S.SegmentDescription like'%{[0-9]}%'
and S.Old_DocId IS NOT NULL AND S.Old_StatusId IS NOT NULL AND S.Old_SegmentId IS NOT NULL 
AND S.SegmentId = S01.SegmentId

Update S
SET S.SegmentDescription = S01.SegmentDescription
from SQL00.SLCMaster.dbo.Segment S
inner join #TempMasterStaging S01 ON S01.SegmentId = S.SegmentId









