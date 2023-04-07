USE SLCProject
GO
--Customer Support 34241: Export from PDF Download Error ( CID = 40860 / AID = 530 )
--Excute on server 03
UPDATE P 
SET P.Name=REPLACE( P.Name,'–','-')
from Project P WITH(NOLOCK) where ProjectId =6858 and name like '%–%'