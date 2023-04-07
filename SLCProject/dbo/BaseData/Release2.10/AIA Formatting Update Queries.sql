/*
Bug 30072: SLC - Master AIA Format Template Has Incorrect Setting for Level 3

Execute on All server.

Reference Queries: FYI
--select * from Template where IsSystem=1
--select * from TemplateStyle where TemplateId=5
--select * from Style where StyleId=40
--select * from Style where StyleId in (select StyleId from TemplateStyle where TemplateId=5)

Row Affected - 1

*/

-- For Level 3: The "Include Number from Previous Levels" needs to be deselected (originally reported in this track):
-- For Level 3: The Text Position is set to .6 and needs to be changed to .4:
update s   
set IncludePrevious=0,HangingIndent=576
from Style s with (nolock)
where StyleId=40 and Name='AIA Format Level 3'

-- For Level 2: The Text Position is set to .4, and needs to be changed to .6:
update s   
set HangingIndent=864
from Style s with (nolock)
where StyleId=39 and name ='AIA Format Level 2'
