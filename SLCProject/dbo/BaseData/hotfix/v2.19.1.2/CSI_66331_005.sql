--Customer Support 66331: Automatic Table of Contents is Incorrect => Code fix + doc api fix [SLCProject_SqlSlcOp005]

USE  [SLCProject]
GO

UPDATE ProjectSection
SET DivisionId=3000011
, DivisionCode='99'
WHERE ProjectId=5932 AND CustomerId=4096 AND SectionId=8387748