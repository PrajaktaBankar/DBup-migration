--Excute it only server 3 db

Use [SLCProject_SqlSlcOp003]
GO

UPDATE   PSS SET PSS.SpecTypeTagId = 2 
From ProjectSegmentStatus PSS With(nolock)
WHERE PSS.ProjectId = 6267 AND 
ISNULL(PSS.IsDeleted,0)=0  AND 
PSS.SectionId = 5867218 AND PSS.SpecTypeTagId IS NULL


UPDATE PSS SET PSS.SpecTypeTagId = 2 
From ProjectSegmentStatus PSS With(nolock)
WHERE PSS.ProjectId = 9240 AND 
ISNULL(PSS.IsDeleted,0)=0  AND 
PSS.SectionId = 9319500 AND PSS.SpecTypeTagId IS NULL
