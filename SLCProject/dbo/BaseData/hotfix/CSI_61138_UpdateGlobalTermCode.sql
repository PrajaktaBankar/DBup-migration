/* 
server name : SLCProject_SqlSlcOp005 
Customer Support 61138: Wrong global terms - 72355
*/


UPDATE PGT 
SET PGT.GlobalTermCode = 10000001
FROM ProjectGlobalTerm PGT WITH (NOLOCK)
WHERE PGT.CustomerId =4267 
AND PGT.GlobalTermSource = 'U' 
AND PGT.GlobalTermCode=23