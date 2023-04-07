CREATE PROCEDURE [dbo].[usp_UpdateCopyProjectStepProgress]
AS
BEGIN

   	--find and mark as failed copy project requests which running loner(more than 30 mins)
	SELECT cpr.RequestId into #longRunningRequests
	FROM dbo.CopyProjectRequest cpr WITH(nolock) 
	INNER JOIN dbo.CopyProjectHistory cph WITH(NOLOCK)
	ON cpr.RequestId=cph.RequestId
	WHERE cpr.StatusId = 2 
	AND CPR.CopyProjectTypeId=1
	and cph.CreatedDate < DATEADD(MINUTE,-30,GETUTCDATE())
	and cph.Step=2

	IF(EXISTS(select top 1 1 from #longRunningRequests))
	BEGIN
		UPDATE cpr
		SET cpr.StatusId=5
			,cpr.IsNotify=0
			,cpr.IsEmailSent=0
			,cpr.ModifiedDate=GETUTCDATE()
		FROM dbo.CopyProjectRequest cpr WITH(nolock) 
		INNER JOIN #longRunningRequests cph WITH(NOLOCK)
		ON cpr.RequestId=cph.RequestId
	END
END;
