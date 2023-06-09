
CREATE PROCEDURE [dbo].[usp_MapSegmentRequirementTagFromMasterToProject]  
 @ProjectId INT NULL, @SectionId INT NULL, @CustomerId INT NULL, @UserId INT NULL, @MasterSectionId INT = NULL      
AS      
BEGIN  
SET NOCOUNT ON;  
DECLARE @PProjectId INT = @ProjectId;  
DECLARE @PSectionId INT = @SectionId;  
DECLARE @PCustomerId INT = @CustomerId;  
DECLARE @PUserId INT = @UserId;  
  
DECLARE @PMasterSectionId AS INT = @MasterSectionId ;
DECLARE @PSectionModifiedDate datetime2=null
DECLARE @IsMasterSection BIT=0
      
--NOTE:VIMP: DO NOT UNCOMMENT BELOW IF CONDITION OTHERWISE NEW TAGS UPDATES TO EXISTING PROJECTS WON'T WORK  
--NOTE:Called from   
--1.usp_GetSegmentLinkDetails  
--2.usp_GetSegments  
--3.usp_ApplyNewParagraphsUpdates  
  
 --IF NOT EXISTS (SELECT TOP 1  
 -- PSRT.SegmentRequirementTagId  
 --FROM [dbo].[ProjectSegmentRequirementTag] AS PSRT WITH (NOLOCK)  
 --WHERE PSRT.ProjectId = @PProjectId  
 --AND PSRT.CustomerId = @PCustomerId  
 --AND PSRT.SectionId = @PSectionId)  
	BEGIN
		--IF ISNULL(@PMasterSectionId,0) = 0
		--Begin
		--	SET @PMasterSectionId = (SELECT TOP 1 PS.mSectionId FROM [dbo].ProjectSection PS WITH (NOLOCK) WHERE PS.SectionId = @PSectionId);  
		--End;
		SELECT TOP 1
			@PSectionModifiedDate=DataMapDateTimeStamp
		,@PMasterSectionId=mSectionId
		,@IsMasterSection=iif(mSectionId IS NOT NULL,1,0)
		FROM dbo.ProjectSection WITH (NOLOCK)
		WHERE SectionId = @PSectionId
		OPTION (FAST 1);

		IF(@IsMasterSection=1 AND (dateadd(HOUR,-6,GETUTCDATE())>=@PSectionModifiedDate OR @PSectionModifiedDate IS NULL))
		BEGIN
			DROP TABLE IF EXISTS #TempProjectSegmentStatus;  
			SELECT  
				 PSS.SegmentStatusId
				,PSS.mSegmentStatusId
				,PSS.SectionId
				,PSS.ProjectId
				,PSS.CustomerId
			INTO #TempProjectSegmentStatus  
			FROM [dbo].ProjectSegmentStatus PSS WITH (NOLOCK)  
			WHERE PSS.SectionId = @PSectionId
			AND PSS.ProjectId = @PProjectId  
			AND PSS.CustomerId = @PCustomerId;

			DROP TABLE IF EXISTS #TempProjectSegmentRequirementTag;  
			SELECT  
				 PSRT.SectionId
				,PSRT.ProjectId
				,PSRT.CustomerId
				,PSRT.mSegmentRequirementTagId
				,PSRT.SegmentRequirementTagId
			INTO #TempProjectSegmentRequirementTag
			FROM [dbo].ProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
			WHERE PSRT.ProjectId = @PProjectId AND PSRT.SectionId = @PSectionId;
			--AND PSRT.CustomerId = @PCustomerId;
  
			INSERT INTO [dbo].ProjectSegmentRequirementTag (SectionId, SegmentStatusId, RequirementTagId, CreateDate, ModifiedDate, ProjectId, CustomerId, CreatedBy, ModifiedBy, mSegmentRequirementTagId)  
		SELECT
			 PSST.SectionId  
			,PSST.SegmentStatusId  
			,MSRT.RequirementTagId  
			,GETUTCDATE() AS CreateDate  
			,GETUTCDATE() AS ModifiedDate  
			,@PProjectId AS ModifiedDate  
			,@PCustomerId AS CustomerId  
			,@PUserId AS CreatedBy  
			,@PUserId AS ModifiedBy  
			,MSRT.SegmentRequirementTagId AS mSegmentRequirementTagId  
		 FROM [SLCMaster].[dbo].SegmentRequirementTag MSRT WITH (NOLOCK)  
		 INNER JOIN [dbo].LuProjectRequirementTag LuPRT WITH (NOLOCK)  
		  ON MSRT.RequirementTagId = LuPRT.RequirementTagId  
		 INNER JOIN #TempProjectSegmentStatus PSST WITH (NOLOCK)  
		  ON MSRT.SegmentStatusId = PSST.mSegmentStatusId  
		 LEFT JOIN #TempProjectSegmentRequirementTag PSRT WITH (NOLOCK)  
		  ON PSRT.SectionId = @PSectionId
		   AND PSRT.ProjectId = @PProjectId
		   AND PSRT.CustomerId = @PCustomerId
		   AND PSRT.mSegmentRequirementTagId IS NOT NULL  
		   AND PSRT.mSegmentRequirementTagId = MSRT.SegmentRequirementTagId
		WHERE PSST.SectionId = @PSectionId
		 AND PSST.ProjectId = @PProjectId  
		 AND PSST.CustomerId = @PCustomerId
		 AND MSRT.SectionId = @PMasterSectionId
		 AND PSRT.SegmentRequirementTagId IS NULL
		END
	END
END
GO


