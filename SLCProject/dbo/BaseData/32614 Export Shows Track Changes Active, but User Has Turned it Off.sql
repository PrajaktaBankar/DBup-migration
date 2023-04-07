--Customer Support 32614: SLC Export Shows Track Changes Active, but User Has Turned it Off
--Excute this script on server 03 

USE SLCProject
go

UPDATE PS
SET BaseSegmentDescription='<span>Project Number: {GT#2}&nbsp;</span>'
FROM ProjectSegment PS
WHERE SegmentStatusId=272992058 AND SectionId=5981550 AND ProjectId=5540

UPDATE PS
SET BaseSegmentDescription='<span>Project Name: {GT#1}&nbsp;&nbsp; </span>'
FROM ProjectSegment PS
WHERE SegmentStatusId=272992059 AND SectionId=5981550 AND ProjectId=5540
