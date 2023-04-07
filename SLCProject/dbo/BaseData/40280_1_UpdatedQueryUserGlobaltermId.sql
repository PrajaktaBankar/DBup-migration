/*
Customer Support 40280: SLC User Does Not See All User Global Terms Plus {GT#} Choice Code Issue.
server :5

for references

in projectglobalterm table update userglobaltermid when userglobaltermid is null.
The problem was occured migrated and copy from migrated project  userglobaltermid is getting null.
i update userglobaltermid when userglobaltermid.
please user below script.
select 
PGT.UserGlobalTermId,UGT.UserGlobalTermId,PGT.CustomerId,UGT.CustomerId
from UserGlobalTerm UGT  inner join  ProjectGlobalTerm PGT ON PGT.Name=UGT.Name and 
PGT.CustomerId=UGT.CustomerId and PGT.GlobalTermSource='U' and PGT.UserGlobalTermId is null  where  PGT.ProjectId=@ProjectId and PGT.customerid=@CustomerId

*/



DECLARE @CustomerId int =1947
DECLARE @ProjectId1 int =0


DROP TABLE IF EXISTS #tempprojects

CREATE table #tempprojects (ProjectId Int,RowNo Int)

 INSERT INTO #tempprojects (ProjectId  ,RowNo  )
select ProjectId,
ROW_NUMBER () over(PARTITION BY  CustomerId ORDER BY  CustomerId)as RowNo
 from 
Project WITH(NOLOCK) WHERE  CustomerId=@CustomerId and ISNULL( IsPermanentDeleted,0)=0


DECLARE @ProjectRowCount int=(select COUNT(ProjectId) from project WITH(NOLOCK) where CustomerId=@CustomerId and isnull(IsPermanentDeleted,0)=0)


WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId INT = (select  ProjectId  from #tempprojects WHERE RowNo=@ProjectRowCount);

IF(@ProjectId1 !=0)
	begin
	set @ProjectRowCount=1
	set @ProjectId= @ProjectId1
	end

--select 
--PGT.UserGlobalTermId,UGT.UserGlobalTermId,PGT.CustomerId,UGT.CustomerId
--from UserGlobalTerm UGT  inner join  ProjectGlobalTerm PGT ON PGT.Name=UGT.Name and 
--PGT.CustomerId=UGT.CustomerId and PGT.GlobalTermSource='U' and PGT.UserGlobalTermId is null  where  PGT.ProjectId=@ProjectId and PGT.customerid=@CustomerId

UPDATE PGT
SET PGT.UserGlobalTermId=UGT.UserGlobalTermId
from UserGlobalTerm UGT WITH(NOLOCK)  inner join  ProjectGlobalTerm PGT WITH(NOLOCK) ON PGT.Name=UGT.Name and 
PGT.CustomerId=UGT.CustomerId and PGT.GlobalTermSource='U' and PGT.UserGlobalTermId is null where PGT.ProjectId=@ProjectId  and PGT.customerid=@CustomerId
 
    print @ProjectId

  SET @ProjectRowCount = @ProjectRowCount-1;
 END 
