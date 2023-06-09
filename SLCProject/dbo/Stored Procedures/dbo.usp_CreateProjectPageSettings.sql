CREATE PROCEDURE [dbo].[usp_CreateProjectPageSettings]  
   @ProjectId INT,    
   @CustomerId INT,  
   @PaperName varchar(500),  
   @IsMirrorMargin bit,  
   @EdgeFooter decimal(18, 2),  
   @EdgeHeader decimal(18, 2),  
   @MarginBottom decimal(18, 2),  
   @MarginLeft decimal(18, 2),  
   @MarginRight decimal(18, 2),  
   @MarginTop decimal(18, 2),  
   @PaperHeight decimal(18, 2),  
   @PaperWidth decimal(18, 2),
   @SectionId INT = NULL,
   @TypeId INT = 1
AS  
BEGIN
  
   DECLARE @PProjectId INT = @ProjectId;
   DECLARE @PCustomerId INT = @CustomerId;
   DECLARE @PPaperName varchar(500) = @PaperName;
   DECLARE @PIsMirrorMargin bit = @IsMirrorMargin;
   DECLARE @PEdgeFooter decimal(18, 2) = @EdgeFooter;
   DECLARE @PEdgeHeader decimal(18, 2) = @EdgeHeader;
   DECLARE @PMarginBottom decimal(18, 2) = @MarginBottom;
   DECLARE @PMarginLeft decimal(18, 2) = @MarginLeft;
   DECLARE @PMarginRight decimal(18, 2) = @MarginRight;
   DECLARE @PMarginTop decimal(18, 2) = @MarginTop;
   DECLARE @PPaperHeight decimal(18, 2) = @PaperHeight;
   DECLARE @PPaperWidth decimal(18, 2) =  @PaperWidth;
   DECLARE @PSectionId INT = CASE WHEN @SectionId > 0 THEN @SectionId ELSE 0 END;  
   DECLARE @PTypeId INT = @TypeId;

--Update Page Setting
IF (EXISTS (SELECT TOP 1 1
	FROM ProjectPageSetting WITH (NOLOCK)
	WHERE ProjectId = @PProjectId
	AND CustomerId = @PCustomerId AND ISNULL(SectionId,0) = @PSectionId))
BEGIN
UPDATE PPS
SET PPS.MarginTop = @PMarginTop
   ,PPS.MarginBottom = @PMarginBottom
   ,PPS.MarginLeft = @PMarginLeft
   ,PPS.MarginRight = @PMarginRight
   ,PPS.EdgeHeader = @PEdgeHeader
   ,PPS.EdgeFooter = @PEdgeFooter
   ,PPS.IsMirrorMargin = @PIsMirrorMargin
   FROM ProjectPageSetting PPS WITH (NOLOCK)
WHERE PPS.ProjectId = @PProjectId
AND PPS.CustomerId = @PCustomerId
AND ISNULL(PPS.SectionId,0) = @PSectionId

UPDATE PPS
SET PPS.PaperName = @PPaperName
   ,PPS.PaperWidth = @PPaperWidth
   ,PPS.PaperHeight = @PPaperHeight
FROM ProjectPaperSetting PPS WITH (NOLOCK)
WHERE PPS.ProjectId = @PProjectId
AND PPS.CustomerId = @PCustomerId
AND ISNULL(PPS.SectionId,0) = @PSectionId
END
--Insert if not exist
ELSE
BEGIN
   SET @PSectionId = CASE WHEN @SectionId = 0 THEN NULL ELSE @SectionId END;  
INSERT INTO ProjectPageSetting (MarginTop, MarginBottom, MarginLeft, MarginRight, EdgeHeader, EdgeFooter, IsMirrorMargin, ProjectId, CustomerId, SectionId, TypeId)
	VALUES (@PMarginTop, @PMarginBottom, @PMarginLeft, @PMarginRight, @PEdgeHeader, @PEdgeFooter, @PIsMirrorMargin, @ProjectId, @PCustomerId, @PSectionId, @PTypeId);

INSERT INTO ProjectPaperSetting (PaperName, PaperWidth, PaperHeight, ProjectId, CustomerId, SectionId)
	VALUES (@PPaperName, @PPaperWidth, @PPaperHeight, @PProjectId, @PCustomerId, @PSectionId);
END
END
GO