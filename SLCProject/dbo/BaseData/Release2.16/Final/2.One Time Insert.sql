USE SLCProject
GO

INSERT INTO LuExportFileFormatCategory Values('ForDocument')
INSERT INTO LuExportFileFormatCategory Values('ForProjectReport')

INSERT INTO FileNameFormatProperties Values('Identifier','{C}','',1,1,NULL,NULL,0,GETDATE(),0,GETDATE())
INSERT INTO FileNameFormatProperties Values('SectionId','{S}','',1,0,NULL,NULL,0,GETDATE(),0,GETDATE())
INSERT INTO FileNameFormatProperties Values('Title','{T}','',1,1,NULL,NULL,0,GETDATE(),0,GETDATE())
INSERT INTO FileNameFormatProperties Values('Date','{D}','',1,1,NULL,NULL,0,GETDATE(),0,GETDATE())

INSERT INTO FileNameFormatSetting Values(1,1,'-','{S}-{T}-{D:dd-MM-yyyy@}',NULL,NULL)
INSERT INTO FileNameFormatSetting Values(2,1,'-','{T}-{D:dd-MM-yyyy@}',NULL,NULL)

INSERT INTO LuFacilityType values('IndusWareho','Industrial Warehouse',1,191)
INSERT INTO LuFacilityType values('DataCen','Data Center',1,192)