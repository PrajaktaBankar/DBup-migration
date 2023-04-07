
--Customer Support 76748: Section incorrect order in TOC report
--Execute on Server 03
USE SLCProject_003
GO

UPDATE PS
SET
DivisionId=08,
DivisionCode='06'
FROM ProjectSection PS WITH (NOLOCK)
WHERE PS.SectionId IN (21905620,14026513,12129899,11345985)