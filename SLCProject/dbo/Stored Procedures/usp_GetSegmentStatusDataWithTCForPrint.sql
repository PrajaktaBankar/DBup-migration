
CREATE PROCEDURE [dbo].[usp_GetSegmentStatusDataWithTCForPrint]                    
(                      
 @IsActiveOnly BIT,                      
 @TCPrintModeId INT,                      
 @SectionIdsString NVARCHAR(MAX),                      
 @CatalogueType NVARCHAR(150),                      
 @ProjectId INT,                       
 @CustomerId INT)                       
 AS                       
BEGIN                      
                      
DECLARE @PIsActiveOnly BIT = @IsActiveOnly;                       
DECLARE @PTCPrintModeId INT = @TCPrintModeId;                         
DECLARE @PSectionIdsString NVARCHAR(MAX) =@SectionIdsString;                       
DECLARE @PProjectId INT = @ProjectId;                       
DECLARE @PCustomerId INT = @CustomerId;                       
DECLARE @PCatalogueType NVARCHAR(MAX) = @CatalogueType;                        
                       
DECLARE @CatalogueTypeTbl TABLE (TagType NVARCHAR(MAX));                         
DECLARE @Lu_InheritFromSection INT = 1;                                                                            
DECLARE @Lu_AllWithMarkups INT = 2;                                                                            
DECLARE @Lu_AllWithoutMarkups INT = 3;                       
DECLARE @IsFalse BIT = 0;                       
DECLARE @SectionIdTbl TABLE (SectionId INT);                        
                      
--CONVERT STRING INTO TABLE                                                                                     
INSERT INTO @SectionIdTbl (SectionId)                                                                            
SELECT *                                                                            
FROM dbo.fn_SplitString(@PSectionIdsString, ',');  


  --CONVERT CATALOGUE TYPE INTO TABLE                                                                          
 IF @PCatalogueType IS NOT NULL                                                      
  AND @PCatalogueType != 'FS'                                                          
 BEGIN                                                          
  INSERT INTO @CatalogueTypeTbl (TagType)                                                          
  SELECT *                                                          
  FROM dbo.fn_SplitString(@PCatalogueType, ',');                                     
                                                          
  IF EXISTS (                                                          
    SELECT *                                                
    FROM @CatalogueTypeTbl                                                          
    WHERE TagType = 'OL'                                       
    )                                                          
  BEGIN                                                          
   INSERT INTO @CatalogueTypeTbl                                               
   VALUES ('UO')                                                          
  END                                                          
                                                          
  IF EXISTS (                                                          
    SELECT TOP 1 1                                                          
    FROM @CatalogueTypeTbl                                                          
    WHERE TagType = 'SF'                                                          
    )                                                          
  BEGIN                                                          
   INSERT INTO @CatalogueTypeTbl                                     
   VALUES ('US')                                                          
  END                                                          
 END                                                           
            
CREATE TABLE #tmp_ProjectSegmentStatus (                        
SegmentStatusId BIGINT                                                            
,SectionId INT                                                                          
,ParentSegmentStatusId BIGINT                                                                           
,mSegmentStatusId  BIGINT                        
,mSegmentId INT                                                                 
, SegmentId BIGINT                                                                   
,SegmentSource NVARCHAR(10)                                                                       
,SegmentOrigin NVARCHAR(10)                                                               
,IndentLevel INT                                                                           
,SequenceNumber  INT                                                                          
,SegmentStatusTypeId INT                                                                          
,SegmentStatusCode BIGINT                                                                         
,IsParentSegmentStatusActive BIT                                                                           
,IsShowAutoNumber BIT                                                
,FormattingJson NVARCHAR(MAX)                                                                           
,TagType NVARCHAR(50)                                        
,SpecTypeTagId INT                              
,IsRefStdParagraph BIT                                                                     
,IsPageBreak BIT                            
,TrackOriginOrder NVARCHAR(100)                     
,MTrackDescription NVARCHAR(MAX)                                                     
,TrackChangeType NVARCHAR(50)                         
,IsStatusTrack BIT                        
)                      
                      
