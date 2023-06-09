CREATE Proc [dbo].[usp_ImportSectionStatusAddGetDelete]  
(  
@ProcessId Int,  
@StatusQueryGetUri NVARCHAR(max),  
@SendEventPostUri  NVARCHAR(max),  
@TerminatePostUri  NVARCHAR(max),  
@RevindPostUri  NVARCHAR(max),  
@Action int -- 1 For Insert, 2 for Select,  3 for Delete  
)  
AS  
Begin
  
DECLARE @PProcessId Int = @ProcessId;
DECLARE @PStatusQueryGetUri NVARCHAR(max) = @StatusQueryGetUri;
DECLARE @PSendEventPostUri  NVARCHAR(max) = @SendEventPostUri;
DECLARE @PTerminatePostUri  NVARCHAR(max) = @TerminatePostUri;
DECLARE @PRevindPostUri  NVARCHAR(max) = @RevindPostUri;
DECLARE @PAction int = @Action;
IF @PAction=1  
 Begin
INSERT INTO ImportSectionStatus (ProcessId, StatusQueryGetUri, SendEventPostUri, TerminatePostUri, RevindPostUri)
	VALUES (@PProcessId, @PStatusQueryGetUri, @PSendEventPostUri, @PTerminatePostUri, @RevindPostUri)
END
IF @PAction = 2
BEGIN
SELECT
	ProcessId
   ,StatusQueryGetUri
   ,SendEventPostUri
   ,TerminatePostUri
   ,RevindPostUri
FROM ImportSectionStatus WITH (NOLOCK)
WHERE ProcessId = @PProcessId
END
IF @PAction = 3
BEGIN
DELETE FROM ImportSectionStatus
WHERE ProcessId = @PProcessId
END
END

GO
