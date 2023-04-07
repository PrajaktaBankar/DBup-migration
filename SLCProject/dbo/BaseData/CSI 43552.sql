USE SLCProject
 Go

--Customer Support 43552: Section does not print in Outline mode
--EXECUTE On server 3
Update dbo.ProjectSegmentStatus set spectypetagid=2 where ProjectId=9759 and SpecTypeTagId=3  and CustomerId=158
Update dbo.ProjectSegmentStatus set spectypetagid=1 where ProjectId=9759 and SpecTypeTagId=4  and customerid=158
