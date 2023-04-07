CREATE PROCEDURE [dbo].[spb_LogErrors]
(
	@CycleID			BIGINT
	,@ErrorCode			INT
	,@ErrorStep			VARCHAR(50)
	,@Return_Message	VARCHAR(1024)
)
AS
BEGIN
	INSERT INTO [dbo].[Logging](ErrorCode, ErrorStep, ErrorMessage, Created, CycleID)
	VALUES(@ErrorCode, @ErrorStep, @Return_Message, GETDATE(), @CycleID)
END