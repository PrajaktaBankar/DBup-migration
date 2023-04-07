
select S01.* into #TempMasterStaging from SLCMasterStaging.dbo.SegmentStaging S WITH (NOLOCK)
inner join SLCMasterStaging_001.dbo.SegmentStaging S01 WITH (NOLOCK) on
S01.Old_DocId=S.Old_DocId and S01.Old_StatusId=S.Old_StatusId and S01.Old_SegmentId=S.Old_SegmentId
where S.MasterDataTypeId IN (4) and( S.SegmentDescription like'%{1}%' or S.SegmentDescription like'%{2}%')
and S.Old_DocId IS NOT NULL AND S.Old_StatusId IS NOT NULL AND S.Old_SegmentId IS NOT NULL 
AND S01.SegmentId = S.SegmentId 
and S.SectionId=3000583

Update S
SET S.SegmentDescription = S01.SegmentDescription
from SLCMasterStaging.dbo.SegmentStaging S WITH (NOLOCK)
inner join SLCMasterStaging_001.dbo.SegmentStaging S01 WITH (NOLOCK) on
S01.Old_DocId=S.Old_DocId and S01.Old_StatusId=S.Old_StatusId and S01.Old_SegmentId=S.Old_SegmentId
where S.MasterDataTypeId IN (4) and( S.SegmentDescription like'%{1}%' or S.SegmentDescription like'%{2}%')
and S.Old_DocId IS NOT NULL AND S.Old_StatusId IS NOT NULL AND S.Old_SegmentId IS NOT NULL 
AND S01.SegmentId = S.SegmentId 
and S.SectionId=3000583

Update S
SET S.SegmentDescription = S01.SegmentDescription
from SLCMaster.dbo.Segment S
inner join #TempMasterStaging S01 ON S01.SegmentId = S.SegmentId





