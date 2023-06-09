CREATE PROCEDURE [dbo].[usp_GetUpdates]          
(          
 @projectId INT NULL,           
 @sectionId INT NULL,           
 @customerId INT NULL,           
 @userId INT NULL=0,          
 @CatalogueType NVARCHAR (50) NULL='FS'                 
)                           
AS                
BEGIN              
DECLARE @PprojectId INT = @projectId;              
DECLARE @PsectionId INT = @sectionId;              
DECLARE @PcustomerId INT = @customerId;              
DECLARE @PuserId INT = @userId;              
DECLARE @PCatalogueType NVARCHAR (50) = @CatalogueType;              
                                    
DECLARE @totalRecords INT              
                                   
--SET MASTER SECTION ID                                    
DECLARE @mSectionId AS INT = ( SELECT TOP 1 mSectionId FROM ProjectSection WITH (NOLOCK) WHERE SectionId = @PsectionId AND ProjectId = @PprojectId);            
              
--DECLARE VARIABLES                                    
DECLARE @CURRENT_VERSION_T AS BIT = 1;              
DECLARE @CURRENT_VERSION_F AS BIT = 0;              
              
DECLARE @MasterDataTypeId INT = 0;              
SELECT @MasterDataTypeId = P.MasterDataTypeId FROM Project P WITH (NOLOCK) WHERE P.ProjectId = @PprojectId AND P.CustomerId = @PcustomerId;            
              
--FETCH ALL SEGMENT STATUS WITH MASTER SOURCES                      
DROP TABLE IF EXISTS #pss              
SELECT              
    SegmentStatusId              
   ,SectionId              
   ,ParentSegmentStatusId              
   ,mSegmentStatusId              
   ,mSegmentId              
   ,SegmentId              
   ,SegmentSource              
   ,SegmentOrigin              
   ,IndentLevel              
   ,SequenceNumber              
   ,SpecTypeTagId              
   ,SegmentStatusTypeId              
   ,IsParentSegmentStatusActive              
   ,ProjectId              
   ,CustomerId              
   ,SegmentStatusCode              
   ,IsShowAutoNumber              
   ,IsRefStdParagraph              
   ,FormattingJson              
   ,CreateDate              
   ,CreatedBy              
   ,ModifiedDate              
   ,ModifiedBy              
   ,IsPageBreak              
   --,SLE_DocID              
   --,SLE_ParentID              
   --,SLE_SegmentID              
   --,SLE_ProjectSegID              
   --,SLE_StatusID              
   --,A_SegmentStatusId              
   ,IsDeleted              
   ,TrackOriginOrder              
   ,MTrackDescription             
INTO #pss              
FROM [ProjectSegmentStatus] WITH (NOLOCK)              
WHERE SectionId = @PsectionId              
AND ProjectId = @PprojectId              
AND CustomerId = @PcustomerId              
AND ISNULL(IsDeleted,0)=0              
AND SegmentSource = 'M'      
--Reference Standard Paragraph : Customer Support 48227: SLC Ref Standard Update Issue      
--AND IsRefStdParagraph = 0              
AND (@PCatalogueType = 'FS'              
OR SpecTypeTagId IN (1, 2))              
            
--FETCH TEMP SEGMENT DATA               
DROP TABLE IF EXISTS #temp_segments              
              
DROP TABLE IF EXISTS #temp              
SELECT              
    ms.SegmentId              
   ,ms.SegmentStatusId              
   ,ms.SectionId              
   ,ms.SegmentDescription              
   ,ms.SegmentSource              
   ,ms.[Version]              
   ,ms.SegmentCode              
   ,ms.UpdatedId              
   ,ms.CreateDate              
   ,ms.ModifiedDate              
   ,ms.PublicationDate              
   ,ms.MasterDataTypeId              
   ,pss.SectionId AS PSectionId              
   ,pss.SegmentId AS PSegmentId              
   ,pss.SegmentStatusId AS PSegmentStatusId              
   ,pss.SegmentOrigin              
   ,ISNULL(pss.IsDeleted, 0) AS ProjectSegmentIsDelete              
   ,CONVERT(BIT, 0) AS MasterSegmentIsDelete             
