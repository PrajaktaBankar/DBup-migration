USE SLCProject
GO

CREATE SYNONYM [dbo].[usp_GetSegmentsForPrint] FOR [dbo].[usp_GetSegmentsForPrintPDF];
GO
CREATE SYNONYM [dbo].[usp_GetSpecDataSectionList] FOR [dbo].[usp_GetSpecDataSectionListPDF];
GO