CREATE PROCEDURE [dbo].[usp_UpdateRSParagraphStatus]  
 @SegmentStatusId BIGINT,      
 @IsShowAutoNumber BIT,  
 @ParentSegmentStatusId BIGINT,  
 @IndentLevel TINYINT  
AS  
BEGIN    
      
 DECLARE @PSegmentStatusId BIGINT = @SegmentStatusId;    
 DECLARE @PIsShowAutoNumber BIT = @IsShowAutoNumber;    
 DECLARE @PParentSegmentStatusId BIGINT = @ParentSegmentStatusId;    
 DECLARE @PIndentLevel TINYINT = @IndentLevel;    
    
 UPDATE PSS    
 SET   
 PSS.IsShowAutoNumber = @PIsShowAutoNumber,  
 PSS.ParentSegmentStatusId = @PParentSegmentStatusId,  
 PSS.IndentLevel = @PIndentLevel,
 PSS.ModifiedDate = GETUTCDATE()
 FROM ProjectSegmentStatus PSS WITH (NOLOCK)    
 WHERE PSS.SegmentStatusId = @PSegmentStatusId    
END
GO