INTO #temp_segments              
FROM #pss AS pss              
INNER JOIN [SLCMaster].[dbo].[Segment] AS ms WITH (NOLOCK)      
 ON ms.SegmentId = pss.mSegmentId              
INNER JOIN [SLCMaster].[dbo].[SegmentStatus] AS mss WITH (NOLOCK)              
 ON ms.SegmentStatusId = mss.SegmentStatusId       
WHERE pss.SectionId = @PsectionId              
        
AND ((          
 ISNULL(pss.IsDeleted, 0) = 0          
  AND ISNULL(mss.IsDeleted, 0) = 0          
 AND ISNULL(ms.UpdatedId, 0) > 0          
 )          
 OR (          
 ISNULL(pss.IsDeleted, 0) = 0          
  AND ISNULL(mss.IsDeleted, 0) = 1          
 ))          
        
UNION              
SELECT              
 ms.SegmentId              
   ,ms.SegmentStatusId              
   ,ms.SectionId              
   ,ms.SegmentDescription              
   ,ms.SegmentSource              
   ,ms.Version              
   ,ms.SegmentCode              
   ,ms.UpdatedId              
   ,ms.CreateDate              
   ,ms.ModifiedDate              
   ,ms.PublicationDate              
   ,ms.MasterDataTypeId              
   ,pss.SectionId AS PSectionId              
   ,pss.SegmentId AS PSegmentId              
   ,pss.SegmentStatusId AS PSegmentStatusId              
   ,pss.SegmentOrigin              
   ,ISNULL(pss.IsDeleted, 0) AS ProjectSegmentIsDelete              
   ,ISNULL(SS.IsDeleted, 0) AS MasterSegmentIsDelete              
FROM ProjectSegmentStatus AS pss WITH (NOLOCK)              
INNER JOIN SLCMaster..SegmentStatus SS WITH (NOLOCK)              
 ON pss.mSegmentStatusId = SS.SegmentStatusId              
INNER JOIN [SLCMaster].[dbo].[Segment] AS ms WITH (NOLOCK)              
 ON ms.SegmentId = pss.mSegmentId              
WHERE pss.SectionId = @PsectionId  
AND pss.ProjectId= @PprojectId
AND pss.CustomerId = @PcustomerId
--Reference Standard Paragraph : Customer Support 48227: SLC Ref Standard Update Issue      
--AND SS.IsRefStdParagraph = 0              
AND ISNULL(SS.IsDeleted,0) = 1              
AND (ISNULL(pss.IsDeleted,0) = 0);             
         
--GET VERSIONS OF THEM ALSO                  
DROP TABLE IF EXISTS #temp;              
;              
WITH updates              
AS              
(SELECT              
  *              
    ,@CURRENT_VERSION_T AS isCurrentVersion              
 FROM #temp_segments              
 UNION ALL              
 SELECT              
  c.SegmentId              
    ,c.SegmentStatusId              
    ,c.SectionId              
    ,c.SegmentDescription              
    ,c.SegmentSource              
    ,c.Version              
    ,c.SegmentCode              
    ,c.UpdatedId              
    ,c.CreateDate              
    ,c.ModifiedDate              
    ,c.PublicationDate              
    ,c.MasterDataTypeId              
    ,updates.PSectionId              
    ,updates.PSegmentId              
    ,updates.PSegmentStatusId              
    ,updates.SegmentOrigin              
    ,@CURRENT_VERSION_F AS isCurrentVersion              
    ,updates.ProjectSegmentIsDelete              
  --,updates.ProjectSegmentIsDelete                  
    ,updates.MasterSegmentIsDelete              
 FROM [SLCMaster].[dbo].[Segment] AS c WITH (NOLOCK)              
 INNER JOIN updates              
  ON c.SegmentId = updates.UpdatedId              
  AND c.SectionId = updates.SectionId              
 WHERE c.SectionId = @mSectionId)              
              
