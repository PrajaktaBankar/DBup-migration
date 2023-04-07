/*
Customer Support 40280: SLC User Does Not See All User Global Terms Plus {GT#} Choice Code Issue.

Server :5

Missing User globalterm in projectglobalterm
*/

Declare @PProjectID int =1161
Declare @PCustomerID int =1947
DECLARE @GlobalTermCode TABLE (    
  MinGlobalTermCode int,    
  UserGlobalTermId int    
);    
    
INSERT @GlobalTermCode
SELECT MIN(GlobalTermCode) AS MinGlobalTermCode,UserGlobalTermId        
 FROM ProjectGlobalTerm WITH (NOLOCK)      
 WHERE CustomerId =@PCustomerID AND ISNULL(IsDeleted,0)=0       
 AND GlobalTermSource='U'      
 GROUP BY UserGlobalTermId
 
 -----(15 rows affected)--------
 INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, Name, Value,GlobalTermCode, GlobalTermSource, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)      
 SELECT      
  NULL AS GlobalTermId      
    ,@PProjectID AS ProjectId      
    ,@PCustomerID AS CustomerId      
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
 WHERE CustomerId = @PCustomerID      
 AND IsDeleted = 0 




