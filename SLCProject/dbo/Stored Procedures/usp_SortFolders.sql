CREATE PROCEDURE [dbo].[usp_SortFolders]
(  
 @ProjectId int,  
 @CustomerId int,  
 @UserId int,  
 @SequencedSections nvarchar(max)  
)  
AS  
BEGIN  
SET NOCOUNT ON;  
 DECLARE @PProjectId int = @ProjectId;  
 DECLARE @PCustomerId int = @CustomerId;  
 DECLARE @PUserId int = @UserId;  
 DECLARE @PSequencedSections nvarchar(max) = @SequencedSections;  
WITH cte          
 AS          
 (SELECT          
   [Key] AS [Sequence]          
     ,[Value] AS SectionId          
  FROM OPENJSON(@SequencedSections))          
 UPDATE PS          
 SET PS.SortOrder = cte.Sequence ,  
 ModifiedBy = @UserId,  
 ModifiedDate = GETUTCDATE()         
 FROM cte WITH (NOLOCK)          
 INNER JOIN ProjectSection AS PS WITH (NOLOCK)          
  ON  PS.SectionId = cte.SectionId  
  AND PS.ProjectId =  @PProjectId  
  AND PS.CustomerId = @PCustomerId;  
        
  
END;