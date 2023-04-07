USE SLCProject
GO

ALTER TABLE ProjectPrintSetting
ADD IsIncludeOrphanParagraph BIT NOT NULL DEFAULT(0)