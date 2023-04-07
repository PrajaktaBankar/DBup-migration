
use SLCProject

ALTER TABLE ProjectPrintSetting
ADD IsMarkPagesAsBlank BIT NOT NULL DEFAULT(0)


ALTER TABLE ProjectPrintSetting
ADD IsIncludeHeaderFooterOnBlackPages BIT NOT NULL DEFAULT(0)

ALTER TABLE ProjectPrintSetting
ADD BlankPagesText nvarchar(250) 