--SELECT MANUFACTURER DATA SEGMENT VERSION DATA                                    
SELECT              
 u.SegmentId AS MSegmentId              
   ,u.SegmentStatusId AS MSegmentStatusId              
   ,u.SectionId AS MSectionId              
   ,u.SegmentDescription              
 --,dbo.fnGetSegmentDescriptionTextForChoice (u.SegmentId,'M') as SegmentDescription                                    
   ,u.SegmentSource              
   ,u.SegmentCode              
   ,u.PublicationDate              
   ,u.UpdatedId AS NextVersionSegmentId              
   ,u.UpdatedId              
   ,u.PSectionId              
   ,u.PSegmentId              
   ,u.isCurrentVersion              
   ,u.[Version]              
   ,@PprojectId AS ProjectId              
   ,u.PSegmentStatusId              
   ,u.SegmentOrigin              
   ,u.SegmentDescription AS displayText              
   ,u.ProjectSegmentIsDelete              
   ,u.MasterSegmentIsDelete              
 --   ,dbo.fnGetSegmentDescriptionTextForChoice (u.SegmentId,'M') AS displayText                                    
   ,IIF(lu.RequirementTagId IN (11), @CURRENT_VERSION_T, @CURRENT_VERSION_F) AS MANUFACTURER INTO #temp              
FROM updates AS u              
LEFT OUTER JOIN [SLCMaster].[dbo].[SegmentRequirementTag] AS lu WITH (NOLOCK)              
 ON lu.[SegmentStatusId] = u.SegmentStatusId              
  AND lu.[SectionId] = u.SectionId;           
            
BEGIN -- Start : Update GT and RS from master logic            
            
 SELECT gt.ProjectId, gt.GlobalTermSource, gt.GlobalTermCode, gt.[Value]            
 INTO #ProjectGlobalTermTemp            
 FROM [ProjectGlobalTerm] AS gt WITH (NOLOCK)            
 WHERE projectId = @projectId and gt.GlobalTermSource = 'M'            
            
 SELECT @totalRecords = COUNT(*)            
 FROM #temp AS t            
 INNER JOIN #ProjectGlobalTermTemp AS gt WITH (NOLOCK)            
 ON t.projectId = gt.ProjectId            
 WHERE gt.GlobalTermSource = 'M'            
 AND t.displayText LIKE CONCAT('%{GT#', gt.GlobalTermCode, '}%');          
            
 WHILE (@totalRecords > 0)            
 BEGIN            
  UPDATE t            
   SET t.displayText = REPLACE(t.displayText, CONCAT('{GT#', gt.GlobalTermCode, '}'), gt.value)            
   ,t.SegmentDescription = REPLACE(t.SegmentDescription, CONCAT('{GT#', gt.GlobalTermCode, '}'), gt.[Value])            
   FROM #temp AS t            
   INNER JOIN #ProjectGlobalTermTemp AS gt WITH (NOLOCK)            
   ON t.projectId = gt.ProjectId            
   WHERE t.displayText LIKE CONCAT('%{GT#', gt.GlobalTermCode, '}%');            
            
  IF EXISTS (SELECT TOP 1 1 FROM #temp AS t            
  INNER JOIN #ProjectGlobalTermTemp AS gt WITH (NOLOCK)            
  ON t.projectId = gt.ProjectId WHERE t.displayText LIKE CONCAT('%{GT#', gt.GlobalTermCode, '}%'))            
   BEGIN            
    SELECT @totalRecords = @totalRecords + 1            
   END            
  ELSE            
   BEGIN            
    SELECT @totalRecords = 0;            
   END            
 END            
            
 UPDATE t            
 SET t.displayText = REPLACE(t.displayText, CONCAT('{RS#', rs.RefStdCode, '}'), rs.RefStdName)            
    ,t.SegmentDescription = REPLACE(t.SegmentDescription, CONCAT('{RS#', rs.RefStdCode, '}'), rs.RefStdName)            
 FROM #temp AS t            
 INNER JOIN [SLCMaster].[dbo].[SegmentReferenceStandard] AS srs WITH (NOLOCK)            
 ON t.MSegmentId = srs.SegmentId            
 INNER JOIN [SLCMaster].[dbo].[ReferenceStandard] AS rs WITH (NOLOCK)            
 ON rs.[RefStdId] = srs.[RefStandardId]            
 WHERE t.displayText LIKE CONCAT('%{RS#', rs.RefStdCode, '}%');            
              
END -- End : Update GT and RS from master logic            
            
