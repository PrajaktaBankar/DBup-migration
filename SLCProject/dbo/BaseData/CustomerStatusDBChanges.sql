UPDATE Customer
SET CustomerStatusId = 3 where 
isActive = 0 and IsDeleted =1 

UPDATE Customer
SET CustomerStatusId = 1 where 
isActive = 1 

UPDATE Customer
SET CustomerStatusId = 4 where 
isActive = 0 and IsDeleted = 0

GO