USE SLCProject
GO

UPDATE ProjectSegment
SET SegmentDescription = '&lt;&lt;&lt;&lt; UPDATE NOTES'
WHERE ProjectId= 8800 AND CustomerId=1401 AND SectionId=10283775 AND SegmentStatusId=501868828

UPDATE ProjectSegment
SET SegmentDescription = 'THIS SECTION WILL BE USED TO SPECIFY {CH#10002249}, {CH#10002250} concurrent Owner occupancy.'
WHERE ProjectId= 8800 AND CustomerId=1401 AND SectionId=10283775 AND SegmentStatusId=501868859