--SELECT SEGMENTS FINALLY                                    
SELECT Convert(BIGINT,SegmentCode) as SegmentCode,Convert(BIGINT,UpdatedId) as UpdatedId, * FROM #temp;              
              
--SELECT RS UPDATES                
DROP TABLE IF EXISTS #RSupdTemp              
SELECT DISTINCT              
 pss.SegmentStatusId              
   ,srs.SegmentRefStandardId              
   ,rs.RefStdId              
   ,rs.RefStdName              
   ,rs.ReplaceRefStdId              
   ,rs.RefStdCode              
   ,rse.RefStdEditionId              
   ,rse.RefEdition              
   ,rse.RefStdTitle              
   ,rse.LinkTarget INTO #RSupdTemp              
FROM #pss AS PSS              
INNER JOIN [SLCMaster].dbo.SegmentReferenceStandard AS SRS WITH (NOLOCK)              
 ON pss.mSegmentId = srs.SegmentId              
INNER JOIN [SLCMaster].dbo.ReferenceStandard AS RS WITH (NOLOCK)              
 ON RS.RefStdId = SRS.RefStandardId              
INNER JOIN [SLCMaster].[dbo].[ReferenceStandardEdition] AS RSE WITH (NOLOCK)              
 ON RSE.RefStdId = rs.RefStdId              
WHERE RS.IsObsolete = 1;              
              
DROP TABLE IF EXISTS #SegRefStd              
;              
WITH RSupdates              
AS              
(SELECT              
  *              
    ,@CURRENT_VERSION_T AS isCurrentVersion              
 FROM #RSupdTemp              
 UNION ALL              
 SELECT              
  rsu.SegmentStatusId              
    ,rsu.SegmentRefStandardId              
    ,rs.RefStdId              
    ,rs.RefStdName              
    ,rs.ReplaceRefStdId              
    ,rs.RefStdCode              
    ,rse.RefStdEditionId              
    ,rse.RefEdition              
    ,rse.RefStdTitle              
    ,rse.LinkTarget              
    ,@CURRENT_VERSION_F AS isCurrentVersion              
 FROM [SLCMaster].dbo.ReferenceStandard AS RS WITH (NOLOCK)              
 INNER JOIN RSupdates AS rsu              
  ON rs.RefStdCode = rsu.RefStdCode              
 INNER JOIN [SLCMaster].[dbo].[ReferenceStandardEdition] AS RSE WITH (NOLOCK)              
  ON RSE.RefStdId = rs.RefStdId              
 WHERE rs.RefStdId = rsu.ReplaceRefStdId)              
--SELECT DISTINCT                                    
-- *                    
              
--FROM RSupdates;                                    
              
              
SELECT              
 * INTO #SegRefStd              
FROM (SELECT              
  PrjRefStd.ProjectId              
    ,PrjRefStd.SectionId              
    ,PrjRefStd.CustomerId              
    ,PrjRefStd.RefStandardId              
    ,'M' AS [Source]              
    ,RS.RefStdName              
              
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)              
 INNER JOIN SLCMaster..SegmentReferenceStandard SRS WITH (NOLOCK)              
  ON PrjRefStd.RefStandardId = SRS.RefStandardId              
  AND PrjRefStd.RefStdSource = 'M'              
 INNER JOIN ProjectSegmentStatus PSST WITH (NOLOCK)              
  ON SRS.SegmentId = PSST.mSegmentId              
 INNER JOIN SLCMaster..ReferenceStandardEdition MEDN WITH (NOLOCK)              
  ON PrjRefStd.RefStandardId = MEDN.RefStdId              
 INNER JOIN SLCMaster..ReferenceStandard RS WITH (NOLOCK)              
  ON RS.RefStdId = MEDN.RefStdId              
              
 WHERE PrjRefStd.SectionId = @PsectionId              
 AND PrjRefStd.ProjectId = @PprojectId              
 AND PrjRefStd.RefStdSource = 'M'              
 AND PrjRefStd.CustomerId = @PcustomerId              
 AND ISNULL(PrjRefStd.IsDeleted,0) = 0              
 AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId              
 AND PSST.SectionId = @PsectionId              
 AND PSST.ProjectId = @PprojectId              
 AND ISNULL(PSST.IsDeleted ,0) = 0             
 GROUP BY PrjRefStd.ProjectId              
   ,PrjRefStd.SectionId              
   ,PrjRefStd.CustomerId              
   ,PrjRefStd.RefStandardId              
   ,RS.RefStdName) T1              
              
