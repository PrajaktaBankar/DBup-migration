
CREATE PROCEDURE [dbo].[usp_GetSegmentsForSection]  
@ProjectId INT,      
@SectionId INT,       
@CustomerId INT,       
@UserId INT,       
@CatalogueType NVARCHAR (50) NULL='FS'      
AS                                      
BEGIN    
            
 SET NOCOUNT ON;        
            
 DECLARE @PProjectId INT = @ProjectId;                             
         
 DECLARE @PSectionId INT = @SectionId;                              
 DECLARE @PCustomerId INT = @CustomerId;                              
 DECLARE @PUserId INT = @UserId;                              
 DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;                              
            
 --Set mSectionId                                
 DECLARE @MasterSectionId AS INT, @SectionTemplateId AS INT, @SectionTitle NVARCHAR(500) = ''; 
 --SET @MasterSectionId = (SELECT TOP 1 mSectionId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);            
                                
 DECLARE @MasterDataTypeId INT;        
 DECLARE @ProjectTemplateId AS INT;                            
 --SET @MasterDataTypeId = (SELECT TOP 1 MasterDataTypeId FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);             
 SELECT TOP 1 @MasterDataTypeId = MasterDataTypeId, @ProjectTemplateId = ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId        
            
 --FIND TEMPLATE ID FROM                                 
 --DECLARE @ProjectTemplateId AS INT = (SELECT TOP 1 ISNULL(TemplateId, 1) FROM Project WITH (NOLOCK) WHERE ProjectId = @PProjectId);                              
 --DECLARE @SectionTemplateId AS INT = ( SELECT TOP 1 TemplateId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId);            
   
 SELECT TOP 1  @MasterSectionId = mSectionId, @SectionTemplateId = TemplateId, @SectionTitle = [Description]  
 FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PSectionId;       
   
 DECLARE @DocumentTemplateId INT = 0;            
 DECLARE @IsMasterSection INT = CASE WHEN @MasterSectionId IS NULL THEN 0 ELSE 1 END;    
  
                              
 IF (@SectionTemplateId IS NOT NULL AND @SectionTemplateId > 0)                              
  BEGIN                              
   SET @DocumentTemplateId = @SectionTemplateId;            
  END                                
 ELSE                                
  BEGIN                              
   SET @DocumentTemplateId = @ProjectTemplateId;                              
  END                          
                              
 --CatalogueTypeTbl table                              
 DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(10));            
                              
 IF @PCatalogueType IS NOT NULL AND @PCatalogueType != 'FS'                              
 BEGIN                              
  INSERT INTO @CatalogueTypeTbl (TagType)             
  SELECT splitdata AS TagType FROM fn_SplitString(@PCatalogueType, ',');            
                              
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'OL')                              
  BEGIN                              
   INSERT INTO @CatalogueTypeTbl VALUES ('UO')                              
  END                              
  IF EXISTS (SELECT TOP 1 1 FROM @CatalogueTypeTbl WHERE TagType = 'SF')                              
  BEGIN                              
   INSERT INTO @CatalogueTypeTbl VALUES ('US')                              
  END                              
 END
       
