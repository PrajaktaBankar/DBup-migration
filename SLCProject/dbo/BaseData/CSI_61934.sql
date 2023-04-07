--csi-61934 Sections Cannot be deleted
--server-3


UPDATE PCO 
SET PCO.OptionJson='[{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":2,"Value":" to be incorporated in the Contract Sum by Contractor. See Section 012100 Allowances for cash allowance for purchase contract","MValue":null,"DefaultValue":null,"Id":0,"ValueJson":null,"MValueJson":null,"TempSortOrder":0.0,"IsdeletedSectionId":false,"IncludeSectionTitle":false,"PrevTrackValue":null,"PrevTrackValueJson":null}]'
FROM ProjectChoiceOption as PCO WITH (nolock)
WHERE  ProjectId = 6545  AND CustomerId = 294  AND ChoiceOptionId=157065700

UPDATE PCO 
SET PCO.OptionJson='[{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":2,"Value":" to be incorporated in the Contract Sum by Contractor. See Section 012100 Allowances for cash allowance for purchase contract","MValue":null,"DefaultValue":null,"Id":0,"ValueJson":null,"MValueJson":null,"TempSortOrder":0.0,"IsdeletedSectionId":false,"IncludeSectionTitle":false,"PrevTrackValue":null,"PrevTrackValueJson":null}]'
FROM ProjectChoiceOption as PCO WITH (nolock)
WHERE  ProjectId = 6545  AND CustomerId = 294  AND ChoiceOptionId=157438185