DROP TABLE IF EXISTS #RefStdEdOld              
SELECT              
 * INTO #RefStdEdOld              
FROM (SELECT              
  OLDEDN.LinkTarget AS OldLinkTarget              
    ,OLDEDN.RefStdTitle AS OldRefStdTitle              
    ,OLDEDN.RefEdition AS OldRefEdition              
    ,OLDEDN.RefStdEditionId AS OldRefStdEditionId              
    ,PrjRefStd.RefStandardId AS PrjRefStdId              
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)              
 INNER JOIN SLCMaster..ReferenceStandardEdition OLDEDN WITH (NOLOCK)              
  ON PrjRefStd.RefStdEditionId = OLDEDN.RefStdEditionId              
 WHERE PrjRefStd.SectionId = @PsectionId              
 AND PrjRefStd.ProjectId = @PprojectId              
 AND PrjRefStd.RefStdSource = 'M'              
 AND PrjRefStd.CustomerId = @PcustomerId              
 --AND PrjRefStd.RefStandardId = X1.RefStandardId              
 AND PrjRefStd.IsDeleted = 0) T2              
              
DROP TABLE IF EXISTS #RefStdEdNew              
SELECT              
 RefStdId AS PrjRefStdId              
   ,MAX(RefStdEditionId) AS NewRefStdEditionId              
   ,CAST('' AS NVARCHAR(MAX)) AS NewRefStdTitle              
   ,CAST('' AS NVARCHAR(MAX)) AS NewLinkTarget              
   ,CAST('' AS NVARCHAR(MAX)) AS NewRefEdition INTO #RefStdEdNew              
FROM SLCMaster..ReferenceStandardEdition WITH (NOLOCK)              
WHERE MasterDataTypeId = @MasterDataTypeId              
GROUP BY RefStdId              
UPDATE t              
SET t.NewRefStdTitle = e.RefStdTitle              
   ,t.NewLinkTarget = e.LinkTarget              
   ,t.NewRefEdition = e.RefEdition              
FROM #RefStdEdNew t WITH (NOLOCK)              
INNER JOIN SLCMaster..ReferenceStandardEdition e WITH (NOLOCK)              
 ON e.RefStdEditionId = t.NewRefStdEditionId              
 AND e.RefStdId = t.PrjRefStdId              
            
DROP TABLE if EXISTS #RefStdWithOldNewEdId              
DROP TABLE if EXISTS #NewRSInfo              
SELECT RT.RefStdId AS RefStdId                
   ,MAX(PRT.RefStdEditionId) AS OldRefStdEditionId                
   ,MAX(RSE.RefStdEditionId) AS NewRefStdEditionId                
   ,PRT.ProjectId               
   ,PRT.SectionId              
   ,PRT.CustomerId              
   INTO #RefStdWithOldNewEdId              
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN ProjectReferenceStandard  PRT                
on RT.RefStdId=PRT.RefStandardId and RT.CustomerId=PRT.CustomerId and RT.RefStdSource=PRT.RefStdSource               
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStandardId =RSE.RefStdId               
where PRT.SectionId=@sectionId  AND PRT.ProjectId=@projectId and RT.CustomerId=@customerId   
and RT.RefStdSource='U'     
and  ISNULL( RT.IsDeleted,0) = 0   
and ISNULL( PRT.IsDeleted ,0) = 0     
 AND RSE.RefStdEditionId > PRT.RefStdEditionId      -- Added this condion  to resolve CSI: Customer Support 57414: Showing updates when none can be applied - 14820          
GROUP BY RT.RefStdId,PRT.ProjectId ,PRT.SectionId              
   ,PRT.CustomerId       
            
   --select * from #RefStdWithOldNewEdId              
                 
