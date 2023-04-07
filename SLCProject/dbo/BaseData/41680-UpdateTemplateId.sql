/*
Customer Support 41680: SLC Reports with Full Text fail to export

Server:2

for references 
templateid is null update default templatedid in project table.
*/


UPDATE P
SET P.TemplateId = 1
FROM Project P with(nolock) WHERE P.ProjectId in(2277,1956) and P.CustomerId=322 

