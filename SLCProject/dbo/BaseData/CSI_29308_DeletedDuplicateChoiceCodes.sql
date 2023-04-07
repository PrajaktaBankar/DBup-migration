USE [SLCProject]

--Execute this script on Server-3

UPDATE sc
set sc.IsDeleted = 1
from SelectedChoiceOption sc WITH(NOLOCK)
WHERE sc.SelectedChoiceOptionId in (
385664996
,385664997
,385665071
,385665072
,414012041
);

GO