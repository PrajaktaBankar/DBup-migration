--Customer Support 67506: SLC Section Name Error
--Execute on Server 04

USE SLCProject_004
GO

UPDATE PS
SET
SegmentSource='M',
SegmentDescription='Architectural Wood Millwork'
FROM ProjectSegment PS WITH (NOLOCK)
WHERE PS.SegmentId=225500902

UPDATE PSS
SET
SegmentOrigin='M'
FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.SegmentStatusId=1237146625