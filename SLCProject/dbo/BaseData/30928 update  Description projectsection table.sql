
/*
server name : SLCProject_SqlSlcOp003
 Customer Support 30928: Section title corrupt after migration from SLE to SLC - 43488

 ---For references-----
select top(10) * from ProjectSection where SectionId=5344696   and ProjectId=5830
 before update text 
 --\plain\rtlch\af1\afs22\alang0\ab\ltrch\f1\fs22\lang0\langnp0\langfe0\langfenp0 COMMON WORK RESULTS FOR FIRE SUPPRESSION

*/

 update PS
 set PS.Description='Common Work Results for Fire Suppression'
 from projectsection PS WITH(nolock) 
 where PS.SectionId=5344696	 and PS.ProjectId=5830
