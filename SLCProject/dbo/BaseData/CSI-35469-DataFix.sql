/*
Customer Support 35469: Issue with spec number 28 2000 - BSD - Video Surveillance
Server 1
*/
USE [SLCProject_SqlSlcOp001]
GO

UPDATE ProjectSegmentStatus SET IsDeleted=1  WHERE SegmentStatusId in(SELECT SegmentStatusId FROM (
SELECT ROW_NUMBER() OVER (PARTITION BY ProjectId,mSegmentStatusId,SegmentStatusCode,SegmentCode ORDER BY sequenceNumber)As 'Ranking',SegmentStatusId,ProjectId, SectionId, mSegmentStatusId,SegmentStatusCode,SegmentCode 
FROM ProjectSegmentStatusView WITH (NOLOCK)
WHERE Sectionid=9939012 and ProjectId=3863 and isnull(IsDeleted,0)=0
) As t WHERE Ranking>1) 