SELECT               
    RSE.LinkTarget AS NewLinkTarget              
   ,RSE.RefEdition AS NewRefEdition              
   ,RSE.RefStdTitle AS NewRefStdTitle              
   ,RSE.RefStdEditionId AS NewRefStdEditionId              
   ,RT.RefStdId  as RefStandardId              
   INTO #NewRSInfo              
FROM ReferenceStandard RT WITH(NOLOCK)INNER JOIN #RefStdWithOldNewEdId  PRT                
on RT.RefStdId=PRT.RefStdId              
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStdId =RSE.RefStdId  and RSE.RefStdEditionId=PRT.NewRefStdEditionId           
where RT.CustomerId=@customerId and RT.RefStdSource='U'  AND ISNULL( RT.IsDeleted,0) = 0   
AND PRT.OldRefStdEditionId != PRT.NewRefStdEditionId      
  
--Select * from  #NewRSInfo        
--Drop table if exists #RefStdEdNew                      
--Select *,null as MaxRefStdEditionId  into #RefStdEdNew                      
--from                      
--(                      
--SELECT  MEDN.LinkTarget AS NewLinkTarget                      
--    ,MEDN.RefEdition AS NewRefEdition                      
--    ,MEDN.RefStdTitle AS NewRefStdTitle                      
--    ,MEDN.RefStdEditionId AS NewRefStdEditionId                      
--    ,PrjRefStd.RefStandardId As PrjRefStdId                      
-- FROM ProjectReferenceStandard PrjRefStd WITH(NOLOCK)                      
-- INNER JOIN SLCMaster..ReferenceStandardEdition MEDN WITH(NOLOCK)                      
--  ON PrjRefStd.RefStandardId = MEDN.RefStdId                      
-- WHERE PrjRefStd.ProjectId = @PprojectId                      
-- AND PrjRefStd.RefStdSource = 'M'                      
-- AND PrjRefStd.SectionId = @PsectionId                      
-- AND PrjRefStd.CustomerId = @PcustomerId                      
-- AND PrjRefStd.IsDeleted = 0                      
-- --AND PrjRefStd.RefStandardId = X1.RefStandardId                      
-- AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId                   
-- --ORDER BY MEDN.RefStdEditionId DESC                      
--)T3                      
              
              
DROP TABLE IF EXISTS #ProjRefStd              
SELECT              
 * INTO #ProjRefStd              
FROM (SELECT              
  PrjRefStd.ProjectId              
    ,PrjRefStd.SectionId              
    ,PrjRefStd.CustomerId              
    ,PrjRefStd.RefStandardId              
    ,'M' AS [Source]              
    ,RS.RefStdName              
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)              
 INNER JOIN SLCMaster..ReferenceStandardEdition edition WITH (NOLOCK)              
  ON PrjRefStd.RefStandardId = edition.RefStdId              
 INNER JOIN SLCMaster..ReferenceStandard RS WITH (NOLOCK)              
  ON RS.RefStdId = edition.RefStdId              
 WHERE PrjRefStd.SectionId = @PsectionId              
 AND PrjRefStd.ProjectId = @PprojectId              
 AND PrjRefStd.CustomerId = @PcustomerId              
 AND PrjRefStd.RefStdSource = 'M'              
 AND PrjRefStd.IsDeleted = 0              
 AND edition.RefStdEditionId > PrjRefStd.RefStdEditionId              
GROUP BY PrjRefStd.ProjectId              
   ,PrjRefStd.SectionId              
   ,PrjRefStd.CustomerId              
   ,PrjRefStd.RefStandardId              
   ,RS.RefStdName) Ta              
              
DROP TABLE IF EXISTS #PRefStdOld        
SELECT              
 * INTO #PRefStdOld              
FROM (SELECT              
  OLDEDN.LinkTarget AS OldLinkTarget              
    ,OLDEDN.RefStdTitle AS OldRefStdTitle              
    ,OLDEDN.RefEdition AS OldRefEdition              
    ,OLDEDN.RefStdEditionId AS OldRefStdEditionId              
    ,PrjRefStd.RefStandardId AS PrjRefStdId              
 FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)              
 INNER JOIN SLCMaster..ReferenceStandardEdition OLDEDN WITH (NOLOCK)              
  ON PrjRefStd.RefStdEditionId = OLDEDN.RefStdEditionId              
 WHERE PrjRefStd.SectionId = @PsectionId              
 AND PrjRefStd.ProjectId = @PprojectId              
 AND PrjRefStd.CustomerId = @PcustomerId              
 AND PrjRefStd.RefStdSource = 'M'              
 AND PrjRefStd.IsDeleted = 0              
