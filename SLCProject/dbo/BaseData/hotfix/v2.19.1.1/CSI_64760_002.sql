--Customer Support 64760: SLC - No Spacing Between Divisions When Exporting to PDF in Outline View

--code fix(SP - Get Segments print ) + data fix _SqlSlcOp002
USE SLCProject
GO
 
UPDATE ProjectSection 
SET DivisionId=11,
DivisionCode='09'
WHERE ProjectId=15463 AND CustomerId=2098 AND SectionId IN (19437670,19434883)