CREATE PROCEDURE [dbo].[usp_UpdateLongRunningRequestsASFailed]
AS
BEGIN
	UPDATE cpr
	SET cpr.StatusId=5
		,cpr.IsNotify=0
		,cpr.IsEmailSent=0
		,ModifiedDate=GETUTCDATE()
	FROM CopyProjectRequest cpr WITH(nolock) INNER JOIN CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2  AND cpr.CopyProjectTypeId=1


END