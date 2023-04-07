USE SLCProject
GO

ALTER TABLE ProjectPrintSetting
ADD IsIncludePdfBookmark BIT NOT NULL DEFAULT(0)


ALTER TABLE ProjectPrintSetting
ADD BookmarkLevel INT NOT NULL DEFAULT(0)
