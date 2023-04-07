/*
Customer Support 40280: SLC User Does Not See All User Global Terms Plus {GT#} Choice Code Issue.
server :5

for references:
missing entry in projectglobalterm.
the project have no userglobalterm in projectglobalterm.
thats why i putted entry for that angainst.

for example:
select * from  ProjectGlobalTerm where projectid=1379 and customerid=1947
there is  no record against this project. i insert record  for userglobalterm in ProjectGlobalTerm table.

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


DECLARE @GlobalTermCode TABLE (    
  MinGlobalTermCode int,    
  UserGlobalTermId int    
);    
    
INSERT @GlobalTermCode
SELECT MIN(GlobalTermCode) AS MinGlobalTermCode,UserGlobalTermId        
 FROM ProjectGlobalTerm WITH (NOLOCK)      
 WHERE CustomerId =@CustomerId AND ISNULL(IsDeleted,0)=0       
 AND GlobalTermSource='U'      
 GROUP BY UserGlobalTermId

WHILE (@ProjectRowCount >0)
BEGIN

DECLARE @ProjectId INT = (select  ProjectId  from #tempprojects WHERE RowNo=@ProjectRowCount);

IF(@ProjectId1 !=0)
	begin
	set @ProjectRowCount=1
	set @ProjectId= @ProjectId1
	end

if not exists(select 1 from ProjectGlobalTerm WITH(NOLOCK) where projectid=@ProjectId and GlobalTermSource='U' and CustomerId=@CustomerId 
 and UserGlobalTermId in(select UserGlobalTermId from UserGlobalTerm WITH(NOLOCK) where CustomerId=@CustomerId))
begin

 ---(15 rows affected)--------
 INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value,GlobalTermCode, GlobalTermSource, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)      
 SELECT      
  NULL AS GlobalTermId      
    ,@ProjectId AS ProjectId      
    ,@CustomerId AS CustomerId      
    ,Name      
    ,Name      
    ,MGTC.MinGlobalTermCode      
    ,'U' AS GlobalTermSource     
    ,GETUTCDATE() AS CreatedDate    
    ,CreatedBy      
    ,GETUTCDATE() AS ModifiedDate    
    ,CreatedBy AS ModifiedBy      
    ,UGT.UserGlobalTermId AS UserGlobalTermId      
    ,ISNULL(IsDeleted, 0) AS IsDeleted      
 FROM UserGlobalTerm UGT WITH(NOLOCK) INNER JOIN @GlobalTermCode MGTC     
 ON UGT.UserGlobalTermId=MGTC.UserGlobalTermId      
 WHERE CustomerId = @CustomerId      
 AND ISNULL(IsDeleted,0)=0 


  print @ProjectId 
end

SET @ProjectRowCount = @ProjectRowCount-1;
 END 

