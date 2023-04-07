/*
Customer Support 47436: SLC GLOBAL ISSUE - Paragraph content is repeated several times in Section 08 7100-BSD
Run this on Server 0 and Server 1
The same records on canada master looks good.

Section ID of 087100:BSD  is 388
(select * From slcmasterstaging.dbo.SectionsStaging where SourceTag like '087100' and Author like 'bsd' and MasterDataTypeId=1)

I am not sure if there are other affected records. Tried to identify through scripting but couldn't reliably do so.

*/

-- Fix for Manufacturer paragraph "Hiawatha"

--SLE_Master [description] looks OK.
--I am not sure how old_description in SLCMasterStaging.dbo.SegmentStaging got its data.
--Set the [old_description] right to be safe, I am not sure if its used for conversion logic.
/*
select * from SLCMasterStaging.dbo.SegmentStaging with (nolock) 
where SectionId=388 and [SegmentDescription] like 'Hiawatha%'

select * from SLCMaster.dbo.Segment with (nolock) 
where SectionId=388 and [SegmentDescription] like 'Hiawatha%'
*/

--returns 12 rows
Update SLCMasterStaging.dbo.SegmentStaging set Old_Description=b.[Description]
from SLCMasterStaging.dbo.SegmentStaging a
inner join SLE_Master.dbo.Segments b on a.Old_DocId=b.DocID and a.Old_SegmentId=b.SegmentID
where a.SectionId=388 and [SegmentDescription] like 'Hiawatha%'

--returns 12 rows
--strip all the character after the first #sle.
Update SLCMasterStaging.dbo.SegmentStaging set segmentdescription=SUBSTRING(segmentdescription, 0, CHARINDEX('#sle.', segmentdescription)+5)
from SLCMasterStaging.dbo.SegmentStaging with (nolock) 
where SectionId=388 and [SegmentDescription] like 'Hiawatha%'

--returns 12 rows
Update SLCMaster.dbo.Segment set SegmentDescription=b.SegmentDescription
from SLCMaster.dbo.Segment a
inner join SLCMasterStaging.dbo.SegmentStaging b on b.SectionId=a.SectionId and b.SegmentId=a.SegmentId
where b.SectionId=388 
and b.[SegmentDescription] like 'Hiawatha%'
and b.MasterDataTypeId=1 




-- Fix for Manufacturer paragraph "Ives"
/*
select * from SLCMasterStaging.dbo.SegmentStaging with (nolock) 
where SectionId=388 and [SegmentDescription] like 'Ives%'

select * from SLCMaster.dbo.Segment with (nolock) 
where SectionId=388 and [SegmentDescription] like 'Ives%'
*/

--Returns 13 rows
Update SLCMasterStaging.dbo.SegmentStaging set Old_Description=b.[Description]
from SLCMasterStaging.dbo.SegmentStaging a
inner join SLE_Master.dbo.Segments b on a.Old_DocId=b.DocID and a.Old_SegmentId=b.SegmentID
where a.SectionId=388 and [SegmentDescription] like 'Ives%'

--Returns 13 rows
--strip all the character after the first #sle.
Update SLCMasterStaging.dbo.SegmentStaging set segmentdescription=SUBSTRING(segmentdescription, 0, CHARINDEX('#sle.', segmentdescription)+5)
from SLCMasterStaging.dbo.SegmentStaging with (nolock) 
where SectionId=388 and [SegmentDescription] like 'Ives%'

--Returns 13 rows
Update SLCMaster.dbo.Segment set SegmentDescription=b.SegmentDescription
from SLCMaster.dbo.Segment a
inner join SLCMasterStaging.dbo.SegmentStaging b on b.SectionId=a.SectionId and b.SegmentId=a.SegmentId
where b.SectionId=388 
and b.[SegmentDescription] like 'Ives%'
and b.MasterDataTypeId=1 


