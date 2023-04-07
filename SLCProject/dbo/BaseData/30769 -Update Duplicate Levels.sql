/*
server name : SLCProject_SqlSlcOp003
Customer Support 30769: SLC Migrated Project Template Shows Double Levels

for reference
select * from Project where CustomerId=783 AND PROJECTID=4356
select * from TemplateStyle  where TemplateId=309 AND TemplateStyleId>2781
SELECT * FROM Template WHERE Name ='G+P Standard'

9 row affected
*/

UPDATE  TS  
SET TemplateId=309 
FROM TemplateStyle TS with (nolock) 
where TemplateId=298 AND TemplateStyleId>2781