--FETCH SEGMENT STATUS DATA INTO TEMP TABLE                           
INSERT INTO #tmp_ProjectSegmentStatus                                                                                          
 SELECT PSST.SegmentStatusId                                                                      
  ,PSST.SectionId                                                                            
  ,PSST.ParentSegmentStatusId                                                                            
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                                                                            
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                                                                            
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId                                                                       
  ,PSST.SegmentSource                                                                            
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                                                                            
  ,CASE                                                                             
   WHEN PSST.IndentLevel > 8                                                                            
    THEN CAST(8 AS TINYINT)                                                              
   ELSE PSST.IndentLevel                                                                            
   END AS IndentLevel                                                                            
  ,PSST.SequenceNumber                                                                            
  ,PSST.SegmentStatusTypeId                                                                            
  ,PSST.SegmentStatusCode                                                                            
  ,PSST.IsParentSegmentStatusActive                                                                            
  ,PSST.IsShowAutoNumber                                                 
  ,PSST.FormattingJson                        
  ,STT.TagType                                         
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                                                                            
  ,PSST.IsRefStdParagraph                                                                       
  ,PSST.IsPageBreak                                    
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                                                                            
  ,PSST.MTrackDescription                                                        
  ,(                        
      CASE                        
         WHEN (                        
            TSST.InitialStatus = 0                
   and TSST.CurrentStatus = 1                 
         ) THEN 'AddedParagraph'                          
         ELSE 'Untouched'                        
      END                        
   ) AS TrackChangeType                             
  ,(                                            
   CASE                                                                             
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups AND TSST.SegmentStatusTypeId>0                                                                          
     THEN CAST(0 AS BIT)                                                                     
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups AND TSST.SegmentStatusTypeId>0                                                                             
     THEN CAST(1 AS BIT)                         
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                                                                            
     AND PS.IsTrackChanges = 1 AND TSST.SegmentStatusTypeId>0                                                                         
     THEN CAST(1 AS BIT)                                                                            
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                                     
     AND PS.IsTrackChanges = 0 AND TSST.SegmentStatusTypeId>0                                                                    
     THEN CAST(0 AS BIT)                                                                           
    ELSE CAST(0 AS BIT)                                                   
    END                                                                            
   ) AS IsStatusTrack                                            
                               
 FROM @SectionIdTbl SIDTBL                                                                         
 INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.ProjectId = @PProjectId AND PSST.SectionId = SIDTBL.SectionId                                                                            
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                                                       
 LEFT OUTER JOIN TrackSegmentStatusType TSST WITH(NOLOCK) ON PSST.SectionId=TSST.SectionId                                       
 AND PSST.SegmentStatusId=TSST.SegmentStatusId AND isnull(TSST.IsAccepted,0)=0                                                      
 LEFT JOIN ProjectSection PS WITH(NOLOCK) ON PS.SectionId=TSST.SectionId                                                  
 WHERE PSST.ProjectId = @PProjectId                                                                          
  AND PSST.CustomerId = @PCustomerId                                                                            
  AND (                                                                            
   PSST.IsDeleted IS NULL                                                                            
   OR PSST.IsDeleted = 0                                                                            
   )                                                                            
  AND (                                                                            
   @PIsActiveOnly = @IsFalse                
   OR (                                                                            
     PSST.SegmentStatusTypeId>0 AND PSST.SegmentStatusTypeId<6 AND PSST.IsParentSegmentStatusActive=1                                  
    )                                                                            
   OR (PSST.IsPageBreak = 1)                                                                            
   )                                                                            
  AND (                                                                            
   @PCatalogueType = 'FS'                                                                            
   OR STT.TagType IN (                                                                            
SELECT TagType                                                                            
    FROM @CatalogueTypeTbl                                                                            
    )                                                                            
   )                                                                            
    UNION                                 
  --TRACK PARA                                 
  --if EXISTS (select top 1* from TrackSegmentStatusType TSST INNER JOIN @SectionIdTbl SIDTBL ON TSST.SectionId= SIDTBL.SectionId )                                
  --begin                                  
   SELECT PSST.SegmentStatusId                                                                      
  ,PSST.SectionId                          
  ,PSST.ParentSegmentStatusId                                                                            
  ,ISNULL(PSST.mSegmentStatusId, 0) AS mSegmentStatusId                                                                            
  ,ISNULL(PSST.mSegmentId, 0) AS mSegmentId                                                                            
  ,ISNULL(PSST.SegmentId, 0) AS SegmentId                                                                       
  ,PSST.SegmentSource                           
  ,trim(convert(NCHAR(2), PSST.SegmentOrigin)) AS SegmentOrigin                            
  ,CASE                                                                        
   WHEN PSST.IndentLevel > 8                                                         
    THEN CAST(8 AS TINYINT)                                                                            
   ELSE PSST.IndentLevel                
   END AS IndentLevel                                                                            
  ,PSST.SequenceNumber                                                                            
  ,PSST.SegmentStatusTypeId                                                                            
  ,PSST.SegmentStatusCode                                                                            
  ,PSST.IsParentSegmentStatusActive                         
  ,PSST.IsShowAutoNumber                                                                            
  ,PSST.FormattingJson                                                                            
  ,STT.TagType                                                                            
  ,ISNULL(PSST.SpecTypeTagId, 0) AS SpecTypeTagId                                                                            
  ,PSST.IsRefStdParagraph                                                                       
  ,PSST.IsPageBreak                                                                            
  ,ISNULL(PSST.TrackOriginOrder, '') AS TrackOriginOrder                                                                     
  ,PSST.MTrackDescription                                                   
  ,(                        
      CASE                        
         WHEN (                        
            TSST.InitialStatus =1                      
            and TSST.CurrentStatus =0                     
         ) THEN 'RemovedParagraph'                       
         ELSE 'DoNotTrack'                        
      END                        
   ) AS TrackChangeType,              
   (                                            
   CASE                                                                             
    WHEN @PTCPrintModeId = @Lu_AllWithoutMarkups AND TSST.SegmentStatusTypeId>0                                                                          
     THEN CAST(0 AS BIT)                                                                     
    WHEN @PTCPrintModeId = @Lu_AllWithMarkups AND TSST.SegmentStatusTypeId>0                   
     THEN CAST(1 AS BIT)                                                                             
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                                                                            
     AND PS.IsTrackChanges = 1 AND TSST.SegmentStatusTypeId>0                                                                         
     THEN CAST(1 AS BIT)                                     
    WHEN @PTCPrintModeId = @Lu_InheritFromSection                                                                            
     AND PS.IsTrackChanges = 0 AND TSST.SegmentStatusTypeId>0                                                                    
     THEN CAST(0 AS BIT)                                                                           
    ELSE CAST(0 AS BIT)                                                   
    END                                                                            
   ) AS IsStatusTrack                      
 FROM @SectionIdTbl SIDTBL                                                   
 INNER JOIN ProjectSegmentStatus AS PSST WITH (NOLOCK) ON PSST.ProjectId = @ProjectId AND PSST.SectionId = SIDTBL.SectionId                                                                            
 LEFT OUTER JOIN LuProjectSpecTypeTag AS STT WITH (NOLOCK) ON PSST.SpecTypeTagId = STT.SpecTypeTagId                                                       
 LEFT OUTER JOIN TrackSegmentStatusType TSST WITH(NOLOCK) ON PSST.SectionId=TSST.SectionId                                            
 AND PSST.SegmentStatusId=TSST.SegmentStatusId AND isnull(TSST.IsAccepted,0)=0                                                      
 LEFT JOIN ProjectSection PS WITH(NOLOCK) ON PS.SectionId=TSST.SectionId                                                  
 WHERE PSST.ProjectId = @PProjectId                                                                          
  AND PSST.CustomerId = @PCustomerId                                                                            
  AND (                                                                            
   PSST.IsDeleted IS NULL                                                                            
   OR PSST.IsDeleted = 0                                                                            
   )                                                                        
  AND (                                                                            
   @PIsActiveOnly = @IsFalse                                                                       
   OR (                         
  --(PSST.SegmentStatusTypeId>0 AND PSST.SegmentStatusTypeId<6 AND PSST.IsParentSegmentStatusActive=1  )                      
  --or                                                                         
         (                                
            TSST.SegmentStatusTrackId IS NOT NULL                                
            AND ISNULL(TSST.IsAccepted, 0) = 0                                
         ) --40                                
         --AND PSST.SegmentStatusTypeId <>TSST.InitialStatusSegmentStatusTypeId --33)                                
         AND (                                
            TSST.InitialStatusSegmentStatusTypeId < 6                                
            AND PSST.SegmentStatusTypeId >= 6 --4                                
            OR (   
               TSST.InitialStatusSegmentStatusTypeId < 6                                
               AND PSST.SegmentStatusTypeId < 6                                
            )                                
         )                                
    )                                                                            
   OR (PSST.IsPageBreak = 1)                                                                            
   )                                                                            
  AND (                                                                            
   @PCatalogueType = 'FS'                                                                            
   OR STT.TagType IN (                                                                            
SELECT TagType                                                                            
    FROM @CatalogueTypeTbl                                                                            
    )                                                                       
 )                                  
   and @PTCPrintModeId IN (@Lu_AllWithMarkups,@Lu_InheritFromSection)       ;                                                                 
                        
  SELECT * FROM  #tmp_ProjectSegmentStatus                      
  END
GO


