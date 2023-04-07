/*
Execute on Server 02.
*/

UPDATE PS
SET PS.SegmentDescription ='<span style="">Color:  {CH#10004974}{ch#1}.</span>'
FROM ProjectSegment PS WITH (NOLOCK)
where PS.SegmentId=44360581


UPDATE PS
SET SegmentDescription ='<span style="">Controller Enclosure:  {rs#1}, Type {CH#10017428}.</span>'
FROM ProjectSegment PS WITH (NOLOCK)
where SegmentId=44398198

UPDATE PCO 
SET PCO.OptionJson='[{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":1,"Value":", and galvanized to","DefaultValue":null,"Id":0,"ValueJson":null},{"OptionTypeId":5,"OptionTypeName":"ReferenceStandard","SortOrder":2,"Value":"{rs#1}","DefaultValue":null,"Id":0,"ValueJson":null},{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":3,"Value":"where connecting galvanized components","DefaultValue":null,"Id":0,"ValueJson":null}]'
FROM ProjectChoiceOption PCO WITH (NOLOCK)
WHERE PCO.ChoiceOptionId=1722814357

UPDATE PCO 
SET OptionJson='[{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":1,"Value":"10 cycles, when tested in accordance with","DefaultValue":null,"Id":0,"ValueJson":null},{"OptionTypeId":5,"OptionTypeName":"ReferenceStandard","SortOrder":2,"Value":"{rs#1}","DefaultValue":null,"Id":2350,"ValueJson":null}]'
FROM ProjectChoiceOption PCO WITH (NOLOCK)
WHERE ChoiceOptionId=1722820590

UPDATE PCO 
SET OptionJson='[{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":1,"Value":"10 cycles, when tested in accordance with","DefaultValue":null,"Id":0,"ValueJson":null},{"OptionTypeId":5,"OptionTypeName":"ReferenceStandard","SortOrder":2,"Value":"{rs#1}","DefaultValue":null,"Id":1583583,"ValueJson":null},{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":3,"Value":"or","DefaultValue":null,"Id":0,"ValueJson":null},{"OptionTypeId":5,"OptionTypeName":"ReferenceStandard","SortOrder":4,"Value":"{rs#2}","DefaultValue":null,"Id":2,"ValueJson":null}]'
FROM ProjectChoiceOption PCO WITH (NOLOCK)
WHERE ChoiceOptionId=1722820609

UPDATE PS
SET SegmentDescription ='<span style="">Controller Enclosure:  {rs#1}, Type {CH#50522}.</span>'
FROM ProjectSegment PS WITH (NOLOCK)
where PS.SegmentId=44360005