
CREATE PROCEDURE [dbo].[usp_MapSegmentChoiceFromMasterToProject]
	@ProjectId INT NULL
	,@SectionId INT NULL
	,@CustomerId INT NULL
	,@UserId INT NULL
	,@MasterSectionId INT = NULL
AS
BEGIN
	DECLARE @PProjectId INT = @ProjectId;
	DECLARE @PSectionId INT = @SectionId;
	DECLARE @PCustomerId INT = @CustomerId;
	DECLARE @PSectionModifiedDate datetime2=null
	DECLARE @PUserId INT = @UserId;
	--DECLARE @SProjectId NVARCHAR(20) = convert(NVARCHAR, @ProjectId);
	--DECLARE @SSectionId NVARCHAR(20) = convert(NVARCHAR, @SectionId);
	--DECLARE @SCustomerId NVARCHAR(20) = convert(NVARCHAR, @CustomerId);
	--DECLARE @SUserId NVARCHAR(20) = convert(NVARCHAR, @UserId);

	DECLARE @PMasterSectionId AS INT = @MasterSectionId;

 --NOTE:VIMP: DO NOT UNCOMMENT BELOW IF CONDITION OTHERWISE UNCOIPED CHOICES WILL NOT WORK            
 --NOTE:Called from             
 --1.usp_GetSegmentLinkDetails            
 --2.usp_GetSegments            
 --3.usp_ApplyNewParagraphsUpdates            
 --IF NOT EXISTS (SELECT TOP 1            
 --  SCHOP.SelectedChoiceOptionId            
 -- FROM [dbo].[SelectedChoiceOption] AS SCHOP WITH (NOLOCK)            
 -- WHERE SCHOP.SectionId = @PSectionId            
 -- AND SCHOP.[ProjectId] = @PProjectId            
 -- AND SCHOP.CustomerId = @PCustomerId            
 -- AND SCHOP.ChoiceOptionSource = 'M')            
 --BEGIN  

	SELECT TOP 1
	@PMasterSectionId = mSectionId
	,@PSectionModifiedDate=DataMapDateTimeStamp
	FROM dbo.ProjectSection WITH (NOLOCK)
	WHERE SectionId = @PSectionId
	OPTION (FAST 1);

	DROP TABLE IF EXISTS #tmpMasterChoices;

	SELECT SegmentChoiceCode
	,ChoiceOptionCode
	--,SelectedChoiceOptionId
	,SectionId
	INTO #tempSelectedChoiceOption
	FROM SelectedChoiceOption PSCHOP WITH (NOLOCK)
	WHERE PSCHOP.ProjectId = @PProjectId AND PSCHOP.CustomerId = @PCustomerId AND PSCHOP.SectionId = @PSectionId
	AND PSCHOP.ChoiceOptionSource = 'M';

	SELECT MCH.SegmentChoiceCode
	,MCHOP.ChoiceOptionCode
	,MSCHOP.ChoiceOptionSource
	,MSCHOP.IsSelected
	,@PProjectId AS ProjectId
	,@PCustomerId AS CustomerId
	,@PSectionId AS SectionId
	INTO #tmpMasterChoices
	FROM SLCMaster..SegmentStatus MST WITH (NOLOCK)
	INNER JOIN SLCMaster..SegmentChoice AS MCH WITH (NOLOCK) ON MCH.SectionId=MST.SectionId and MCH.SegmentStatusId = MST.SegmentStatusId
	INNER JOIN SLCMaster..ChoiceOption AS MCHOP WITH (NOLOCK) ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
	INNER JOIN SLCMaster..SelectedChoiceOption AS MSCHOP WITH (NOLOCK) ON MCH.SectionId = MSCHOP.SectionId
	AND MSCHOP.SegmentChoiceCode=MCH.SegmentChoiceCode
	AND MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode
	WHERE MCH.SectionId = @PMasterSectionId

	INSERT INTO SelectedChoiceOption (
	SegmentChoiceCode
	,ChoiceOptionCode
	,ChoiceOptionSource
	,IsSelected
	,ProjectId
	,CustomerId
	,SectionId
	)
	SELECT MC.SegmentChoiceCode
	,MC.ChoiceOptionCode
	,MC.ChoiceOptionSource
	,MC.IsSelected
	,MC.ProjectId
	,MC.CustomerId
	,MC.SectionId
	FROM #tmpMasterChoices MC
	LEFT JOIN #tempSelectedChoiceOption PSCHOP
	ON PSCHOP.SectionId = MC.SectionId
	AND PSCHOP.SegmentChoiceCode = MC.SegmentChoiceCode
	AND PSCHOP.ChoiceOptionCode = MC.ChoiceOptionCode
	WHERE PSCHOP.SegmentChoiceCode IS NULL  
 
		----INSERT INTO SelectedChoiceOption (
		----SegmentChoiceCode
		----,ChoiceOptionCode
		----,ChoiceOptionSource
		----,IsSelected
		----,ProjectId
		----,CustomerId
		----,SectionId
		----)
		----SELECT MCH.SegmentChoiceCode
		----,MCHOP.ChoiceOptionCode
		----,MSCHOP.ChoiceOptionSource
		----,MSCHOP.IsSelected
		----,@PProjectId
		----,@PCustomerId
		----,@PSectionId
		
		----FROM SLCMaster..SegmentStatus MST WITH (NOLOCK)
		----INNER JOIN SLCMaster..SegmentChoice AS MCH WITH (NOLOCK) ON MCH.SectionId=MST.SectionId and MCH.SegmentStatusId = MST.SegmentStatusId
		----INNER JOIN SLCMaster..ChoiceOption AS MCHOP WITH (NOLOCK) ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId
		----INNER JOIN SLCMaster..SelectedChoiceOption AS MSCHOP WITH (NOLOCK) ON MCH.SectionId = MSCHOP.SectionId
		----AND MSCHOP.SegmentChoiceCode=MCH.SegmentChoiceCode
		----AND MCHOP.ChoiceOptionCode = MSCHOP.ChoiceOptionCode
		----LEFT JOIN #tempSelectedChoiceOption PSCHOP
		----ON PSCHOP.SectionId = @PSectionId
		----AND PSCHOP.SegmentChoiceCode = MCH.SegmentChoiceCode
		----AND PSCHOP.ChoiceOptionCode = MCHOP.ChoiceOptionCode
		----WHERE MST.SectionId = @PMasterSectionId
		----AND PSCHOP.SegmentChoiceCode IS NULL


	IF((dateadd(HOUR,-6,GETUTCDATE())>=@PSectionModifiedDate or @PSectionModifiedDate is null))
	BEGIN
		DROP TABLE IF EXISTS #tempSelectedChoiceOption1

		SELECT SegmentChoiceCode
		,ChoiceOptionCode
		,SectionId
		,ProjectId
		,ChoiceOptionSource
		INTO #tempSelectedChoiceOption1
		FROM SelectedChoiceOption PSCHOP WITH (NOLOCK)
		WHERE PSCHOP.ProjectId = @PProjectId AND PSCHOP.CustomerId = @PCustomerId AND PSCHOP.SectionId = @PSectionId;

		-- Insert missing entry
		INSERT INTO SelectedChoiceOption
		SELECT psc.SegmentChoiceCode
		,pco.ChoiceOptionCode
		,pco.ChoiceOptionSource
		,slcmsco.IsSelected
		,psc.SectionId
		,psc.ProjectId
		,pco.CustomerId
		,NULL AS OptionJson
		,0 AS IsDeleted
		FROM ProjectSegmentChoice psc WITH (NOLOCK)
		INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId
		AND pco.SectionId = psc.SectionId
		AND pco.ProjectId = psc.ProjectId
		AND pco.CustomerId = psc.CustomerId
		AND ISNULL(pco.IsDeleted, 0) = 0
		
		LEFT OUTER JOIN #tempSelectedChoiceOption1 sco WITH (NOLOCK)
		ON pco.SectionId = sco.SectionId
		AND pco.ProjectId = sco.ProjectId
		AND sco.SegmentChoiceCode=psc.SegmentChoiceCode
		AND pco.ChoiceOptionCode = sco.ChoiceOptionCode
		--AND pco.CustomerId = sco.CustomerId
		AND sco.ChoiceOptionSource = pco.ChoiceOptionSource
		INNER JOIN SLCMaster.dbo.SelectedChoiceOption slcmsco WITH (NOLOCK)
		ON slcmsco.SectionId=@PMasterSectionId
		and slcmsco.SegmentChoiceCode = psc.SegmentChoiceCode
		and slcmsco.ChoiceOptionCode = pco.ChoiceOptionCode
		WHERE psc.ProjectId = @PProjectId AND psc.CustomerId = @CustomerId AND psc.SectionId = @PSectionId
		AND pco.ProjectId = @PProjectId
		AND pco.CustomerId = @PCustomerId
		AND sco.SegmentChoiceCode IS NULL
		AND ISNULL(psc.IsDeleted, 0) = 0  
		
		IF(@@ROWCOUNT>0)
		BEGIN
			INSERT INTO BsdLogging..DBLogging (
			ArtifactName
			,DBServerName
			,DBServerIP
			,CreatedDate
			,LevelType
			,InputData
			,ErrorProcedure
			,ErrorMessage
			)
			VALUES (
			'usp_MapSegmentChoiceFromMasterToProject'
			,@@SERVERNAME
			,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))
			,Getdate()
			,'Information'
			,concat('ProjectId: ' , @ProjectId , ' SectionId: ' , @SectionId , ' CustomerId: ' , @CustomerId , ' UserId:' , @UserId)
			,'Insert'
			,('Scenario 1: SelectedChoiceOption Rows Inserted - ' + convert(NVARCHAR, @@ROWCOUNT))
			)
		END
		-- Mark isdeleted =0 for SelectedChoiceOption
		UPDATE sco
		SET sco.isdeleted = 0
		FROM ProjectSegmentChoice psc WITH (NOLOCK)
		INNER JOIN ProjectChoiceOption pco WITH (NOLOCK) ON pco.SegmentChoiceId = psc.SegmentChoiceId
		AND pco.SectionId = psc.SectionId
		AND pco.ProjectId = psc.ProjectId
		AND pco.CustomerId = psc.CustomerId
		AND ISNULL(pco.IsDeleted, 0) = 0

		LEFT OUTER JOIN SelectedChoiceOption sco WITH (NOLOCK)
		ON pco.ProjectId = sco.ProjectId AND pco.CustomerId = sco.CustomerId AND pco.SectionId = sco.SectionId
		AND sco.SegmentChoiceCode = psc.SegmentChoiceCode
		AND pco.ChoiceOptionCode = sco.ChoiceOptionCode
		AND ISNULL(sco.IsDeleted, 0) = 1
		--AND pco.CustomerId = sco.CustomerId
		AND sco.ChoiceOptionSource = pco.ChoiceOptionSource
		WHERE psc.ProjectId = @PProjectId AND psc.CustomerId = @CustomerId AND psc.SectionId = @PSectionId
		AND pco.ProjectId = @PProjectId AND pco.SectionId = @PSectionId AND pco.CustomerId = @PCustomerId  
		  AND ISNULL(psc.IsDeleted, 0) = 0  
		  AND psc.SegmentChoiceSource = 'U'  

		-- Mark isdeleted =0 for SelectedChoiceOption
		IF(@@ROWCOUNT>0)
		BEGIN
			INSERT INTO BsdLogging..DBLogging (
			ArtifactName
			,DBServerName
			,DBServerIP
			,CreatedDate
			,LevelType
			,InputData
			,ErrorProcedure
			,ErrorMessage
			)
			VALUES (
			'usp_MapSegmentChoiceFromMasterToProject'
			,@@SERVERNAME
			,convert(NVARCHAR, CONNECTIONPROPERTY('local_net_address'))
			,Getdate()
			,'Information'
			,concat('ProjectId: ' , @ProjectId , ' SectionId: ' , @SectionId , ' CustomerId: ' , @CustomerId , ' UserId:' , @UserId)
			,'Update'
			,('Scenario 2: SelectedChoiceOption Rows Updated - ' + convert(NVARCHAR, @@ROWCOUNT))
			)
		END
	END
END
GO


