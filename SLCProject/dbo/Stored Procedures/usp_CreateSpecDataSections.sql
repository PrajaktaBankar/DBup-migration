
CREATE Procedure [dbo].[usp_CreateSpecDataSections]    
(    
@ProjectId int,    
@CustomerId int,    
@UserId Int,    
@MasterSectionIdJson NVARCHAR(max)     
)    
as    
begin    
    
DECLARE  @ReturnInputDataTable TABLE(     
    SectionId INT  ,    
 mSectionId INT     
);    
    
DECLARE  @InputDataTable TABLE(    
RowId int,    
    SectionId INT      
);    
DECLARE @SectionId int=0;    
DECLARE @Canada_Section_CutOffDate DATETIME2(7) = '20190420';    
IF @MasterSectionIdJson != ''    
BEGIN    
INSERT INTO @InputDataTable    
 SELECT    
  ROW_NUMBER() OVER (ORDER BY SectionId ASC) AS RowId    
    ,SectionId    
 FROM OPENJSON(@MasterSectionIdJson)    
 WITH (    
 SectionId INT '$.SectionId'    
 );    
END    
    
DECLARE @RowCount INT = (SELECT    
  COUNT(SectionId)    
 FROM @InputDataTable)    
    
DECLARE @n INT = 1;    
WHILE (@RowCount >= @n)    
BEGIN    
    
SET @SectionId = (SELECT TOP 1    
  ps.SectionId    
 FROM @InputDataTable stb    
 INNER JOIN ProjectSection ps  with (nolock)  
  ON ps.mSectionId = stb.SectionId    
  AND ps.ProjectId = @ProjectId    
  AND ps.CustomerId = @CustomerId    
 WHERE RowId = @n)    
    
DECLARE @IsPresent INT = 0;    
SELECT    
 @IsPresent = COUNT(SegmentStatusId)    
FROM ProjectSegmentStatus  with (nolock)  
WHERE SectionId = @SectionId    
AND ProjectId = @ProjectId    
AND CustomerId = @CustomerId    
    
PRINT @IsPresent    
PRINT @n    
    
IF (@IsPresent > 0)    
BEGIN    
    
DECLARE @PMasterDataTypeId INT = (SELECT    
  MasterDataTypeId    
 FROM Project  with (nolock)  
 WHERE ProjectId = @ProjectId    
 AND CustomerId = @CustomerId);    
    
DECLARE @SpecViewModeId INT = (SELECT    
  SpecViewModeId    
 FROM ProjectSummary WITH (NOLOCK)    
 WHERE ProjectId = @ProjectId    
 AND CustomerId = @CustomerId);    
SET @SpecViewModeId =    
CASE    
 WHEN @SpecViewModeId IS NULL THEN 1    
 ELSE @SpecViewModeId    
END;    
    
DROP TABLE IF EXISTS #ProjectSection    
    
SELECT    
 S.SectionId AS mSectionId    
   ,0 AS ParentSectionId    
   ,s.ParentSectionId AS mParentSectionId    
   ,@ProjectId AS [ProjectId]    
   ,@CustomerId AS [CustomerId]    
   ,@UserId AS [UserId]    
   ,DivisionId    
   ,[Description]    
   ,LevelId    
   ,IsLastLevel    
   ,SourceTag + '.1' AS SourceTag    
   ,Author    
   ,@UserId AS CreatedBy    
   ,GETUTCDATE() AS CreateDate    
   ,@UserId AS ModifiedBy    
   ,GETUTCDATE() AS ModifiedDate    
   ,[SectionCode]    
   ,[IsDeleted]    
   ,CASE    
  WHEN ParentSectionId = 0 OR    
   ParentSectionId IS NULL THEN 0    
  ELSE NULL    
 END AS TemplateId    
   ,[FormatTypeId]    
   ,[S].[DivisionCode]    
   ,@SpecViewModeId AS SpecViewModeId INTO #ProjectSection    
FROM [SLCMaster].[dbo].[Section] S WITH (NOLOCK)    
INNER JOIN @InputDataTable stbl    
 ON S.SectionId = stbl.SectionId    
  AND stbl.RowId = @n    
