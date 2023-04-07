USE [SLCProject]
GO

--1. Drop the trigger
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = N'trg_InsertProjectSection' AND [type] = 'TR')
DROP TRIGGER trg_InsertProjectSection
GO

DECLARE @maxSectionCode BIGINT = 0
DECLARE @dynamicSql nvarchar(2000)

SET @maxSectionCode = (Select max(sectionCode) + 1 from ProjectSection with (nolock))

--print @maxSectionCode

SET @dynamicSql = 'CREATE SEQUENCE [dbo].[seq_ProjectSection] 
 AS [bigInt]
 START WITH '+ CONVERT(NVARCHAR(100), @maxSectionCode) +
 ' INCREMENT BY 1
 MINVALUE 1
 MAXVALUE 9223372036854775807
 NO CACHE';

--print @dynamicSql

IF EXISTS(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[seq_ProjectSection]') AND type = 'SO')
BEGIN
	
	--Execute below commented statement if constraints exists
	--ALTER TABLE ProjectSection DROP CONSTRAINT [Default_ProjectSection_SectionCode]
	
	DROP Sequence seq_ProjectSection
END

EXECUTE sp_executesql @dynamicSql

ALTER TABLE [dbo].ProjectSection ADD  CONSTRAINT [Default_ProjectSection_SectionCode]  DEFAULT (NEXT VALUE FOR [seq_ProjectSection]) FOR [SectionCode]
GO
