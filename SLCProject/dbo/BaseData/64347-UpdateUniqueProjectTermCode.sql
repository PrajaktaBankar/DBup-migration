 /*

Customer Support 64347: Global Term displays/exports wrong term - ON A DEADLINE

Server:2

---------reference------------
---User globaltermcode is not unique
---it is same like master globalterm code it was causing issue
--select * FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
-- and PSGT.GlobalTermCode=23 AND  PSGT.UserGlobalTermId = 802 and IsDeleted=0
 --select  distinct PS.* from ProjectSegmentGlobalTerm PSG inner join ProjectSegment PS ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
 --where PSG.GlobalTermCode = 23 and PSG.UserGlobalTermId = 802 and pSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#23}%'

 */

-------------------1st table insert ------------------------------------------------------------------

UPDATE PS set PS.GlobalTermCode =10004617 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=23 and PS.UserGlobalTermId=802

UPDATE PS set PS.GlobalTermCode =10004618 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=24 and PS.UserGlobalTermId=803

UPDATE PS set PS.GlobalTermCode =10004619 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=25  and PS.UserGlobalTermId=804

UPDATE PS set PS.GlobalTermCode =10004620 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=26  and PS.UserGlobalTermId=805


UPDATE PS set PS.GlobalTermCode =10004621 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=27  and PS.UserGlobalTermId=806


UPDATE PS set PS.GlobalTermCode =10004622 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=28  and PS.UserGlobalTermId=808


UPDATE PS set PS.GlobalTermCode =10004623 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=29  and PS.UserGlobalTermId=809


UPDATE PS set PS.GlobalTermCode =10004624 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=32 and PS.UserGlobalTermId=812

UPDATE PS set PS.GlobalTermCode =10004625 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=33  and PS.UserGlobalTermId=813

UPDATE PS set PS.GlobalTermCode =10004626 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=35  and PS.UserGlobalTermId=815


UPDATE PS set PS.GlobalTermCode =10004627 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=37  and PS.UserGlobalTermId=817

UPDATE PS set PS.GlobalTermCode =10004628 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=38  and PS.UserGlobalTermId=818


UPDATE PS set PS.GlobalTermCode =10004629 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=39  and PS.UserGlobalTermId=819

UPDATE PS set PS.GlobalTermCode =10004630 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=40 and PS.UserGlobalTermId=820


UPDATE PS set PS.GlobalTermCode =10004631 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=41  and PS.UserGlobalTermId=821

UPDATE PS set PS.GlobalTermCode =10004632 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=42  and PS.UserGlobalTermId=822


UPDATE PS set PS.GlobalTermCode =10004633 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=44  and PS.UserGlobalTermId=824

UPDATE PS set PS.GlobalTermCode =10004634 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=45  and PS.UserGlobalTermId=826

UPDATE PS set PS.GlobalTermCode =10004635 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=46  and PS.UserGlobalTermId=827

UPDATE PS set PS.GlobalTermCode =10004636 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=47  and PS.UserGlobalTermId=829


UPDATE PS set PS.GlobalTermCode =10004635 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=48  and PS.UserGlobalTermId=830


UPDATE PS set PS.GlobalTermCode =10004636 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=50  and PS.UserGlobalTermId=832


UPDATE PS set PS.GlobalTermCode =10004637 FROM ProjectGlobalTerm PS WITH(NOLOCK)  WHERE PS.CustomerId=1211 
and PS.GlobalTermSource='U' and PS.GlobalTermCode=51  and PS.UserGlobalTermId=833

--------------------------2nd table insert------------------------------------
UPDATE PSGT set PSGT.GlobalTermCode =10004618 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=24 AND  PSGT.UserGlobalTermId = 803 and IsDeleted=0

 UPDATE PSGT set PSGT.GlobalTermCode =10004619 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=25 AND  PSGT.UserGlobalTermId = 804 and IsDeleted=0

 UPDATE PSGT set PSGT.GlobalTermCode =10004620 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=26 AND  PSGT.UserGlobalTermId = 805 and IsDeleted=0

  UPDATE PSGT set PSGT.GlobalTermCode =10004629 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=39 AND  PSGT.UserGlobalTermId = 819 and IsDeleted=0

  UPDATE PSGT set PSGT.GlobalTermCode =10004630 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=40 AND  PSGT.UserGlobalTermId = 820 and IsDeleted=0

   UPDATE PSGT set PSGT.GlobalTermCode =10004631 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=41 AND  PSGT.UserGlobalTermId = 821 and IsDeleted=0

  UPDATE PSGT set PSGT.GlobalTermCode =10004633 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=44 AND  PSGT.UserGlobalTermId = 824 and IsDeleted=0

   UPDATE PSGT set PSGT.GlobalTermCode =10004634 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=45 AND  PSGT.UserGlobalTermId = 826 and IsDeleted=0

    UPDATE PSGT set PSGT.GlobalTermCode =10004636 FROM ProjectSegmentGlobalTerm PSGT WITH(NOLOCK)  WHERE PSGT.CustomerId=1211 
 and PSGT.GlobalTermCode=47 AND  PSGT.UserGlobalTermId = 829 and IsDeleted=0

 -------------------------------3 segmentdescription updated-----------------------------------------------------------------------------
UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#24}','{GT#10004618}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where PSG.GlobalTermCode = 24 and PSG.UserGlobalTermId = 803 and PSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#24}%'

UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#25}','{GT#10004619}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where PSG.GlobalTermCode = 25 and PSG.UserGlobalTermId = 804 and PSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#25}%'

UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#26}','{GT#10004620}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where PSG.GlobalTermCode = 26 and PSG.UserGlobalTermId = 805 and PSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#26}%'

UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#40}','{GT#10004630}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where PSG.GlobalTermCode = 40 and PSG.UserGlobalTermId = 820 and PSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#40}%'

UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#41}','{GT#10004631}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where PSG.GlobalTermCode = 41 and PSG.UserGlobalTermId = 821 and PSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#41}%'

UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#45}','{GT#10004634}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where PSG.GlobalTermCode = 45 and PSG.UserGlobalTermId = 826 and PSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#45}%'

UPDATE PS set PS.SegmentDescription=REPLACE(PS.SegmentDescription,'{GT#47}','{GT#10004636}') from 
ProjectSegmentGlobalTerm PSG WITH(NOLOCK) inner join ProjectSegment PS WITH(NOLOCK) ON PSG.SectionId=PS.SectionId and PSG.SegmentId=PS.SegmentId and PSG.ProjectId=PS.ProjectId
where PSG.GlobalTermCode = 47 and PSG.UserGlobalTermId = 829 and PSG.CustomerId=1211 and PS.SegmentDescription like '%{GT#47}%'