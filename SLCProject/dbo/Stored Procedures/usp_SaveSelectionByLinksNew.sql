CREATE PROCEDURE [dbo].[usp_SaveSelectionByLinksNew]     
(  
 @ProjectId INT,   
 @CustomerId INT,   
 @UserId INT,    
 @SegmentStatusId BIGINT,  
 @SegmentStatusListJson NVARCHAR(MAX),   
 @SelectedChoiceOptionListJson NVARCHAR(MAX),   
 @SegmentLinkListJson NVARCHAR(MAX),
 @UserFullName NVARCHAR(MAX) = NULL
 )
AS        
BEGIN      
DECLARE @PProjectId INT = @ProjectId;      
DECLARE @PCustomerId INT = @CustomerId;      
DECLARE @PUserId INT = @UserId;      
DECLARE @PSegmentStatusListJson NVARCHAR(MAX) = @SegmentStatusListJson;      
DECLARE @PSelectedChoiceOptionListJson NVARCHAR(MAX) = @SelectedChoiceOptionListJson;      
DECLARE @PSegmentLinkListJson NVARCHAR(MAX) = @SegmentLinkListJson;      
  
--SET NO COUNT ON          
SET NOCOUNT ON;    
      
 BEGIN -- Update Status in ProjectSegmentStatus table    
  IF @PSegmentStatusListJson != ''    
  BEGIN    
   ;WITH PSSCTE    
    AS      
    (    
      SELECT SegmentStatusId, SegmentStatusTypeId,IsParentSegmentStatusActive     
     FROM OPENJSON(@PSegmentStatusListJson)      
     WITH (      
      SegmentStatusId BIGINT '$.SegmentStatusId',      
      SegmentStatusTypeId INT '$.SegmentStatusTypeId',      
      IsParentSegmentStatusActive BIT '$.IsParentSegmentStatusActive'      
     )    
    )      
    UPDATE PSS      
    SET PSS.SegmentStatusTypeId = PSSCTE.SegmentStatusTypeId      
      ,PSS.IsParentSegmentStatusActive = PSSCTE.IsParentSegmentStatusActive      
    FROM PSSCTE WITH (NOLOCK)    
    INNER JOIN ProjectSegmentStatus AS PSS WITH (NOLOCK)      
     ON PSSCTE.SegmentStatusId = PSS.SegmentStatusId;    
    
     --EXEC usp_UpdateSegmentStatusTypeDeletedLinkFromUpdate @PProjectId,@PCustomerId, @SegmentStatusId    
  END    
 END    
    
 BEGIN -- Update IsSelected flag in SelectedChoiceOption table    
  IF @PSelectedChoiceOptionListJson != ''    
  BEGIN    
   ;WITH SCOCTE    
    AS      
    (    
      SELECT SelectedChoiceOptionId, IsSelected    
     FROM OPENJSON(@PSelectedChoiceOptionListJson)      
     WITH (      
     SelectedChoiceOptionId BIGINT '$.SelectedChoiceOptionId',      
     IsSelected BIT '$.IsSelected'        
     )    
    )    
    UPDATE SCO     
    SET SCO.IsSelected = SCOCTE.IsSelected      
    FROM SCOCTE WITH (NOLOCK)    
    INNER JOIN SelectedChoiceOption SCO WITH (NOLOCK)      
    ON SCOCTE.SelectedChoiceOptionId = SCO.SelectedChoiceOptionId;    
  END    
 END    
    
 BEGIN -- Update IsDeleted flag in ProjectSegmentLink table    
  IF @PSegmentLinkListJson != ''    
  BEGIN    
   ;WITH PSLCTE    
    AS      
    (    
      SELECT SegmentLinkId    
     FROM OPENJSON(@PSegmentLinkListJson)      
     WITH (      
     SegmentLinkId BIGINT '$.SegmentLinkId'        
     )    
    )    
    UPDATE PSL     
    SET PSL.IsDeleted = 1    
    FROM PSLCTE WITH (NOLOCK)    
    INNER JOIN ProjectSegmentLink PSL WITH (NOLOCK)    
    ON PSLCTE.SegmentLinkId = PSL.SegmentLinkId;    
  END    
 END    
    
    
 BEGIN -- Update LastAccessed date for Project in LastAccessed table    
  UPDATE UF     
  SET UF.UserId = @PUserId, UF.LastAccessed = GETUTCDATE(), LastAccessByFullName = @UserFullName
  FROM UserFolder UF WITH (NOLOCK)      
  WHERE UF.ProjectId = @PProjectId      
  AND UF.CustomerId = @PCustomerId      
 END    
      
END;  
