

 --For Get Projects For Missing Global Term
SELECT DISTINCT P.ProjectId,P.CustomerId,P.UserId,P.[Name]
INTO #CopyGTProjects
FROM Project P
LEFT OUTER JOIN ProjectGlobalTerm PGT 
ON P.ProjectId = PGT.ProjectId
WHERE PGT.ProjectId IS NULL AND P.IsDeleted = 0
ORDER BY ProjectId ASC

--SELECT * FROM #CopyGTProjects


DECLARE @MasterDataTypeId int = 1
DECLARE @TotalRows INT = 0;
SELECT @TotalRows = COUNT(1) FROM #CopyGTProjects;

DECLARE @CounterValue INT = 0;

PRINT 'ROWS ' + CAST(@CounterValue AS NVARCHAR(100));

DECLARE @ProjectId INT = 0;
DECLARE @CustomerId INT = 0 ;
DECLARE @UserId INT = 0;
DECLARe @ProjectName NVARCHAR ='';
DECLARE @SourceProjectId INT = 0;
DECLARE @TargetProjectId INT = 0;
WHILE exists (select * from #CopyGTProjects)
BEGIN

    select @ProjectId = (select top 1 ProjectId
                       from #CopyGTProjects)
    select @CustomerId = (select top 1 CustomerId
                       from #CopyGTProjects)
    select @UserId = (select top 1 UserId
                       from #CopyGTProjects)
    select @ProjectName = (select top 1 [Name]
                       from #CopyGTProjects)

    -- Do something with your TableID
	PRINT 'INSERT GT FOR - ' + CAST(@ProjectId AS NVARCHAR(100));

	
		-- Map All Global Term
		INSERT INTO ProjectGlobalTerm (mGlobalTermId, ProjectId, CustomerId, [Name], [Value], GlobalTermSource, GlobalTermCode, CreatedDate, CreatedBy, ModifiedDate, ModifiedBy, UserGlobalTermId, IsDeleted)
		SELECT
			GlobalTermId
		   ,@ProjectID AS ProjectId
		   ,@CustomerID AS CustomerId
		   ,[Name]
		   --,Value
			,CASE
				WHEN GlobalTermId = 1 THEN CAST(@ProjectName AS NVARCHAR(MAX))
				WHEN GlobalTermId = 2 THEN CAST(@ProjectID AS NVARCHAR(MAX))
				 ELSE [Value]
			 END AS [Value]
		   ,'M'
		   ,GlobalTermCode
		   ,GETUTCDATE()
		  ,@UserID AS CreatedBy
		   ,GETUTCDATE()
		  ,@UserID AS ModifiedBy
		   ,NUll
		   ,0 AS IsDeleted
		FROM SLCMaster..GlobalTerm(Nolock)
		WHERE MasterDataTypeId = @MasterDataTypeId

    delete #CopyGTProjects where ProjectId = @ProjectId

END

--DROP TABLE #CopyGTProjects