WHERE S.MasterDataTypeId = @PMasterDataTypeId    
AND S.IsDeleted = 0    
AND (S.PublicationDate >=    
CASE    
 WHEN @PMasterDataTypeId = 4 THEN (    
  CASE    
   WHEN S.IsLastLevel = 1 THEN @Canada_Section_CutOffDate    
   ELSE S.PublicationDate    
  END    
  )    
 ELSE S.PublicationDate    
END)    
    
INSERT INTO [ProjectSection] ([mSectionId], [ParentSectionId], [ProjectId], [CustomerId], [UserId], [DivisionId], [Description],    
[LevelId], [IsLastLevel], [SourceTag], [Author], [CreatedBy], [CreateDate], [ModifiedBy], [ModifiedDate],SectionCode , [IsDeleted],    
[TemplateId],    
[FormatTypeId], [DivisionCode], [SpecViewModeId])    
 SELECT    
  ps.mSectionId    
    ,ps.ParentSectionId    
    ,@ProjectId AS [ProjectId]    
    ,@CustomerId AS [CustomerId]    
    ,@UserId AS [UserId]    
    ,ps.DivisionId    
    ,ps.[Description]    
    ,ps.LevelId    
    ,ps.IsLastLevel    
    ,ps.SourceTag    
    ,ps.Author    
    ,@UserId AS CreatedBy    
    ,GETUTCDATE() AS CreateDate    
    ,@UserId AS ModifiedBy    
    ,GETUTCDATE() AS ModifiedDate    
	,ps.[SectionCode] 
    ,ps.[IsDeleted]    
    ,CASE    
   WHEN ParentSectionId = 0 OR    
    ParentSectionId IS NULL THEN 0    
   ELSE NULL    
  END AS TemplateId    
    ,ps.[FormatTypeId]    
    ,ps.[DivisionCode]    
    ,@SpecViewModeId AS SpecViewModeId    
 FROM #ProjectSection AS ps;    
    
DROP TABLE IF EXISTS #PSections    
    
SET @SectionId = SCOPE_IDENTITY();    
    
SELECT    
 PPS.ParentSectionId    
   ,PPS.mSectionId INTO #PSections    
FROM [ProjectSection] AS PPS WITH (NOLOCK)    
INNER JOIN @InputDataTable stbl    
 ON PPS.mSectionId = stbl.SectionId    
WHERE PPS.[ProjectId] = @ProjectId    
AND PPS.[CustomerId] = @CustomerId    
AND stbl.RowId = @n    
GROUP BY PPS.ParentSectionId    
  ,PPS.mSectionId    
    
    
UPDATE CPS    
SET CPS.ParentSectionId = PPS.ParentSectionId    
FROM [ProjectSection] AS CPS WITH (NOLOCK)    
INNER JOIN #PSections AS PPS WITH (NOLOCK)    
 ON PPS.mSectionId = CPS.mSectionId    
WHERE CPS.[ProjectId] = @ProjectId    
AND CPS.[CustomerId] = @CustomerId    
AND CPS.SectionId = @SectionId    
AND PPS.ParentSectionId <> 0    
    
END    
    
IF (@IsPresent <= 0)    
BEGIN    
    
SET @SectionId = (SELECT TOP 1    
  ps.SectionId    
 FROM ProjectSection PS WITH (NOLOCK)    
 INNER JOIN @InputDataTable IDTBL    
  ON IDTBL.SectionId = PS.mSectionId    
  AND PS.ProjectId = @ProjectId    
  AND PS.CustomerId = @CustomerId    
 WHERE RowId = @n)    
    
END    
    
    
SET @n = @n + 1;    
declare @mSectionId int=0    
SELECT    
 @mSectionId = mSectionId    
FROM ProjectSection  with (nolock)  
WHERE SectionId = @SectionId    
INSERT INTO @ReturnInputDataTable (SectionId, mSectionId)    
 SELECT    
  @SectionId    
    ,@mSectionId    
    
END    
    
    
SELECT    
 *    
FROM @ReturnInputDataTable    
END  