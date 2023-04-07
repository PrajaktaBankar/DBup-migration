/*
server Name : SLCProject_SqlSlcOp001,SLCProject_SqlSlcOp002,SLCProject_SqlSlcOp003,SLCProject_SqlSlcOp004
Customer Support 30728: Section 260923:LUT was deleted by accident by master editors and they want it back.
*/

use SLCMaster
go​
update sec
set isdeleted=0
from section sec with (Nolock)
where SourceTag='260923' and Author='LUT' and MasterDataTypeId=1​



use SLCMasterStaging
go
update secstg
set isdeleted=0
from [SectionsStaging] secstg with (Nolock)
where SourceTag='260923' and Author='LUT' and MasterDataTypeId=1​ and sectionid=807