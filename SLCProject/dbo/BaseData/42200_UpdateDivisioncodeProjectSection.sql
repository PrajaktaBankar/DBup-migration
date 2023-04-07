/*
Customer Support 42200: SLC Section Will Not Print / Export

server 3

for references
the issue occured only migrated and copy from migrated project divisionid and division code getting null
select ps.SectionId,s.SectionId, ps.CustomerId,ps.ProjectId,
ps.DivisionId,s.DivisionId,ps.DivisionCode,s.DivisionCode from projectsection ps WITH (NOLOCK) inner join [SLCMaster]..Section s WITH (NOLOCK) on ps.mSectionId=s.SectionId 
and ps.DivisionId is null and ps.DivisionCode is null  and s.DivisionCode is not null and  s.DivisionId is not null where  ps.CustomerId=105 and isnull(ps.IsDeleted,0)=0

*/

--------------------customer specific-----------------------------------
update ps set 
ps.DivisionId=s.DivisionId,ps.DivisionCode=s.DivisionCode  from projectsection ps WITH (NOLOCK) inner join [SLCMaster]..Section s WITH (NOLOCK) on ps.mSectionId=s.SectionId 
and ps.DivisionId is null and ps.DivisionCode is null  and s.DivisionCode is not null and  s.DivisionId is not null where  ps.CustomerId=105 and isnull(ps.IsDeleted,0)=0




--------------------Server specific-----------------------------------
select ps.SectionId,s.SectionId, ps.CustomerId,ps.ProjectId,
ps.DivisionId,s.DivisionId,ps.DivisionCode,s.DivisionCode from projectsection ps WITH (NOLOCK) inner join [SLCMaster]..Section s WITH (NOLOCK) on ps.mSectionId=s.SectionId 
and ps.DivisionId is null and ps.DivisionCode is null  and s.DivisionCode is not null and  s.DivisionId is not null  and  isnull(ps.IsDeleted,0)=0


--update ps set 
--ps.DivisionId=s.DivisionId,ps.DivisionCode=s.DivisionCode  from projectsection ps WITH (NOLOCK) inner join [SLCMaster]..Section s WITH (NOLOCK) on ps.mSectionId=s.SectionId 
--and ps.DivisionId is null and ps.DivisionCode is null  and s.DivisionCode is not null and  s.DivisionId is not null and isnull(ps.IsDeleted,0)