----Remove duplicate GT entry for Project: 3993 ----------
-- Execute on Server 3----
UPDATE PGT
SET PGT.IsDeleted = 1
FROM ProjectGlobalTerm PGT
WHERE PGT.ProjectId = 3993
AND PGT.mGlobalTermId > 3000000
