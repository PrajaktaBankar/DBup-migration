CREATE PROC usp_EnableDisableLinkEngine
(
	@ProjectId INT,
	@CustomerId INT,
	@UserId INT=0,
	@isLinkEngineServiceEnabled BIT
)
AS
BEGIN
	update ps 
	set ps.IsLinkEngineEnabled=@isLinkEngineServiceEnabled 
	from ProjectSummary ps WITH (NOLOCK) 
	where projectId=@ProjectId and CustomerId=@CustomerId
END