CREATE PROCEDURE usp_UpdateUserSubDivision                                    
(                          
@ProjectId INT,                          
@CustomerId INT,                   
@SectionId INT,                         
@UserId INT,              
@Description NVARCHAR(1000),                                                    
@SourceTag NVARCHAR(18) = NULL ,      
@IsAddOnTop INT        
)                          
AS                          
BEGIN      
                                                                                      
DECLARE @SortOrder INT;      
                                      
DECLARE @PSectionId INT = @SectionId;      
DECLARE @PParentSectionId INT;      
DECLARE @PProjectId INT=@ProjectId;      
DECLARE @PCustomerId INT=@CustomerId;      
DECLARE @PUserId INT=@UserId;      
DECLARE @PResponceId INT=0;      
DECLARE @PDescription NVARCHAR(1000)=@Description;      
DECLARE @PSourceTag NVARCHAR(10)=@SourceTag;      
DECLARE @PIsAddOnTop INT = @IsAddOnTop;      
DECLARE @AddSubDivisionSettingValue nvarchar(10);      
      
SELECT      
 @PParentSectionId = ParentSectionId      
FROM ProjectSection ps WITH (NOLOCK)      
WHERE SectionId = @PSectionId      
AND ProjectId = @PProjectId      
AND CustomerId = @PCustomerId;      
      
IF (@PSourceTag IS NOT NULL      
 AND @PSourceTag <> ''      
 AND EXISTS (SELECT TOP 1      
   1      
  FROM ProjectSection WITH (NOLOCK)      
  WHERE ParentSectionId = @PParentSectionId    
  AND  SectionId != @PSectionId      
  AND ParentSectionId = @PParentSectionId      
  AND ProjectId = @PProjectId      
  AND CustomerId = @PCustomerId      
  AND UPPER(SourceTag) = UPPER(@PSourceTag)      
  AND ISNULL(IsDeleted, 0) = 0)      
 )      
BEGIN      
SET @PResponceId = -1;      
 --SET @ResponseMsg = 'Division number already exists.';                                      
END;      
      
IF EXISTS (SELECT TOP 1      
   1      
  FROM ProjectSection WITH (NOLOCK)      
  WHERE ParentSectionId = @PParentSectionId      
  AND SectionId != @PSectionId      
  AND ProjectId = @PProjectId      
  AND CustomerId = @PCustomerId      
  AND UPPER([Description]) = UPPER(@PDescription)      
  AND ISNULL(IsDeleted, 0) = 0)      
BEGIN      
IF (@PResponceId <> 0)      
SET @PResponceId = -3;      
END      
      
IF (@PResponceId = 0)      
BEGIN      
DROP TABLE IF EXISTS #subDivisions;      
CREATE TABLE #subDivisions (      
 [Description] NVARCHAR(MAX)      
   ,[T_Description] NVARCHAR(MAX)      
   ,[SourceTag] VARCHAR(18) NULL      
   ,[T_SourceTag] VARCHAR(400) NULL      
   ,[SortOrder] INT      
);      
      
IF (@PIsAddOnTop = 1)      
BEGIN      
 SET  
 @SortOrder = (SELECT  
  ISNULL(MIN(SortOrder) - 1, 1)  
 FROM ProjectSection WITH (NOLOCK)  
 WHERE ParentSectionId = @PParentSectionId  
 AND ProjectId = @PProjectId  
 AND CustomerId = @PCustomerId  
 AND ISNULL(IsDeleted, 0) = 0);  
  
 SET @AddSubDivisionSettingValue = 'Top';      
END      
ELSE IF (@PIsAddOnTop = 0)      
BEGIN      
 SET @SortOrder = (SELECT  
  ISNULL(MAX(SortOrder) + 1, 1)  
 FROM ProjectSection WITH (NOLOCK)  
 WHERE ParentSectionId = @PParentSectionId 
 AND ProjectId = @PProjectId  
 AND CustomerId = @PCustomerId  
 AND ISNULL(IsDeleted, 0) = 0);  
  
 SET @AddSubDivisionSettingValue = 'Bottom';      
