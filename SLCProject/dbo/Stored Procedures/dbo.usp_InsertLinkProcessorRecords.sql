CREATE PROCEDURE [dbo].[usp_InsertLinkProcessorRecords] 
	-- Add the parameters for the stored procedure here
	@jsonData nvarchar(max)
	
AS
BEGIN
	DECLARE @PjsonData nvarchar(max) = @jsonData;
-- SET NOCOUNT ON added to prevent extra result sets from
-- interfering with SELECT statements.
SET NOCOUNT ON;

-- Insert statements for procedure here
INSERT INTO LinkProcessorRecords (JsonData, CreateDate, ModifiedDate, ProcessingStatus)
	VALUES (@PjsonData, GETDATE(), NULL, 0)

END

GO
