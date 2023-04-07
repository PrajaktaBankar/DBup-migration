/*
 server name : ALL server 
 Customer Support 62497: SLC User Cannot Import Sections from Master; Div 20 in Master is Not in Numerical Order
*/

-- Time for execution 
--server 01 - 1 sec
--server 02 - 2 sec
--server 03 - 2 sec
--server 04 - 2 sec
--server 05 - 2 sec

--server 07 - 0 sec
Update SLCMaster..Section set SourceTag='20' where SourceTag like '200'
Update SLCMaster..Section set SourceTag='02' where SourceTag like '020'

Update SLCMasterStaging..SectionsStaging set SourceTag='20' where SourceTag like '200'
Update SLCMasterStaging..SectionsStaging set SourceTag='02' where SourceTag like '020'

update PS set PS.SourceTag = '20' 
from Projectsection PS with(nolock)
where SourceTag = '200'  
and Description like 'Division 20 - Facility Services' 

update PS set PS.SourceTag = '02' 
from Projectsection PS with(nolock)
where SourceTag = '020' 
and Description like 'Division 02 - Existing Conditions' 
