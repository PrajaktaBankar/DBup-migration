USE [SLCProject_SqlSlcOp004]
GO

UPDATE PS SET PS.IsLocked = 0 
FROM ProjectSection PS   with(nolock)
WHERE PS.ProjectId = 11268 
AND PS.SourceTag = '000101'