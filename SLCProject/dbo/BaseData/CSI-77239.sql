--Execute this on Server 4
--Customer Support 77239: SLC: Unable To Print/Export Section
--Record will be affected 1

Update ProjectChoiceOption
Set OptionJson = '[{"OptionTypeId":1,"OptionTypeName":"CustomText","SortOrder":3,"Value":" Wood Profile Marlite W770 9⁄16” x 1” x 8’-0 Poplar, for field finishing.","MValue":null,"DefaultValue":null,"Id":0,"ValueJson":null,"MValueJson":null,"TempSortOrder":0.0,"IsdeletedSectionId":false,"IncludeSectionTitle":false,"PrevTrackValue":null,"PrevTrackValueJson":null}]'
Where ChoiceOptionId = 307860565 And ProjectId = 26892 And CustomerId = 1681