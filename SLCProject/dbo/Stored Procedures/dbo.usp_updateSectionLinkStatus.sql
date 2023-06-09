CREATE PROCEDURE [dbo].[usp_updateSectionLinkStatus]  
(  
  @ProjectId int ,    
  @sectionId int,  
  @vimId int ,    
  @linkStatus bit,  
  @MaterialId NVARCHAR(MAX),  
  @userId int  
)  
AS  
BEGIN
  
  DECLARE @PProjectId int = @ProjectId;
  DECLARE @PsectionId int = @sectionId;
  DECLARE @PvimId int = @vimId;
  DECLARE @PlinkStatus bit = @linkStatus;
  DECLARE @PMaterialId NVARCHAR(MAX) = @MaterialId;
  DECLARE @PuserId int = @userId;

 IF(@PlinkStatus=1)  
 BEGIN
  
  declare @customerId int
SELECT
	@customerId = customerId
FROM Project WITH (NOLOCK)
WHERE ProjectId = @PProjectId
INSERT INTO LinkedSections (ProjectId,
SectionId,
VimId,
MaterialId,
Linkedby,
LinkedDate,
customerId)
	SELECT
		@PProjectId
	   ,@PsectionId
	   ,@PvimId
	   ,splitdata
	   ,@PuserId
	   ,GETUTCDATE()
	   ,@customerId
	FROM dbo.fn_SplitString(@PMaterialId, ',') AS M_Ids
--WHERE ms.ProjectId=@PProjectId and RevitFileId=@PvimId  
--AND ms.SectionId=@PsectionId  

IF (@@rowcount > 0)
BEGIN
UPDATE UF
SET UF.LastAccessed = GETUTCDATE()
   ,UF.UserId = @PuserId
   FROM UserFolder UF WITH (NOLOCK)
WHERE UF.ProjectId = @PProjectId

END
END
ELSE
BEGIN
DELETE ls
	FROM LinkedSections ls
	INNER JOIN dbo.fn_SplitString(@PMaterialId, ',') AS M_Ids
		ON ls.MaterialId = M_Ids.splitdata
WHERE ls.ProjectId = @PProjectId
	AND ls.vimId = @PvimId
	AND ls.SectionId = @PsectionId

IF (@@rowcount > 0)
BEGIN 
UPDATE UF
SET UF.LastAccessed = GETUTCDATE()
   ,UF.UserId = @PuserId
   FROM UserFolder UF WITH (NOLOCK)
WHERE UF.ProjectId = @PProjectId
END
END
END

GO
