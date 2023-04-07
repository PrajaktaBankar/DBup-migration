/*
Customer Support 33234: SLC Project Missing Sections
Execute on Server 4
Row Affected 1 for each query
*/
update PS
set IsDeleted=0
from ProjectSection PS with (nolock)
where ProjectId = 993 and CustomerId=2682 and SourceTag='233400' and SectionId=1137206

update PS
set IsDeleted=0
from ProjectSection PS with (nolock)
where ProjectId = 993 and CustomerId=2682 and SourceTag='238126.13' and SectionId=1137205
