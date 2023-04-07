
CREATE PROCEDURE  [dbo].[usp_GetCustomerDataForPDFExport] 
   @CustomerId INT=0
AS  
BEGIN  
  
	SELECT [TemplateId],[Name],[TitleFormatId],[SequenceNumbering],[CustomerId],[IsSystem],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[MasterDataTypeId],[A_TemplateId],[ApplyTitleStyleToEOS]
	FROM [dbo].[Template]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	SELECT [TemplateStyleId],[TemplateId],[StyleId],[Level],[CustomerId],[A_TemplateStyleId]
	FROM [dbo].[TemplateStyle]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId


	SELECT [StyleId],[Alignment],[IsBold],[CharAfterNumber],[CharBeforeNumber],[FontName],[FontSize],[HangingIndent],[IncludePrevious],[IsItalic],[LeftIndent]
		  ,[NumberFormat],[NumberPosition],[PrintUpperCase],[ShowNumber],[StartAt],[Strikeout],[Name],[TopDistance],[Underline],[SpaceBelowParagraph]
		  ,[IsSystem],[CustomerId],[IsDeleted],[CreatedBy],[CreateDate],[ModifiedBy],[ModifiedDate],[Level],[MasterDataTypeId],[A_StyleId]
	FROM [dbo].[Style]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	SELECT [UserTagId],[CustomerId],[TagType],[Description],[SortOrder],[IsSystemTag],[CreateDate],[CreatedBy],[ModifiedDate],[ModifiedBy],[A_UserTagId]
	FROM [dbo].[ProjectUserTag]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	SELECT [RefStdId],[RefStdName],[RefStdSource],[ReplaceRefStdId],[ReplaceRefStdSource],[mReplaceRefStdId],[IsObsolete],[RefStdCode],[CreateDate],[CreatedBy],[ModifiedDate]
		  ,[ModifiedBy],[CustomerId],[IsDeleted],[IsLocked],[IsLockedByFullName],[IsLockedById],[A_RefStdId]
	FROM [dbo].[ReferenceStandard]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId


	SELECT [RefStdEditionId],[RefEdition],[RefStdTitle],[LinkTarget],[CreateDate],[CreatedBy],[RefStdId],[CustomerId],[ModifiedDate],[ModifiedBy],[A_RefStdEditionId]
	FROM [dbo].[ReferenceStandardEdition]  WITH (NOLOCK)
	WHERE ISNull(CustomerID,0)= @CustomerId

	IF (IsNull(@CustomerId,0)=0)
	Begin
	Select [ProjectPrintSettingId]
		  ,[ProjectId]
		  ,[CustomerId]
		  ,[CreatedBy]
		  ,[CreateDate]
		  ,[ModifiedBy]
		  ,[ModifiedDate]
		  ,[IsExportInMultipleFiles]
		  ,[IsBeginSectionOnOddPage]
		  ,[IsIncludeAuthorInFileName]
		  ,[TCPrintModeId]
		  ,[IsIncludePageCount]
		  ,[IsIncludeHyperLink]
		  ,[KeepWithNext]
		  ,[IsPrintMasterNote]
		  ,[IsPrintProjectNote]
		  ,[IsPrintNoteImage]
		  ,[IsPrintIHSLogo] 
	From ProjectPrintSetting WITH (NOLOCK)
	Where ProjectId is null and CustomerId is null
	End

END
