
CREATE PROCEDURE [dbo].[usp_GetSectionChoices]
(  
 @ProjectId INT   
 ,@SectionId INT   
 ,@CustomerId INT 
 ,@MasterSectionId INT
)  
AS  
BEGIN  
  
  SET NOCOUNT ON;
 DECLARE @IsMasterSection INT = CASE WHEN ISNULL(@MasterSectionId,0) =0 THEN 0 ELSE 1 END;  
 DECLARE @finalOutput TABLE
 (
   SegmentId BIGINT
   ,mSegmentId INT
   ,ChoiceTypeId INT
   ,ChoiceSource CHAR(1)
   ,SegmentChoiceCode     BIGINT
   ,ChoiceOptionCode   BIGINT 
   ,IsSelected    BIT
   ,ChoiceOptionSource   CHAR(1) 
   ,OptionJson NVARCHAR(MAX)   
   ,SortOrder    TINYINT
   ,SegmentChoiceId    BIGINT
   ,ChoiceOptionId   BIGINT 
   ,SelectedChoiceOptionId BIGINT
 )
  
 SELECT SegmentId, mSegmentId  
 INTO #ProjectSegmentStatus  
 FROM ProjectSegmentStatus PSS  
 WHERE PSS.ProjectId = @ProjectId AND PSS.SectionId = @SectionId
 AND PSS.CustomerId = @CustomerId
  AND ISNULL(PSS.IsDeleted,0)=0; 
  
 -- GET Project Choice only if ProjectSegmentChoice has entry  
 IF EXISTS(SELECT TOP 1 1 FROM ProjectSegmentChoice PSC WHERE PSC.ProjectId = @ProjectId AND PSC.CustomerId = @CustomerId AND PSC.SectionId = @SectionId)  
 BEGIN  
  --NOTE -- Need to fetch distinct SelectedChoiceOption records     
  DROP TABLE IF EXISTS #SelectedChoiceOptionTempProject  
  SELECT DISTINCT   
   SCHOP.SegmentChoiceCode   
   ,SCHOP.ChoiceOptionCode   
   ,SCHOP.ChoiceOptionSource   
   ,SCHOP.IsSelected   
   ,SCHOP.ProjectId   
   ,SCHOP.SectionId   
   ,SCHOP.CustomerId   
   ,0 AS SelectedChoiceOptionId   
   ,SCHOP.OptionJson  
  INTO #SelectedChoiceOptionTempProject   
  FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
  WHERE SCHOP.ProjectId = @ProjectId AND SCHOP.CustomerId = @CustomerId AND SCHOP.SectionId = @SectionId      
  AND ISNULL(SCHOP.IsDeleted, 0) = 0  
  AND SCHOP.ChoiceOptionSource = 'U';  
  
  DROP TABLE IF EXISTS #ProjectSegmentChoiceTemp;  
  SELECT  
   PSC.SegmentId  
  ,PSC.ChoiceTypeId  
  ,PSC.SegmentChoiceSource  
  ,PSC.SegmentChoiceCode  
  ,PSC.SegmentChoiceId  
  ,PSC.SectionId  
  INTO #ProjectSegmentChoiceTemp  
  FROM ProjectSegmentChoice PSC  
  WHERE PSC.ProjectId = @ProjectId AND PSC.CustomerId = @CustomerId AND PSC.SectionId = @SectionId AND ISNULL(PSC.IsDeleted, 0) = 0;  
  
  DROP TABLE IF EXISTS #ProjectChoiceOptionTemp;  
  SELECT  
   PCO.ChoiceOptionCode  
  ,PCO.OptionJson  
  ,PCO.SortOrder  
  ,PCO.ChoiceOptionId  
  ,PCO.SegmentChoiceId  
  ,PCO.SectionId  
  INTO #ProjectChoiceOptionTemp  
  FROM ProjectChoiceOption PCO  
  WHERE PCO.SectionId = @SectionId AND PCO.ProjectId = @ProjectId AND ISNULL(PCO.IsDeleted, 0) = 0;  
  
  INSERT INTO @finalOutput
  SELECT    
   PCH.SegmentId    
     ,0 AS mSegmentId    
     ,PCH.ChoiceTypeId    
     ,PCH.SegmentChoiceSource AS ChoiceSource    
     ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
     ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
     ,PSCHOP.IsSelected    
     ,PSCHOP.ChoiceOptionSource    
     ,PCHOP.OptionJson    
     ,PCHOP.SortOrder    
     ,PCH.SegmentChoiceId    
     ,PCHOP.ChoiceOptionId    
     ,PSCHOP.SelectedChoiceOptionId    
  FROM  #ProjectSegmentStatus PSST WITH (NOLOCK)  
  INNER JOIN #ProjectSegmentChoiceTemp PCH WITH (NOLOCK)  
  ON PSST.SegmentId = PCH.SegmentId  
  INNER JOIN #ProjectChoiceOptionTemp PCHOP WITH (NOLOCK)    
   ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId  
  INNER JOIN #SelectedChoiceOptionTempProject PSCHOP WITH (NOLOCK)    
   ON PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
    AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode;  
 END  
  
 -- GE  
 IF(@IsMasterSection = 1)  
 BEGIN  
  
  DROP TABLE IF EXISTS #SelectedChoiceOptionTempMaster   
  SELECT DISTINCT   
   SCHOP.SegmentChoiceCode   
  ,SCHOP.ChoiceOptionCode   
  ,SCHOP.ChoiceOptionSource   
  ,SCHOP.IsSelected   
  ,SCHOP.ProjectId   
  ,SCHOP.SectionId   
  ,SCHOP.CustomerId   
  ,0 AS SelectedChoiceOptionId   
  ,SCHOP.OptionJson  
  INTO #SelectedChoiceOptionTempMaster   
  FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
  WHERE SCHOP.ProjectId = @ProjectId AND SCHOP.CustomerId = @CustomerId AND SCHOP.SectionId = @SectionId      
  AND ISNULL(SCHOP.IsDeleted, 0) = 0  
  AND SCHOP.ChoiceOptionSource = 'M';  
  
  
  DROP TABLE IF EXISTS #MasterSegmentChoiceTemp;  
  SELECT  
   MSC.SegmentId  
  ,MSC.ChoiceTypeId  
  ,MSC.SegmentChoiceSource  
  ,MSC.SegmentChoiceCode  
  ,MSC.SegmentChoiceId  
  ,MSC.SectionId  
  INTO #MasterSegmentChoiceTemp  
  FROM SLCMaster..SegmentChoice MSC  
  WHERE MSC.SectionId = @MasterSectionId  
   
 INSERT INTO @finalOutput
  SELECT    
   0 AS SegmentId    
     ,MCH.SegmentId AS mSegmentId    
     ,MCH.ChoiceTypeId    
     ,'M' AS ChoiceSource    
     ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
     ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
     ,PSCHOP.IsSelected    
     ,PSCHOP.ChoiceOptionSource    
     ,CASE    
    WHEN PSCHOP.IsSelected = 1 AND    
     PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson    
    ELSE MCHOP.OptionJson    
   END AS OptionJson    
     ,MCHOP.SortOrder    
     ,MCH.SegmentChoiceId    
     ,MCHOP.ChoiceOptionId    
     ,PSCHOP.SelectedChoiceOptionId    
  FROM #ProjectSegmentStatus PSST WITH (NOLOCK)  
  INNER JOIN #MasterSegmentChoiceTemp MCH WITH (NOLOCK)  
  ON PSST.mSegmentId = MCH.SegmentId  
  INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)    
   ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId  
  INNER JOIN #SelectedChoiceOptionTempMaster PSCHOP WITH (NOLOCK)  
    ON MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode  
    AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode;     
    
 END  

 SELECT * FROM @finalOutput
END
GO


