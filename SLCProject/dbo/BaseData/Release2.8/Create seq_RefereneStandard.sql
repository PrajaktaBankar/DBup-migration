USE [SLCProject]
GO

--1. Drop the trigger
IF EXISTS(SELECT * FROM sys.objects WHERE [name] = N'trg_InsertReferenceStandard' AND [type] = 'TR')
DROP TRIGGER trg_InsertReferenceStandard
GO

DECLARE @maxRefStdCode BIGINT = 0
DECLARE @dynamicSql nvarchar(2000)

SET @maxRefStdCode = (Select max(RefStdCode) + 1 from ReferenceStandard with (nolock))

--print @maxSectionCode

SET @dynamicSql = 'CREATE SEQUENCE [dbo].[seq_ReferenceStandard] 
 AS [bigInt]
 START WITH '+ CONVERT(NVARCHAR(100), @maxRefStdCode) +
 ' INCREMENT BY 1
 MINVALUE 1
 MAXVALUE 9223372036854775807
 NO CACHE';

--print @dynamicSql

IF EXISTS(SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[seq_ReferenceStandard]') AND type = 'SO')
BEGIN
	
	--Execute below commented statement if constraints exists
	--ALTER TABLE ReferenceStandard DROP CONSTRAINT [Default_ReferenceStandard_RefStdCode]
	
	DROP Sequence seq_ReferenceStandard
END

EXECUTE sp_executesql @dynamicSql

ALTER TABLE [dbo].ReferenceStandard ADD  CONSTRAINT [Default_ReferenceStandard_RefStdCode]  DEFAULT (NEXT VALUE FOR [seq_ReferenceStandard]) FOR RefStdCode
GO
