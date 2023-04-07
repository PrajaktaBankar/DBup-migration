USE SLCProject
GO
--Customer Support 34944: SLC User Cannot Remove Page Break
--execute on server 02

UPDATE pss set pss.IsPageBreak = 0 FROM ProjectSegmentStatus pss WITH(NOLOCK)
WHERE SegmentStatusId in (312693162, 9255058);