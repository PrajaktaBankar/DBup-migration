/*
Customer Support 62395: SLC Client would like a script to remove unwanted Font inserted by Copy/Paste - 14820 (S4)
Server - 005
*/
USE SLCProject
GO

UPDATE PS SET PS.SegmentDescription ='flexible-metal-hose legs joined by long-radius, 180-degree return bend or center section of flexible hose.' FROM ProjectSegment PS WITH (NOLOCK)
	WHERE PS.ProjectId =6312 AND PS.CustomerId = 4377 AND PS.SegmentId = 71074466;
UPDATE PS SET IsDeleted = 1 FROM ProjectSegment PS WITH (NOLOCK) WHERE PS.ProjectId =6312 AND PS.CustomerId = 4377 AND PS.SegmentId = 71074467;
UPDATE PSS SET IsDeleted = 1 FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.ProjectId =6312 AND PSS.CustomerId = 4377 AND PSS.SegmentStatusId = 367108549;
UPDATE PS SET SegmentDescription = '<span>PART 1 GENERAL</span>' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 76703395;
UPDATE PS SET SegmentDescription = '&lt;&lt;&lt;&lt; UPDATE NOTES' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 76704257;
UPDATE PS SET SegmentDescription = 'THIS SECTION WILL BE USED TO SPECIFY {CH#10002249}, {CH#10002250} concurrent Owner occupancy.' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 76704935;
UPDATE PS SET SegmentDescription = 'DELETE REFERENCES TO DIVISION 01.' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 76702152;
UPDATE PS SET SegmentDescription = 'Existing power/telephone poles, pole guys, street signs, drainage inlets, valve boxes, manhole covers, etc., do not interfere with the new driveways, sidewalks, or other site improvements. {/qa}' from ProjectSegment PS WITH(NOLOCK) WHERE SegmentId = 76702268;
UPDATE PS SET SegmentDescription = 'Quality Assurance' from ProjectSegment PS  WITH(NOLOCK) WHERE SegmentId = 76702299;