END      
ELSE IF (@PIsAddOnTop = -1)      
BEGIN      
 IF(@PSourceTag IS NULL OR @PSourceTag = '')      
  INSERT INTO #subDivisions ([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder)
  VALUES (@PDescription, '', @PDescription, '', -1);      
 ELSE      
  INSERT INTO #subDivisions ([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder)
  VALUES (@PDescription, '', @PSourceTag, '', -1);      
      
 INSERT INTO #subDivisions ([Description], [T_Description], SourceTag, [T_SourceTag], SortOrder)      
 (SELECT  
  [Description]  
    ,''  
    ,SourceTag  
    ,''  
    ,SortOrder  
    FROM ProjectSection WITH (NOLOCK)  
    WHERE ParentSectionId = @PParentSectionId  
    AND ProjectId = @PProjectId  
    AND ISNULL(IsDeleted, 0) = 0  
    AND SectionId <> @PSectionId  
    AND (SourceTag IS NOT NULL  
    AND SourceTag <> ''));      
  
 UPDATE sd  
SET sd.T_SourceTag = dbo.udf_ExpandDigits(sd.SourceTag, 18, '0')  
FROM #subDivisions sd; 
      
 DROP TABLE IF EXISTS #sortedSubDivisions;      
 SELECT  
 ROW_NUMBER() OVER (ORDER BY T_SourceTag) AS RowId  
   ,[Description]  
   ,SourceTag  
   ,SortOrder INTO #sortedSubDivisions  
    FROM #subDivisions  
    ORDER BY SourceTag;
    
 DECLARE @MaxRowId INT = (SELECT  
  MAX(RowId)  
 FROM #sortedSubDivisions);  
DECLARE @NewSubDivRowId INT = (SELECT TOP 1  
  RowId  
 FROM #sortedSubDivisions  
 WHERE [Description] = @PDescription
  AND SourceTag = @PSourceTag);  

 IF (@MaxRowId = 1)      
  SET @SortOrder = 1;      
 ELSE  
IF (@MaxRowId = @NewSubDivRowId)  
SET @SortOrder = (SELECT  
  MAX(SortOrder) + 1  
 FROM #sortedSubDivisions); 
 ELSE  
    SET @SortOrder = (SELECT  
    SortOrder  
    FROM #sortedSubDivisions  
    WHERE RowId = (@NewSubDivRowId + 1)); -- Update the Sort order of other SubDiv      
END;      
      
IF (@AddSubDivisionSettingValue IS NOT NULL)      
BEGIN      
DECLARE @Id INT = (SELECT TOP 1      
  Id      
 FROM ProjectSetting WITH (NOLOCK)      
 WHERE ProjectId = @PProjectId      
 AND CustomerId = @PCustomerId      
 AND [Name] = 'AddSubDivision');      
IF (@Id IS NULL)      
INSERT INTO ProjectSetting (ProjectId, CustomerId, [Name], [Value], CreatedDate, CreatedBy)      
 VALUES (@PProjectId, @PCustomerId, 'AddSubDivision', @AddSubDivisionSettingValue, GETUTCDATE(), @PUserId);      
ELSE      
UPDATE PS      
SET [Value] = @AddSubDivisionSettingValue      
   ,[ModifiedDate] = GETUTCDATE()      
   ,[ModifiedBy] = @PUserId      
FROM ProjectSetting PS WITH (NOLOCK)      
WHERE ProjectId = @PProjectId      
AND CustomerId = @PCustomerId      
AND [Name] = 'AddSubDivision';      
END      
      
      
UPDATE PS      
SET SortOrder = SortOrder + 1      
FROM ProjectSection PS WITH (NOLOCK)      
WHERE ParentSectionId = @PParentSectionId      
AND ProjectId = @PProjectId      
AND ISNULL(ISDeleted, 0) = 0      
AND SortOrder >= @SortOrder;      
      
UPDATE PS      
SET PS.Description = @PDescription      
   ,PS.SourceTag = @PSourceTag      
   ,PS.SortOrder = @SortOrder      
   ,ModifiedBy = @PUserId      
   ,ModifiedDate = GETUTCDATE()      
FROM ProjectSection PS WITH (NOLOCK)      
WHERE PS.SectionId = @PSectionId      
AND PS.ProjectId = @PProjectId      
AND PS.CustomerId = @PCustomerId;      
  
SET @PResponceId = @PSectionId;      
                                       
 END      
SELECT      
 @PResponceId AS SectionId;      
END