--AND PrjRefStd.RefStandardId = X1.RefStandardId              
) Tb              
              
--DROP TABLE IF EXISTS #PRefStdNew              
--SELECT              
-- * INTO #PRefStdNew              
--FROM (SELECT              
--  MEDN.LinkTarget AS NewLinkTarget              
--    ,MEDN.RefEdition AS NewRefEdition              
--    ,MEDN.RefStdTitle AS NewRefStdTitle              
--    ,MEDN.RefStdEditionId AS NewRefStdEditionId              
--    ,PrjRefStd.RefStandardId AS PrjRefStdId              
-- FROM ProjectReferenceStandard PrjRefStd WITH (NOLOCK)              
-- INNER JOIN SLCMaster..ReferenceStandardEdition MEDN WITH (NOLOCK)              
--  ON PrjRefStd.RefStandardId = MEDN.RefStdId              
-- WHERE PrjRefStd.ProjectId = @PprojectId              
-- AND PrjRefStd.RefStdSource = 'M'              
-- AND PrjRefStd.SectionId = @PsectionId              
-- AND PrjRefStd.CustomerId = @PcustomerId              
-- --AND PrjRefStd.RefStandardId = X1.RefStandardId              
-- AND PrjRefStd.IsDeleted = 0              
-- AND MEDN.RefStdEditionId > PrjRefStd.RefStdEditionId              
----ORDER BY MEDN.RefStdEditionId DESC              
--) Tc              
              
              
              
;              
WITH cte1              
AS              
(SELECT              
  ROW_NUMBER() OVER (PARTITION BY RefStandardId ORDER BY RefStandardId) Rownum              
    ,ProjectId              
    ,SectionId              
    ,CustomerId              
    ,RefStandardId              
    ,Source              
    ,RefStdName              
    ,OldLinkTarget              
    ,OldRefStdTitle              
    ,OldRefEdition              
    ,OldRefStdEditionId              
    ,NewLinkTarget              
    ,NewRefEdition              
    ,NewRefStdTitle              
 ,NewRefStdEditionId              
 FROM #SegRefStd R1              
 INNER JOIN #RefStdEdOld R2              
  ON R1.RefStandardId = R2.PrjRefStdId              
 INNER JOIN #RefStdEdNew R3              
  ON R1.RefStandardId = R3.PrjRefStdId),              
cte2              
AS              
(SELECT              
  ROW_NUMBER() OVER (PARTITION BY RefStandardId ORDER BY RefStandardId) Rownum              
    ,ProjectId              
    ,SectionId              
    ,CustomerId              
    ,RefStandardId              
    ,Source              
    ,RefStdName              
    ,OldLinkTarget              
    ,OldRefStdTitle              
    ,OldRefEdition              
    ,OldRefStdEditionId              
    ,NewLinkTarget              
    ,NewRefEdition              
    ,NewRefStdTitle              
    ,NewRefStdEditionId              
 FROM #ProjRefStd R1              
 INNER JOIN #PRefStdOld R2              
  ON R1.RefStandardId = R2.PrjRefStdId              
 INNER JOIN #RefStdEdNew R3              
  ON R1.RefStandardId = R3.PrjRefStdId)              
              
SELECT              
 ProjectId              
   ,SectionId              
   ,CustomerId              
   ,RefStandardId              
   ,Source        
   ,RefStdName              
   ,OldLinkTarget              
   ,OldRefStdTitle              
   ,OldRefEdition              
  ,OldRefStdEditionId              
   ,NewLinkTarget              
   ,NewRefEdition              
   ,NewRefStdTitle              
   ,NewRefStdEditionId              
FROM cte1              
WHERE Rownum = 1              
UNION              
SELECT              
 ProjectId              
   ,SectionId              
   ,CustomerId              
   ,RefStandardId              
   ,Source              
   ,RefStdName              
   ,OldLinkTarget              
   ,OldRefStdTitle              
   ,OldRefEdition              
   ,OldRefStdEditionId              
   ,NewLinkTarget              
   ,NewRefEdition              
   ,NewRefStdTitle              
   ,NewRefStdEditionId              
