USE [SLCProject_SqlSlcOp003]
GO

UPDATE PCO
SET IsDeleted = 1
FROM ProjectChoiceOption PCO WITH (NOLOCK)
WHERE ChoiceOptionId =159384251