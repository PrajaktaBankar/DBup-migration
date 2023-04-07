/*
 server name : SLCProject_SqlSlcOp004
 Customer Support 55503: Spacing and text wrapping - Paul O'Connor with Setplan Engineering - 70501

*/

UPDATE PS SET PS.SegmentDescription = REPLACE (PS.SegmentDescription,'&nbsp;',' ') FROM Projectsegment AS PS WITH(NOLOCK) WHERE PS. ProjectId = 5834

