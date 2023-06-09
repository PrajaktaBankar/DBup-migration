CREATE PROCEDURE [dbo].[usp_UpdateLinkProcessorsProcessingStatus] 
	-- Add the parameters for the stored procedure here
	@Id int, 
	@ProcessingStatus int
AS
BEGIN
	DECLARE @PId int = @Id;
	DECLARE @PProcessingStatus int = @ProcessingStatus;
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Insert statements for procedure here
UPDATE LinkProcessorRecords
SET ModifiedDate = GETDATE()
   ,ProcessingStatus = @PProcessingStatus
WHERE Id = @PId
END

GO
