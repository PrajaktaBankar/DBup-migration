-- Execute on Server 2 
-- CSI-45025: SLC Modified Exclusive Choices has two options selected after closing section - 68843

UPDATE sch
SET IsDeleted =1
FROM SelectedChoiceOption sch WITH (NOLOCK)
WHERE sch.SelectedChoiceOptionId IN (330086329 ,
550388385,548238703,548238704,548238705)

UPDATE sch
SET IsSelected =0
FROM SelectedChoiceOption sch WITH (NOLOCK)
WHERE sch.SelectedChoiceOptionId IN (548238706 ,
548238696,550388386,552784222,552976164,548237165)