
CREATE PROCEDURE  [dbo].[usp_DeleteCustomerDataForPDFExport]   
AS  
BEGIN 
	Truncate Table TemplatePDF
	Truncate Table TemplateStylePDF
	Truncate Table StylePDF
	Truncate Table ProjectUserTagPDF
	Truncate Table ReferenceStandardPDF
	Truncate Table ReferenceStandardEditionPDF
	Truncate Table ProjectPrintSettingPDF
END