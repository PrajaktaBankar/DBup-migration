/*
Customer Support 62766: SLC Global Terms and Section ID Are Incorrect

Server:4

-------------Description-----------
select * from ProjectGlobalTerm PS WHERE PS.CustomerId=3155 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=23 and IsDeleted=0
select * from ProjectGlobalTerm PS WHERE PS.CustomerId=3155 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=25and IsDeleted=0

select  distinct PS.* from ProjectSegmentGlobalTerm PSG inner join ProjectSegment PS ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
 where GlobalTermCode = 23 and UserGlobalTermId = 526 and pSG.CustomerId=3155 and PS.SegmentDescription like '%{GT#23}%'

*/

UPDATE PS set PS.GlobalTermCode =10000702 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=3155 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=23

UPDATE PS set PS.GlobalTermCode =10000703 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=3155 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=25


UPDATE PSGT set PSGT.GlobalTermCode =10000702 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=3155 
 and PSGT.GlobalTermCode=23 AND  PSGT.UserGlobalTermId = 526 and IsDeleted=0


UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#23}','{GT#10000702}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where GlobalTermCode = 23 and UserGlobalTermId = 526 and pSG.CustomerId=3155 and PS.SegmentDescription like '%{GT#23}%'
