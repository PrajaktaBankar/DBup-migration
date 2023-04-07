
--select * from ProjectPrintSetting

ALTER TABLE ProjectPrintSetting
ADD IsPrintMasterNote Bit NOT NULL DEFAULT 0
GO
ALTER TABLE ProjectPrintSetting
ADD IsPrintProjectNote Bit NOT NULL DEFAULT 0
GO
ALTER TABLE ProjectPrintSetting
ADD IsPrintNoteImage Bit NOT NULL DEFAULT 0
GO
ALTER TABLE ProjectPrintSetting
ADD IsPrintIHSLogo Bit NOT NULL DEFAULT 0
