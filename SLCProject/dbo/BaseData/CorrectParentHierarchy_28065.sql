--Execute it on server 3
--Customer Support 28065: Cannot update section

--(9 row affected)
USE [SLCProject_SqlSlcOp003]
----Correct Parents : 
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143762104 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143761884
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143599313
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143634961
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143634959
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143634981
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143634979
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143634992
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143635005
UPDATE PSS SET  PSS.ParentSegmentStatusId = 143599343 FROM [ProjectSegmentStatus] PSS with(nolock) WHERE PSS.SegmentStatusId = 143795334

--Seq 0131 - Increase Indent
--Seq 0130 - Increase Branch Indent
--Seq 0478 - Increase Indent
--Go Ahead and Accept Updates in update mode