--IF @IsMasterSection = 1  
-- BEGIN -- Data Mapping SP's                  
--   EXECUTE usp_MapSegmentStatusFromMasterToProject @ProjectId = @PProjectId                              
--  ,@SectionId = @PSectionId                              
--  ,@CustomerId = @PCustomerId                              
--  ,@UserId = @PUserId  
--  ,@MasterSectionId =@MasterSectionId;                              
--   EXECUTE usp_MapSegmentChoiceFromMasterToProject @ProjectId = @PProjectId                    
--  ,@SectionId = @PSectionId                              
--  ,@CustomerId = @PCustomerId                              
--  ,@UserId = @PUserId  
--  ,@MasterSectionId =@MasterSectionId;                              
--   EXECUTE usp_MapProjectRefStands @ProjectId = @PProjectId                   
--    ,@SectionId = @PSectionId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@UserId = @PUserId  
--    ,@MasterSectionId=@MasterSectionId;                              
--   EXECUTE usp_MapSegmentRequirementTagFromMasterToProject @ProjectId = @PProjectId                              
--    ,@SectionId = @PSectionId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@UserId = @PUserId  
--     ,@MasterSectionId=@MasterSectionId;            
--   EXECUTE usp_MapSegmentLinkFromMasterToProject @ProjectId = @PProjectId                            
--   ,@SectionId = @PSectionId                              
--   ,@CustomerId = @PCustomerId                              
--   ,@UserId = @PUserId;                              
--   EXECUTE usp_UpdateSegmentStatus_ApplyMasterUpdate @ProjectId = @PProjectId                              
--    ,@CustomerId = @PCustomerId                              
--    ,@SectionId = @PSectionId       
--    -- NOT IN USE hence commented                         
--   --EXECUTE usp_DeleteSegmentRequirementTag_ApplyMasterUpdate @ProjectId = @PProjectId                              
--   --,@CustomerId = @PCustomerId                              
--   --,@SectionId = @PSectionId                    
-- END        
        
 DROP TABLE IF EXISTS #ProjectSegmentStatus;                        
 SELECT                          
  PSS.ProjectId                          
    ,PSS.CustomerId                          
    ,PSS.SectionId                     
    ,PSS.SegmentStatusId                               
    ,PSS.ParentSegmentStatusId                          
    ,ISNULL(PSS.mSegmentStatusId, 0) AS mSegmentStatusId                          
    ,ISNULL(PSS.mSegmentId, 0) AS mSegmentId                          
    ,ISNULL(PSS.SegmentId, 0) AS SegmentId                          
    ,PSS.SegmentSource                          
    ,TRIM(PSS.SegmentOrigin) as SegmentOrigin                  
    ,PSS.IndentLevel                          
    ,ISNULL(MSST.IndentLevel, 0) AS MasterIndentLevel                          
    ,PSS.SequenceNumber                          
    ,PSS.SegmentStatusTypeId                          
    ,PSS.SegmentStatusCode                          
    ,PSS.IsParentSegmentStatusActive                          
    ,PSS.IsShowAutoNumber                          
    ,PSS.FormattingJson                          
    ,STT.TagType                          
    ,CASE                          
   WHEN PSS.SpecTypeTagId IS NULL THEN 0                          
   ELSE PSS.SpecTypeTagId                          
  END AS SpecTypeTagId                          
    ,PSS.IsRefStdParagraph                          
    ,PSS.IsPageBreak                          
    ,PSS.IsDeleted                          
    ,MSST.SpecTypeTagId AS MasterSpecTypeTagId                          
    ,ISNULL(MSST.ParentSegmentStatusId, 0) AS MasterParentSegmentStatusId                          
    ,CASE                          
   WHEN MSST.SegmentStatusId IS NOT NULL AND                          
    MSST.SpecTypeTagId = PSS.SpecTypeTagId THEN CAST(1 AS BIT)                          
   ELSE CAST(0 AS BIT)                          
  END AS IsMasterSpecTypeTag                          
    ,PSS.TrackOriginOrder AS TrackOriginOrder                    
    ,PSS.MTrackDescription                    
    INTO #ProjectSegmentStatus                          
 FROM ProjectSegmentStatus AS PSS WITH (NOLOCK)                          
 LEFT JOIN SLCMaster..SegmentStatus MSST WITH (NOLOCK)                          
  ON PSS.mSegmentStatusId = MSST.SegmentStatusId                          
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK)                          
  ON PSS.SpecTypeTagId = STT.SpecTypeTagId                          
 WHERE PSS.SectionId = @PSectionId                          
 AND PSS.ProjectId = @PProjectId                          
 AND PSS.CustomerId = @PCustomerId                          
 AND ISNULL(PSS.IsDeleted, 0) = 0                          
 AND (@PCatalogueType = 'FS'                          
 OR STT.TagType IN (SELECT  TagType FROM @CatalogueTypeTbl))    
    
    
 BEGIN -- Fetching Master and Project Notes    
  SELECT Distinct MN.SegmentStatusId    
  INTO #MasterNotes    
  FROM SLCMaster..Note MN WITH (NOLOCK)    
  WHERE MN.SectionId = @MasterSectionId;    
    
  SELECT Distinct PN.SegmentStatusId    
  INTO #ProjectNotes    
  FROM ProjectNote PN WITH (NOLOCK)    
  WHERE PN.SectionId = @PSectionId AND PN.ProjectId = @PProjectId  AND ISNULL(PN.IsDeleted,0)=0 
  --AND PN.CustomerId=@CustomerId 
 END    
    
    
 SELECT        
  PSS.SegmentStatusId        
 ,PSS.ParentSegmentStatusId        
 ,PSS.mSegmentStatusId        
 ,PSS.mSegmentId        
 ,PSS.SegmentId        
 ,PSS.SegmentSource        
 ,PSS.SegmentOrigin        
 ,PSS.IndentLevel        
 ,PSS.MasterIndentLevel        
 ,PSS.SequenceNumber        
 ,PSS.SegmentStatusTypeId        
 ,PSS.SegmentStatusCode        
 ,PSS.IsParentSegmentStatusActive        
 ,PSS.IsShowAutoNumber        
 ,PSS.FormattingJson        
 ,PSS.TagType        
 ,PSS.SpecTypeTagId        
 ,PSS.IsRefStdParagraph    
 ,PSS.IsPageBreak        
 ,PSS.IsDeleted        
 ,PSS.MasterSpecTypeTagId        
 ,PSS.MasterParentSegmentStatusId        
 ,PSS.IsMasterSpecTypeTag        
 ,PSS.TrackOriginOrder        
 ,PSS.MTrackDescription    
 ,CASE WHEN (MN.SegmentStatusId IS NOT NULL AND @IsMasterSection = 1) THEN 1 ELSE 0 END AS HasMasterNote      
 ,CASE WHEN (PN.SegmentStatusId IS NOT NULL) THEN 1 ELSE 0 END AS HasProjectNote    
 FROM #ProjectSegmentStatus PSS WITH (NOLOCK)    
 LEFT JOIN #MasterNotes MN WITH (NOLOCK)      
  ON MN.SegmentStatusId = PSS.mSegmentStatusId      
 LEFT JOIN #ProjectNotes PN WITH (NOLOCK)    
  ON PN.SegmentStatusId = PSS.SegmentStatusId    
 ORDER BY SequenceNumber;        
    
                          
 SELECT                          
  *                          
 FROM (SELECT                          
   PSG.SegmentId                          
  ,PSST.SegmentStatusId                          
  ,PSG.SectionId                          
  ,ISNULL(PSG.SegmentDescription, '') AS SegmentDescription                          
  ,PSG.SegmentSource                          
  ,PSG.SegmentCode                          
  FROM #ProjectSegmentStatus AS PSST WITH (NOLOCK)                          
  INNER JOIN ProjectSegment AS PSG WITH (NOLOCK)                          
   ON PSST.SegmentId = PSG.SegmentId                          
   AND PSST.SectionId = PSG.SectionId                          
   AND PSST.ProjectId = PSG.ProjectId                          
   AND PSST.CustomerId = PSG.CustomerId                          
  WHERE PSG.ProjectId = @PProjectId AND PSG.SectionId = @PSectionId                          
  AND ISNULL(PSST.IsDeleted, 0) = 0                          
  UNION ALL                          
  SELECT                          
   MSG.SegmentId                          
  ,PST.SegmentStatusId                          
  ,PST.SectionId                          
  ,CASE WHEN PST.ParentSegmentStatusId = 0 AND PST.SequenceNumber = 0 THEN @SectionTitle ELSE ISNULL(MSG.SegmentDescription, '') END AS SegmentDescription                          
  ,MSG.SegmentSource  
  ,MSG.SegmentCode                          
  FROM #ProjectSegmentStatus AS PST WITH (NOLOCK)                          
  --INNER JOIN ProjectSection AS PS WITH (NOLOCK)                          
  -- ON PST.SectionId = PS.SectionId                          
  INNER JOIN SLCMaster.dbo.Segment AS MSG WITH (NOLOCK)                          
   ON PST.mSegmentId = MSG.SegmentId                             
  ) AS X        
          
		  --NOTE- @Sanjay - Create new SP usp_GetSectionChoices hence commented                    
 ----NOTE -- Need to fetch distinct SelectedChoiceOption records     
 --DROP TABLE IF EXISTS #SelectedChoiceOptionTempMaster    SELECT DISTINCT   
 -- SCHOP.SegmentChoiceCode   
 --   ,SCHOP.ChoiceOptionCode   
 --   ,SCHOP.ChoiceOptionSource   
 --   ,SCHOP.IsSelected   
 --   ,SCHOP.ProjectId   
 --   ,SCHOP.SectionId   
 --   ,SCHOP.CustomerId   
 --   ,0 AS SelectedChoiceOptionId   
 --   ,SCHOP.OptionJson  
 --INTO #SelectedChoiceOptionTempMaster   
 --FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
 --WHERE SCHOP.SectionId = @PSectionId      
 --AND SCHOP.ProjectId = @PProjectId  
 --AND SCHOP.CustomerId = @PCustomerId   
 --AND ISNULL(SCHOP.IsDeleted, 0) = 0  
 --AND SCHOP.ChoiceOptionSource = 'M'    
  
 ----NOTE -- Need to fetch distinct SelectedChoiceOption records     
 --DROP TABLE IF EXISTS #SelectedChoiceOptionTempProject  
 --SELECT DISTINCT   
 -- SCHOP.SegmentChoiceCode   
 --   ,SCHOP.ChoiceOptionCode   
 --   ,SCHOP.ChoiceOptionSource   
 --   ,SCHOP.IsSelected   
 --   ,SCHOP.ProjectId   
 --   ,SCHOP.SectionId   
 --   ,SCHOP.CustomerId   
 --   ,0 AS SelectedChoiceOptionId   
 --   ,SCHOP.OptionJson  
 --INTO #SelectedChoiceOptionTempProject   
 --FROM SelectedChoiceOption SCHOP WITH (NOLOCK)   
 --WHERE SCHOP.SectionId = @PSectionId      
 --AND SCHOP.ProjectId = @PProjectId  
 --AND SCHOP.CustomerId = @PCustomerId   
 --AND ISNULL(SCHOP.IsDeleted, 0) = 0  
 --AND SCHOP.ChoiceOptionSource = 'U'    
  
   
 ----FETCH MASTER + USER CHOICES AND THEIR OPTIONS  
 --SELECT    
 -- 0 AS SegmentId    
 --   ,MCH.SegmentId AS mSegmentId    
 --   ,MCH.ChoiceTypeId    
 --   ,'M' AS ChoiceSource    
 --   ,ISNULL(MCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
 --   ,ISNULL(MCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
 --   ,PSCHOP.IsSelected    
 --   ,PSCHOP.ChoiceOptionSource    
 --   ,CASE    
 --  WHEN PSCHOP.IsSelected = 1 AND    
 --   PSCHOP.OptionJson IS NOT NULL THEN PSCHOP.OptionJson    
 --  ELSE MCHOP.OptionJson    
 -- END AS OptionJson    
 --   ,MCHOP.SortOrder    
 --   ,MCH.SegmentChoiceId    
 --   ,MCHOP.ChoiceOptionId    
 --   ,PSCHOP.SelectedChoiceOptionId    
 --FROM #ProjectSegmentStatus PSST WITH (NOLOCK)    
 --INNER JOIN SLCMaster..SegmentChoice MCH WITH (NOLOCK)    
 -- ON PSST.mSegmentId = MCH.SegmentId AND MCH.SectionId=@MasterSectionId  
 --INNER JOIN SLCMaster..ChoiceOption MCHOP WITH (NOLOCK)    
 -- ON MCH.SegmentChoiceId = MCHOP.SegmentChoiceId    
 --INNER JOIN #SelectedChoiceOptionTempMaster PSCHOP WITH (NOLOCK)    
 --  --AND PSCHOP.ChoiceOptionSource = 'M'    
 --  ON PSCHOP.SectionId = @PSectionId    
 --  AND PSCHOP.ProjectId = @PProjectId    
 --  AND MCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode    
 --  AND MCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
 --WHERE  
 --PSST.SectionId = @PSectionId   AND   
 --MCH.SectionId = @MasterSectionId     
 --AND PSST.ProjectId = @PProjectId    
 --AND PSST.CustomerId = @PCustomerId    
 --AND ISNULL(PSST.IsDeleted, 0) = 0    
 --UNION ALL    
 --SELECT    
 -- PCH.SegmentId    
 --   ,0 AS mSegmentId    
 --   ,PCH.ChoiceTypeId    
 --   ,PCH.SegmentChoiceSource AS ChoiceSource    
 --   ,ISNULL(PCH.SegmentChoiceCode, 0) AS SegmentChoiceCode    
 --   ,ISNULL(PCHOP.ChoiceOptionCode, 0) AS ChoiceOptionCode    
 --   ,PSCHOP.IsSelected    
 --   ,PSCHOP.ChoiceOptionSource    
 --   ,PCHOP.OptionJson    
 --   ,PCHOP.SortOrder    
 --   ,PCH.SegmentChoiceId    
 --   ,PCHOP.ChoiceOptionId    
 --   ,PSCHOP.SelectedChoiceOptionId    
 --FROM #ProjectSegmentStatus PSST WITH (NOLOCK)    
 --INNER JOIN ProjectSegmentChoice PCH WITH (NOLOCK)    
 -- ON PSST.SegmentId = PCH.SegmentId AND PCH.SectionId = PSST.SectionId  
 --  AND ISNULL(PCH.IsDeleted, 0) = 0    
 --INNER JOIN ProjectChoiceOption PCHOP WITH (NOLOCK)    
 -- ON PCH.SegmentChoiceId = PCHOP.SegmentChoiceId AND PCHOP.SectionId = PCH.SectionId  
 --  AND ISNULL(PCHOP.IsDeleted, 0) = 0    
 --INNER JOIN #SelectedChoiceOptionTempProject PSCHOP WITH (NOLOCK)    
 -- ON PCHOP.SectionId = PSCHOP.SectionId    
 -- AND PCHOP.ChoiceOptionCode = PSCHOP.ChoiceOptionCode    
 --  AND PCH.SegmentChoiceCode = PSCHOP.SegmentChoiceCode    
 --  --AND PCH.SegmentChoiceSource = PSCHOP.ChoiceOptionSource    
 --  AND PSCHOP.SectionId = @PSectionId    
 --  AND PSCHOP.ProjectId = @PProjectId    
 --  --AND PSCHOP.ChoiceOptionSource = 'U'    
 --WHERE PCH.SectionId = @PSectionId  
 --AND PSST.ProjectId = @PProjectId    
 --AND PSST.SectionId = @PSectionId    
 --AND PSST.CustomerId = @PCustomerId    
 --AND ISNULL(PSST.IsDeleted, 0) = 0                             
                             
 --FETCH SEGMENT REQUIREMENT TAGS LIST                                
 SELECT                              
  PSRT.SegmentStatusId                              
    ,PSRT.SegmentRequirementTagId                              
    ,Temp.mSegmentStatusId                              
    ,LPRT.RequirementTagId                              
    ,LPRT.TagType                             
    ,LPRT.Description AS TagName                              
    ,CASE                              
   WHEN PSRT.mSegmentRequirementTagId IS NULL THEN CAST(0 AS BIT)                              
   ELSE CAST(1 AS BIT)                              
  END AS IsMasterRequirementTag                              
 FROM ProjectSegmentRequirementTag PSRT WITH (NOLOCK)                              
 INNER JOIN LuProjectRequirementTag LPRT WITH (NOLOCK)                              
  ON PSRT.RequirementTagId = LPRT.RequirementTagId                              
 INNER JOIN #ProjectSegmentStatus Temp WITH (NOLOCK)                              
  ON PSRT.SegmentStatusId = Temp.SegmentStatusId                              
 WHERE PSRT.ProjectId = @PProjectId AND PSRT.SectionId = @PSectionId
  --AND PSRT.CustomerId = @PCustomerId        
 AND ISNULL(PSRT.IsDeleted,0)=0    
END
GO


