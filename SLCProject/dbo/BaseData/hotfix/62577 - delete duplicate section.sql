/*
 server name : SLCProject_SqlSlcOp001
 Customer Support 62577: SLC Automatic Table of Contents Export Fails when Include Page Count is Selected*/

UPDATE PS SET IsDeleted = 1  
from ProjectSection PS WITH(NOLOCK) 
where SourceTag = '061500' and ProjectId = 5657 and SectionId = 15526627
