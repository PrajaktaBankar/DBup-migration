/*
Customer Support 42194: SLC restore sections
Server :3


-----For references---------------------
--select IsDeleted,IsLocked, * from projectsection where projectid=9756 and SourceTag in('040343','050169','060121','080314','080350')
--select IsDeleted, * from ProjectSection where projectid=9756 and sectionid in(9977279,9977280,9977281,9977282,9977283)  
--select IsDeleted, * from ProjectSection where projectid=9756 and sectionid in(10078800,10078801,10078802,10078803,10078804)
--select * from ProjectSection where CreateDate like '%2020-07-29%' and projectid=9756 
*/


UPDATE PS
SET PS.IsDeleted = 0
FROM ProjectSection PS with(nolock) WHERE PS.SectionId in(9977279,9977280,9977281,9977282,9977283) and  PS.ProjectId=9756


UPDATE PS
SET PS.IsDeleted = 1
FROM ProjectSection PS with(nolock) WHERE PS.SectionId in(10078800,10078801,10078802,10078803,10078804) and  PS.ProjectId=9756