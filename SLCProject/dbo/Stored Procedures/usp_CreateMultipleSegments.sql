CREATE PROCEDURE [dbo].[usp_CreateMultipleSegments]  
(  
@UserId int,
 @NewSegmentsJson NVARCHAR(MAX)  
)  
AS  
BEGIN  
   
 -- TODO -- Need to pass from api  
 DECLARE @CreatedBy INT = @UserId;  
   
 SELECT *   
 INTO #NewSegmentTable  
 FROM OPENJSON(@NewSegmentsJson) WITH (  
  RowId int '$.RowId',  
  SectionId int '$.SectionId',  
  ParentSegmentStatusId BIGINT '$.ParentSegmentStatusId',  
  IndentLevel int '$.IndentLevel',  
  SpecTypeTagId int '$.SpecTypeTagId',  
  SegmentStatusTypeId int '$.SegmentStatusTypeId',  
  IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive',  
  ProjectId int '$.ProjectId',  
  CustomerId int '$.CustomerId',  
  CreatedBy int '$.CreatedBy',  
  SegmentDescription NVARCHAR(MAX) '$.SegmentDescription',  
  SequenceNumber DECIMAL(18,4) '$.SequenceNumber',  
  IsRefStdParagraph BIT '$.IsRefStdParagraph',  
    
  OriginalSegmentStatusId BIGINT '$.OriginalSegmentStatusId',  
  OriginalParentSegmentStatusId BIGINT '$.OriginalParentSegmentStatusId',  
  SegmentId BIGINT '$.SegmentId',  
  SegmentStatusCode BIGINT '$.SegmentStatusCode',  
  SegmentCode BIGINT '$.SegmentCode',  
    
  SrcSectionId int '$.SrcSectionId',  
  SrcProjectId int '$.SrcProjectId',  
  SrcSectionCode int '$.SrcSectionCode',  
  SrcSegmentStatusCode BIGINT '$.SrcSegmentStatusCode',  
  SrcSegmentCode BIGINT '$.SrcSegmentCode'  
  );  
  
 --SELECT * FROM #NewSegmentTable;  
  
 DECLARE @RowNumber INT = 1;  
 DECLARE @TotalRows INT = 0;  
 SELECT @TotalRows = COUNT(1) FROM #NewSegmentTable;  
  
 WHILE @RowNumber <= @TotalRows  
 BEGIN  
  
  INSERT INTO ProjectSegmentStatus (SectionId, ParentSegmentStatusId, mSegmentStatusId, mSegmentId, SegmentId, SegmentSource, SegmentOrigin, IndentLevel, SequenceNumber, SpecTypeTagId, SegmentStatusTypeId, IsParentSegmentStatusActive, ProjectId, 
  CustomerId, IsShowAutoNumber, FormattingJson, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, IsRefStdParagraph)  
  SELECT   
   NST.SectionId  
  ,NST.ParentSegmentStatusId  
  ,0 AS mSegmentStatusId  
     ,0 AS mSegmentId  
     ,0 AS SegmentId  
     ,'U' AS SegmentSource  
     ,'U' AS SegmentOrigin  
     ,NST.IndentLevel  
  ,NST.SequenceNumber,  
  (CASE  
   WHEN NST.SpecTypeTagId = 0 THEN NULL  
   ELSE NST.SpecTypeTagId  
  END) AS SpecTypeTagId,   
  NST.SegmentStatusTypeId,   
  NST.IsParentSegmentStatusActive,   
  NST.ProjectId,   
  NST.CustomerId  
  ,1 AS IsShowAutoNumber  
    ,NULL AS FormattingJson  
    ,GETUTCDATE() AS CreateDate  
    ,@CreatedBy AS CreatedBy  
    ,NULL AS ModifiedDate  
    ,NULL AS ModifiedBy  
    ,NST.IsRefStdParagraph     
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
  
  DECLARE @SegmentStatusId AS BIGINT = SCOPE_IDENTITY();  
  
  INSERT INTO ProjectSegment (SegmentStatusId, SectionId, ProjectId, CustomerId, SegmentDescription, SegmentSource, CreatedBy, CreateDate, ModifiedBy, ModifiedDate)  
  SELECT  
   @SegmentStatusId AS SegmentStatusId  
     ,NST.SectionId  
     ,NST.ProjectId  
     ,NST.CustomerId  
     ,NST.SegmentDescription  
     ,'U' AS SegmentSource  
     ,@CreatedBy AS CreatedBy  
     ,GETUTCDATE() AS CreateDate  
     ,NULL AS ModifiedBy  
     ,NULL AS ModifiedDate  
	 
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
  
  DECLARE @SegmentId AS BIGINT = SCOPE_IDENTITY();  
  
  UPDATE PSS  
  SET PSS.SegmentId = @SegmentId  
  FROM ProjectSegmentStatus PSS WITH (NOLOCK)  
  WHERE PSS.SegmentStatusId = @SegmentStatusId;  
  
  DECLARE @SegmentStatusCode BIGINT, @SegmentCode BIGINT;  
  SELECT @SegmentStatusCode = PSS.SegmentStatusCode FROM ProjectSegmentStatus PSS WITH (NOLOCK) WHERE PSS.SegmentStatusId = @SegmentStatusId;  
  SELECT @SegmentCode = PS.SegmentCode FROM ProjectSegment PS WITH (NOLOCK) WHERE PS.SegmentId = @SegmentId  
  
  UPDATE NST  
  SET NST.OriginalSegmentStatusId = @SegmentStatusId  
     ,NST.OriginalParentSegmentStatusId = NST.ParentSegmentStatusId  
     ,NST.SegmentId = @SegmentId  
     ,NST.SegmentStatusCode = @SegmentStatusCode  
     ,NST.SegmentCode = @SegmentCode  
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
  
  DECLARE @IsRefStdParagraph BIT = 0, @PProjectId INT, @PSectionId INT, @PCustomerId INT, @SegmentDescription NVARCHAR(MAX) = '';  
  SELECT @IsRefStdParagraph =  NST.IsRefStdParagraph,   
      @SegmentDescription =  NST.SegmentDescription,  
      @PProjectId =  NST.ProjectId,  
      @PSectionId =  NST.SectionId,  
      @PCustomerId =  NST.CustomerId  
  FROM #NewSegmentTable NST WITH(NOLOCK) WHERE NST.RowId = @RowNumber;  
    
  ----NOW CREATE SEGMENT REQUIREMENT TAG IF SEGMENT IS OF RS TYPE  
  IF ISNULL(@IsRefStdParagraph, 0) = 1  
   BEGIN  
    EXEC usp_CreateSegmentRequirementTag @PCustomerId  
             ,@PProjectId  
             ,@PSectionId  
             ,@SegmentStatusId  
             ,'RS'  
             ,@CreatedBy  
    EXEC usp_CreateSpecialLinkForRsReTaggedSegment @PCustomerId  
                 ,@PProjectId  
                 ,@PSectionId  
                 ,@SegmentStatusId  
                 ,@CreatedBy  
  --START- Added Block for Regression Bug 40872  
  DECLARE @RSCode INT = 0 , @RsSegmentDescription nvarchar(max)= @SegmentDescription,@PRefStandardId INT = 0 , @PRefStdCode INT = 0;      
      
      SELECT @RSCode = LEFT(Val, PATINDEX('%[^0-9]%', Val + 'a') - 1)       
      FROM (SELECT SUBSTRING(@RsSegmentDescription, PATINDEX('%[0-9]%', @RsSegmentDescription), LEN(@RsSegmentDescription)) Val) RSCode  
  
  SELECT TOP 1   
  @PRefStandardId = RefStdId,  
  @PRefStdCode = RefStdCode  
  FROM ReferenceStandard WITH (NOLOCK) WHERE RefStdCode=@RSCode AND CustomerId= @PCustomerId  
  
  INSERT INTO ProjectSegmentReferenceStandard (SectionId, SegmentId, RefStandardId, RefStandardSource, mRefStandardId, CreateDate, CreatedBy, ModifiedDate, ModifiedBy, CustomerId, ProjectId, mSegmentId, RefStdCode)  
   VALUES (@PSectionId, @SegmentId, @PRefStandardId, 'U', 0, GETUTCDATE(), @CreatedBy, GETUTCDATE(), NULL, @PCustomerId, @PProjectId, null, @PRefStdCode)  
  
  ----END Block  
  
  END  
  
  SET @RowNumber = @RowNumber + 1;  
  
 END  
  
 SELECT NST.RowId  
    ,NST.OriginalSegmentStatusId  
    ,NST.OriginalParentSegmentStatusId  
    ,NST.SegmentId  
    ,NST.SegmentStatusCode  
    ,NST.SegmentCode  
 FROM #NewSegmentTable NST WITH(NOLOCK);  
  
END
GO


