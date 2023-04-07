--Execute it on All Server
--Bug 30825: Division template sections are displaying under unassigned sections division

use SLCProject
go

update S set S.divisionId = 38, S.DivisionCode = 99
From  SLCMaster..Section S
where S.SourceTag = '999999.03'
and s.SectionId = 1125

update PS SET PS.divisionId = 38, PS.DivisionCode = 99  
From ProjectSection PS where PS.SourceTag = '999999.03'
 