FROM cte2              
WHERE Rownum = 1              
UNION              
SELECT               
    PRT.ProjectId               
   ,PRT.SectionId              
   ,PRT.CustomerId              
   ,RT.RefStdId  as RefStandardId              
   ,RT.RefStdSource AS [Source]              
   ,RefStdName              
   ,RSE.LinkTarget AS OldLinkTarget              
   ,RSE.RefStdTitle AS OldRefStdTitle              
   ,RSE.RefEdition AS OldRefEdition              
   ,RSE.RefStdEditionId AS OldRefStdEditionId              
   ,NewLinkTarget              
   ,NewRefEdition              
   ,NewRefStdTitle              
   ,NRSI.NewRefStdEditionId              
FROM ReferenceStandard RT   WITH(NOLOCK)INNER JOIN #RefStdWithOldNewEdId  PRT                
on RT.RefStdId=PRT.RefStdId              
INNER JOIN ReferenceStandardEdition RSE  WITH(NOLOCK) on PRT.RefStdId =RSE.RefStdId  and RSE.RefStdEditionId=PRT.OldRefStdEditionId              
INNER JOIN #NewRSInfo NRSI on NRSI.RefStandardId =RSE.RefStdId               
where RT.CustomerId=@PcustomerId and RT.RefStdSource='U' AND ISNULL( RT.IsDeleted,0) = 0              
              
              
--GET SEGMENT CHOICES                                    
SELECT              
DISTINCT              
 CONVERT(BIGINT,SCH.SegmentChoiceId) AS SegmentChoiceId              
 ,CONVERT(BIGINT,SCH.SegmentChoiceCode) AS SegmentChoiceCode              
   ,SCH.SectionId              
   ,SCH.ChoiceTypeId              
 ,CONVERT(BIGINT,SCH.SegmentId) AS SegmentId              
FROM SLCMaster..SegmentChoice SCH WITH (NOLOCK)              
INNER JOIN #temp TMPSG              
 ON SCH.SegmentId = TMPSG.MSegmentId              
              
--GET SEGMENT CHOICES OPTIONS                                    
SELECT DISTINCT              
   CAST(CHOP.SegmentChoiceId AS BIGINT) AS SegmentChoiceId              
   ,CAST(CHOP.ChoiceOptionId AS BIGINT) AS ChoiceOptionId              
   ,CHOP.SortOrder              
   ,SCHOP.IsSelected              
   ,CAST(CHOP.ChoiceOptionCode AS BIGINT) AS ChoiceOptionCode              
   ,CHOP.OptionJson              
FROM SLCMaster..SegmentChoice SCH WITH (NOLOCK)              
INNER JOIN SLCMaster..ChoiceOption CHOP WITH (NOLOCK)              
 ON SCH.SegmentChoiceId = CHOP.SegmentChoiceId              
INNER JOIN SLCMaster..SelectedChoiceOption SCHOP WITH (NOLOCK)              
 ON SCHOP.ChoiceOptionCode = CHOP.ChoiceOptionCode              
INNER JOIN #temp TMPSG              
 ON SCH.SegmentId = TMPSG.MSegmentId              
              
--GET REF STD'S                                    
--SELECT                  
-- RS.RefStdId                  
--   ,RS.RefStdName                  
--   ,ISNULL(RS.ReplaceRefStdId,0) AS ReplaceRefStdId                
--   ,RS.IsObsolete                  
--   ,RS.RefStdCode                  
--FROM [SLCMaster].dbo.ReferenceStandard AS RS WITH (NOLOCK);              
              
--GET SECTIONS LIST    -- TODO - Remove sections from here                                
SELECT              
 MS.SectionId              
   ,MS.SectionCode              
   ,MS.Description              
   ,MS.SourceTag              
FROM SLCMaster..Section MS WITH (NOLOCK)              
WHERE MS.MasterDataTypeId = @MasterDataTypeId              
AND MS.IsLastLevel = 1              
ORDER BY MS.SourceTag ASC              
END  