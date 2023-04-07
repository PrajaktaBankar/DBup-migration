/*

Customer Support 77238: SLC: Global Terms Error (GT#) When Printing

Run on Server 4

*/

use SLCProject

--begin tran

--000100.10:MbA
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005491', '30') where CustomerId=3737 and ProjectId=31366 and sectionid=39233178 and SegmentStatusId=2256010750
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005490', '31') where CustomerId=3737 and ProjectId=31366 and sectionid=39233178 and SegmentStatusId=2256010750

--000100.11:APAC
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005498', '39') where CustomerId=3737 and ProjectId=31366 and sectionid=39233188 and SegmentStatusId=2256016099
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005490', '31') where CustomerId=3737 and ProjectId=31366 and sectionid=39233188 and  SegmentStatusId=2256016099

--000100.04:IXD
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005497', '38') where CustomerId=3737 and ProjectId=31366 and sectionid=39233173 and SegmentStatusId=2256021808

--000100.11:APAC
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005498', '39') where CustomerId=3737 and ProjectId=31366 and sectionid=39233188 and SegmentStatusId=2256016099

--000100.12:LATAM
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005498', '39') where CustomerId=3737 and ProjectId=31366 and sectionid=39233197 and SegmentStatusId=2256016206

--000100.16:MENA
Update dbo.ProjectSegment set BaseSegmentDescription=REPLACE(BaseSegmentDescription, '10005498', '39') where CustomerId=3737 and ProjectId=31366 and sectionid=39233225 and SegmentStatusId=2256012242



--commit tran

--rollback tran