CREATE PROCEDURE [dbo].[usp_GetPendingRecordsToProcess]   
 @recordSize int  
  
AS  
BEGIN
  
DECLARE @PrecordSize int = @recordSize;
-- SET NOCOUNT ON added to prevent extra result sets from  
-- interfering with SELECT statements.  
SET NOCOUNT ON;

SELECT TOP (@PrecordSize)
	Id
   ,JsonData
   ,CreateDate
   ,ModifiedDate
   ,ProcessingStatus
FROM LinkProcessorRecords WITH (NOLOCK)
WHERE ProcessingStatus = 0
AND ModifiedDate IS NULL
ORDER BY CreateDate ASC
END

GO
