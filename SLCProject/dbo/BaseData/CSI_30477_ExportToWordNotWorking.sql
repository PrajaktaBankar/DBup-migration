--Execute this on Server 4
update SCO 
SET SCO.IsDeleted = 1
FROM SelectedChoiceOption SCO WITH (NOLOCK)
where SCO.SegmentChoiceCode = 68013 and SCO.ProjectId = 214 
      and SCO.SectionId = 242919 and SCO.ChoiceOptionCode= 166498 and SCO.CustomerId = 1431