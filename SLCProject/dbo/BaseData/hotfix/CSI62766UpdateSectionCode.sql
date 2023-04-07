/*
Customer Support 62766: SLC Global Terms and Section ID Are Incorrect

Server:4

-------------Description-------------
duplicate sectioncode in different section so we have updated sectioncode 

select * from ProjectSection where SourceTag in ('003300','003300.01') and ProjectId = 6585 and CustomerId=3155

*/


Update PCO 
set PCO.OptionJson='[{"OptionTypeId":0,"OptionTypeName":"SectionID","SortOrder":0,"Value":"003300 - BUSINESS & LOCAL WORKFORCE INCLUSION PLAN","MValue":null,"DefaultValue":"003300:USER:BUSINESS & LOCAL WORKFORCE INCLUSION PLAN","Id":10013384,"ValueJson":null,"MValueJson":null,"TempSortOrder":0.0,"IsdeletedSectionId":false,"IncludeSectionTitle":true,"PrevTrackValue":null,"PrevTrackValueJson":null}]'
From ProjectChoiceOption PCO WITH(NOLOCK)  WHERE  PCO.SegmentChoiceId=83490758 and PCO.SectionId=7596969 and PCO.projectid=6585


Update PS
set PS.sectioncode=10013384  From Projectsection PS WITH(NOLOCK)  where PS.SectionId=24083197 and PS.ProjectId=6585

Update PSL set PSL.SourceSectionCode=10013384 From   ProjectSegmentLink PSL WITH(NOLOCK)  
where PSL.TargetSectionCode=15  and PSL.TargetSegmentStatusCode=14399280 and PSL.ProjectId=6585 and PSL.CustomerId=3155 
