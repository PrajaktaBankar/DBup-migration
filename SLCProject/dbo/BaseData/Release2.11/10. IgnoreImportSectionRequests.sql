UPDATE req
SET req.StatusId=4
FROM ImportProjectRequest req WITH(nolock)
WHERE req.StatusId IN(1,2) and Source='Import from Template'