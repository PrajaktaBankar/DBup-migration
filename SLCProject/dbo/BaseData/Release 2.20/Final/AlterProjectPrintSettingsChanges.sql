use SLCProject

ALTER TABLE ProjectPrintSetting
ADD IncludeEndOfSection BIT NOT NULL DEFAULT (1)

ALTER TABLE ProjectPrintSetting
ADD IncludeDivisionNameandNumber BIT NOT NULL DEFAULT (1)