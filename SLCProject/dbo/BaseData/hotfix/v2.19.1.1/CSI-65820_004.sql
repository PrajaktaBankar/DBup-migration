/*
Customer Support 65820: SLC User Cannot Toggle 0000 - and Cannot Add Link Because of This
Server - 004
*/

USE SLCProject

GO

update PSL set TargetSegmentCode = 749441 FROM ProjectSegmentLink PSL WITH(NOLOCK) WHERE SegmentLinkId = 401578593;
update PSL set TargetSegmentCode = 749441 FROM ProjectSegmentLink PSL WITH(NOLOCK) WHERE SegmentLinkId = 438106483;