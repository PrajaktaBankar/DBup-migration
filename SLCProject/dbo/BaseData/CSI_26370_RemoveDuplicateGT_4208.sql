
----Remove duplicate GT entry for Project: 4208 ----------
----Execute on Server 3---------------
UPDATE PGT
SET PGT.IsDeleted = 1
FROM ProjectGlobalTerm PGT
WHERE PGT.ProjectId = 4208
AND PGT.mGlobalTermId > 3000000
