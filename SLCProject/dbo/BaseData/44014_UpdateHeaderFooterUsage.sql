/*
 Customer Support 44014: SLC Copying a Project Error
 server:3

 ---For references-----
 1st project scenario:
select * from Header where projectid=6172 and customerid=530
select * from FOOTER where projectid=6172 and customerid=530
select * from HeaderFooterGlobalTermUsage where customerid=530 and projectid=6172

select * from  Footer where FooterId in(10328,10403,10404,10405,10403,10404,10405,10403,10404,10405,10403,10404,10405)
select * from Header where HeaderId in(10343,10328)
headerid and footerid is missing  in header and Footer  table 
while inserting headerid and footerid in HeaderFooterGlobalTermUsage table getting errror because missing headerid and footerid.

2 project scenario:
select * from ProjectGlobalTerm where projectid=7327 and customerid=530 and UserGlobalTermId=726
select * from  userglobalterm  where UserGlobalTermId in(475,476,477,478,534,726,860,861,862,863,865,875,955,956) and customerid=530

in userglobaltermid is not present in userglobalterm but present in ProjectGlobalTerm.userglobaltermid should be present in 
userglobalterm table.
i have delete one record from ProjectGlobalTerm against projectid=7327.

*/

delete from HeaderFooterGlobalTermUsage where HeaderFooterGTId=1311 and ProjectId=6172 and CustomerId=530

delete from ProjectGlobalTerm where  UserGlobalTermId=726 and ProjectId=7327 and CustomerId=530 