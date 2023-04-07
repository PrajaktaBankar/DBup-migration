CREATE PROCEDURE [dbo].[usp_UpdateSegmentStatus]     
(  
    @ProjectId INT  ,  
    @customerId INT ,  
    @sectionId INT ,  
 @segmentstatusId BIGINT ,  
 @IndentLevel BIT null= null ,  
 @ParentSegmentStatusId  BIGINT null=null,  
 @SegmentOrigin CHAR (2) null=null ,  
 @ModifiedDate  DATETIME null=null ,  
 @ModifiedBy  INT null=null,  
 @IsShowAutoNumber BIT null=null ,  
 @FormattingJson  NVARCHAR (MAX) null=null ,  
 @SegmentId  BIGINT null=null,  
 @IsPageBreak BIT null=null  
)  
AS      
BEGIN
  
 DECLARE @PProjectId INT = @ProjectId;
 DECLARE @PcustomerId INT = @customerId;
 DECLARE @PsectionId INT = @sectionId;
 DECLARE @PsegmentstatusId BIGINT = @segmentstatusId;
 DECLARE @PIndentLevel BIT = @IndentLevel;
 DECLARE @PParentSegmentStatusId  BIGINT = @ParentSegmentStatusId;
 DECLARE @PSegmentOrigin CHAR (2) = @SegmentOrigin;
 DECLARE @PModifiedDate  DATETIME = @ModifiedDate;
 DECLARE @PModifiedBy  INT = @ModifiedBy;
 DECLARE @PIsShowAutoNumber BIT = @IsShowAutoNumber;
 DECLARE @PFormattingJson  NVARCHAR = @FormattingJson;
 DECLARE @PSegmentId  BIGINT = @SegmentId;
 DECLARE @PIsPageBreak BIT = @IsPageBreak;

UPDATE PSS
SET PSS.IndentLevel = @PIndentLevel
   ,PSS.ParentSegmentStatusId = @PParentSegmentStatusId
   ,PSS.SegmentOrigin = @PSegmentOrigin
   ,PSS.ModifiedDate = @PModifiedDate
   ,PSS.ModifiedBy = @PModifiedBy
   ,PSS.IsShowAutoNumber = @PIsShowAutoNumber
   ,PSS.FormattingJson = @PFormattingJson
   ,PSS.SegmentId = @PSegmentId
   ,PSS.IsPageBreak = @PIsPageBreak

FROM ProjectSegmentStatus PSS WITH (NOLOCK)
WHERE PSS.CustomerId = @PcustomerId
AND PSS.ProjectId = @PProjectId
AND PSS.SegmentStatusId = @PsegmentstatusId
AND PSS.SectionId = @PsectionId;



END
GO


