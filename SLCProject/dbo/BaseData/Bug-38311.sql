/*
Resolve Customer Support 38311: SLC User Needs User RS Changed
server : SLCProject_SqlSlcOp002 (CustomerId-404)

for reference
Two reference standard update as per custmer requirement
One delete reference standard 'G707A'
*/


-----Update Refrence standard Name colum--
UPDATE RS set RS.RefStdName='AIA - G706' FROM ReferenceStandard RS WITH (NOLOCK) WHERE RS.CustomerId=404 AND RS.RefStdId=3097
UPDATE RS set RS.RefStdName='AIA - G707A' FROM ReferenceStandard RS WITH (NOLOCK) WHERE RS.CustomerId=404 AND RS.RefStdId=3096


---Delete Refrence standard --
DELETE From  referencestandard WHERE CustomerId=404 AND RefStdId=3095