CREATE PROCEDURE [dbo].[usp_DeleteProjectSegmentGlobalTerms](
@UserGlobalTermId INT,
@GlobalTermCode INT,
@SectionId INT,
@ProjectId INT,
@CustomerId INT
)
AS
BEGIN
DECLARE @PUserGlobalTermId INT = @UserGlobalTermId;
DECLARE @PGlobalTermCode INT = @GlobalTermCode;
DECLARE @PSectionId INT = @SectionId;
DECLARE @PProjectId INT = @ProjectId;
DECLARE @PCustomerId INT = @CustomerId;
	
	IF EXISTS (select top 1 1 from ProjectSegmentGlobalTerm with (nolock)
	where UserGlobalTermId=@PUserGlobalTermId and GlobalTermCode=@PGlobalTermCode and SectionId=@PSectionId and ProjectId=@PProjectId and CustomerId=@PCustomerId )
	BEGIN 
		UPDATE PSGT 
		SET IsDeleted = 1
		from ProjectSegmentGlobalTerm PSGT  WITH (NOLOCK) where UserGlobalTermId=@PUserGlobalTermId and GlobalTermCode=@PGlobalTermCode and SectionId=@PSectionId and ProjectId=@PProjectId and CustomerId=@PCustomerId 
	END  

END


GO
