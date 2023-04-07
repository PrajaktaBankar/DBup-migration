/*
Customer Support 40280: SLC User Does Not See All User Global Terms Plus {GT#} Choice Code Issue.

Server :5

for references
this script for update UserGlobalTermId  in projectglobalterm
*/

Declare @customerId int =1947
DROP TABLE IF EXISTS #tempUserGlobalData
Create table #tempUserGlobalData(
GlobalTermCode	int,
SLE_GlobalChoiceID	int,
A_UserGlobalTermId	int,
UserGlobalTermId  int
)

-----------(15 rows affected)
insert into #tempUserGlobalData
select DISTINCT GlobalTermCode,
        PGT.SLE_GlobalChoiceID,
        UGT.A_UserGlobalTermId,
        UGT.UserGlobalTermId 
from ProjectGlobalTerm PGT WITH (NOLOCK) INNER JOIN UserGlobalTerm UGT WITH (NOLOCK)
ON PGT.SLE_GlobalChoiceID=UGT.A_UserGlobalTermId AND PGT.CustomerId=UGT.CustomerId 
WHERE PGT.CustomerId =@customerId 



--select PGT.* from ProjectGlobalTerm PGT WITH (NOLOCK) inner join #tempUserGlobalData tUGD 
--ON PGT.GlobalTermCode=tUGD.GlobalTermCode and PGT.SLE_GlobalChoiceID=tUGD.SLE_GlobalChoiceID 
--where PGT.CustomerId=1947  and PGT.UserGlobalTermId is NUll


-----------(720 rows affected)---------------------
update PGT set PGT.UserGlobalTermId=tUGD.UserGlobalTermId from ProjectGlobalTerm PGT WITH (NOLOCK) inner join  #tempUserGlobalData tUGD 
ON PGT.GlobalTermCode=tUGD.GlobalTermCode and PGT.SLE_GlobalChoiceID=tUGD.SLE_GlobalChoiceID 
where PGT.CustomerId=@customerId and PGT.UserGlobalTermId is NUll






